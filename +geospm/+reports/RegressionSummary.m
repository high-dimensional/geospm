% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2020,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef RegressionSummary < handle
    
    %RegressionSummary 
    %

    properties (GetAccess=public, SetAccess=public)
        
        dataset
        
        variable_names
        responses
        X
        betas
        eastings
        northings
        
        observation_index_by_cell
        fitted_response
    end

    methods
        
        function obj = RegressionSummary(dataset)
    
            obj.dataset = dataset;
    
            obj.variable_names = {};
            obj.responses = {};
            obj.X = [];
            obj.betas = {};
            obj.eastings = [];
            obj.northings = [];
            
            obj.observation_index_by_cell = {};
            obj.fitted_response = [];
        end
        
        function [stats, betas] = gather_betas(obj, slice_index, mask, selected_names)
            
            if ~exist('selected_names', 'var') || isempty(selected_names)
                selected_names = obj.variable_names;
            end

            stats = hdng.utilities.RecordTable;
            betas = hdng.utilities.RecordTable;

            for index=1:numel(selected_names)

                name = selected_names{index};

                variable_index = find(strcmp(name, obj.variable_names), 1);

                if isempty(variable_index)
                    continue;
                end
                
                beta_values = obj.betas{variable_index};

                beta_values = beta_values(:, :, slice_index);
                beta_values = beta_values(:);
        
                beta_values = beta_values(mask(:));

                observations = cellfun(@(x) numel(x), obj.observation_index_by_cell(mask(:)), 'UniformOutput', true);
                
                n = sum(observations);

                summary = hdng.utilities.RecordTable(hdng.one_struct(...
                              'cells', sum(mask(:)), ...
                              'n', n, ...
                              'name', {name}, ...
                              'mean', mean(beta_values), ...
                              'median', median(beta_values), ...
                              'std', std(beta_values), ...
                              'min', min(beta_values), ...
                              'max', max(beta_values), ...
                              'q1', quantile(beta_values, 0.25), ...
                              'q2', quantile(beta_values, 0.5), ...
                              'q3', quantile(beta_values, 0.75) ...
                ), 1);

                stats = stats + summary;
                 
                betas = betas + hdng.utilities.RecordTable(hdng.one_struct(...
                            'name', repmat({name}, numel(beta_values), 1), ...
                            'value', beta_values ...
                            ), numel(beta_values));
            end
        end
        
        function [stats, trend] = plot_response(obj, mask, ordinate, group_by, diagram_file)
            
            % Convert the polygon mask to a selector usable with the covariates
            observation_indices = obj.observation_index_by_cell(mask(:));
            observation_selector = obj.indices_to_mask(observation_indices, numel(obj.responses));
            
            mask_indices = find(mask(:));
            
            for index=1:numel(mask_indices)
                tmp_mask = zeros(size(mask), 'logical');
                tmp_mask(mask_indices(index)) = true;
                tmp_indices = obj.observation_index_by_cell(tmp_mask);
                tmp_selector = obj.indices_to_mask(tmp_indices, numel(obj.responses));
            
                if sum(tmp_selector) == 0
                    continue
                end
            
                tmp_easting = obj.eastings(tmp_selector);
                tmp_northing = obj.northings(tmp_selector);
                
                if size(tmp_easting, 1) > 1
                    s = sum(sum([tmp_easting(2:end), tmp_northing(2:end)] - ...
                        [tmp_easting(1), tmp_northing(1)]));
            
                    if s ~= 0
                        error('Response files should be equal but are not!');
                    end
                end
            
                fprintf('%d, %d\n', tmp_easting(1), tmp_northing(1));
            end
            
            ordinate_values = obj.get_covariate_by_name(ordinate);
            group_by_values = obj.get_covariate_by_name(group_by);
            
            % Select the values inside the polygon
            ordinate_values = ordinate_values(observation_selector);
            group_by_values = group_by_values(observation_selector);
            
            % Stratify the group-by values by quartile
            N_quantiles = 3;
            selectors = obj.selectors_from_quantiles(group_by_values, N_quantiles);
            
            colours = {
                [196, 182,  28] / 255;
                [ 20, 184, 143] / 255;
                [ 98, 180, 210] / 255;
                [112,  89, 166] / 255;
            };
            
            [directory, file_name, ext] = fileparts(diagram_file);
            
            f = figure;
            weighting = ones(7, 1) / 7;
            obj.plot_diagram(obj.fitted_response, ordinate_values, selectors, observation_selector, mask, colours, weighting);
            exportgraphics(f, fullfile(directory, [file_name '_smooth' ext]), 'ContentType', 'vector');
            close(f);
            
            f = figure;
            [stats, trend] = obj.plot_diagram(obj.fitted_response, ordinate_values, selectors, observation_selector, mask, colours, []);
            exportgraphics(f, fullfile(directory, [file_name ext]), 'ContentType', 'vector');
            close(f);
            
            f = figure;
            
            plot(stats.fields.quartile, stats.fields.y_mean);

            exportgraphics(f, fullfile(directory, [file_name '_trend' ext]), 'ContentType', 'vector');
            close(f);
        
        end

        
        function [covariate_values, covariate_index] = get_covariate_by_name(obj, covariate_name)
            
            covariate_index = [];
        
            for index=1:numel(obj.variable_names)
                name = obj.variable_names{index};
        
                if strcmp(name, covariate_name)
                    covariate_index = index;
                    break;
                end
            end
        
            if isempty(covariate_index)
                error('Couldn''t locate covariate: %s', covariate_name);
            end
        
            covariate_values = obj.X(:, covariate_index);
        end

    end

    methods (Static)


        function result = indices_to_mask(index_groups, N)
        
            result = zeros(N, 1, 'logical');
        
            for i=1:numel(index_groups)
                
                indices = index_groups{i};
        
                for j=1:numel(indices)
                    index = indices(j);
                    result(index) = true;
                end
            end
        end

        
        function result = compile(dataset, resolution, context, cache)
        
            
            [session_key, spm_output_path] = context.spm_paths_from_record(dataset.query.record);
            
            session_file = fullfile(spm_output_path, 'SPM.mat');

            if cache.holds_key(session_file)
                result = cache(session_file);
                return;
            end
            
            cell_size = dataset.query.cell_size;
            min_location = dataset.query.min_location;
            slice_index = dataset.query.slice_index;
            
            spm_output_directory = fileparts(session_file);
        
            session = geospm.spm.SPMSession(session_file);
            grid_spatial_index = geospm.SpatialIndex.load_from_matlab(fullfile(spm_output_directory, 'grid_spatial_index.mat'));
        
            covariates = session.regression_x_values;
        
            responses = session.regression_y_files;
            betas = session.regression_beta_files;
            eastings = zeros(numel(responses), 1);
            northings = zeros(numel(responses), 1);
        
            specifier = context.shared_variables.volume_generators(session_key);
            
            volume_generator = geospm.reports.ReportContext.create_volume_generator(...
                session_key, ...
                [resolution, 1], ...
                'double', ...
                cell_size, ...
                specifier.smoothing_method, ...
                specifier.smoothing_levels, ...
                specifier.smoothing_levels_p_value);
        
            volume_generator.register_spatial_index(grid_spatial_index);

            SyntheticVolumeGenerator.add(volume_generator, ...
                                         volume_generator.session_key);
            
            guard = onCleanup(@() SyntheticVolumeGenerator.remove(volume_generator.session_key));

            observation_index_by_cell = cell(resolution);
        
            try
                    
                for i=1:numel(responses)
                    file_path = responses{i};
                    [~, file_name, file_ext] = fileparts(file_path);
                    file_path = fullfile(session_key, [file_name, file_ext]);
                    file_data = geospm.utilities.read_nifti(file_path);
        
                    volume_spec = volume_generator.parse_specifier(file_name);
                    [x, y, ~] = volume_spec.spatial_index.xyz_coordinates_for_segment(volume_spec.segment_number);
                    
                    eastings(i) = min_location(1) + cell_size(1) * (x(1) - 1.0 + 0.5);
                    northings(i) = min_location(2) + cell_size(2) * (y(1) - 1.0 + 0.5);
                    
                    value = observation_index_by_cell{x(1), y(1)};
                    observation_index_by_cell{x(1), y(1)} = [value; i];
        
                    responses{i} = file_data;
                end
                
            catch exception
        
                %SyntheticVolumeGenerator.remove(volume_generator.session_key);
                rethrow(exception);
            end
            
            
            fitted_response = [];
        
            for i=1:numel(betas)
                file_path = betas{i};
                [~, file_name, file_ext] = fileparts(file_path);
                file_path = fullfile(spm_output_directory, [file_name, file_ext]);
                file_data = geospm.utilities.read_nifti(file_path);
                betas{i} = file_data;
        
                beta = file_data(:, :, slice_index);
                beta = beta(:)';
        
                if isempty(fitted_response)
                    fitted_response = covariates(:, i) * beta;
                else
                    fitted_response = fitted_response + covariates(:, i) * beta;
                end
            end
            

            result = geospm.reports.RegressionSummary(dataset);

            result.variable_names = session.regression_x_names;
            result.X = session.regression_x_values;
            result.responses = responses;
            result.betas = betas;
            result.eastings = eastings;
            result.northings = northings;
            result.observation_index_by_cell = observation_index_by_cell;
            result.fitted_response = fitted_response;
            
            cache(session_file) = result; %#ok<NASGU>
        end
    end

    methods (Static, Access=protected)

        function [stats, trend] = plot_diagram(responses, ordinate_values, selectors, polygon_selector, polygon_mask, colours, weighting)
        
            stats = hdng.utilities.RecordTable;
            trend = hdng.utilities.RecordTable;

            hold on;
            
            % For each quantile range of the group-by values, 
            % print the fitted response against the ordinate
        
            for s_index=1:size(selectors, 2)
                selector = selectors(:, s_index);
        
                X = ordinate_values(selector);
                [X, order] = sort(X);
        
                Y = responses(polygon_selector, polygon_mask(:));
                Y = Y(selector, :);
                Y = Y(order, :);
        
                X_unique = unique(X);
                Y_unique = zeros(numel(X_unique), size(Y, 2));
                
                for x_index=1:numel(X_unique)
                    group = X == X_unique(x_index);
                    Y_unique(x_index, :) = mean(Y(group, :), 1);
                end
        
                Y_min = min(Y_unique, [], 2);
                Y_max = max(Y_unique, [], 2);
                Y_mean = mean(Y_unique, 2);
                
                if ~isempty(weighting)
        
                    Y_min = conv(Y_min, weighting, 'valid');
                    Y_max = conv(Y_max, weighting, 'valid');
                    Y_mean = conv(Y_mean, weighting, 'valid');
                    
                    l = ceil(numel(weighting) / 2);
                    r = floor(numel(weighting) / 2);
        
                    X_unique = X_unique(l:end - r);
                
                end
        
                fill([X_unique; flip(X_unique)], [Y_min; flip(Y_max)], colours{s_index}, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
                plot(X_unique, Y_mean, 'Color', colours{s_index});
                
                stats = stats + hdng.utilities.RecordTable(hdng.one_struct(...
                    'quartile', s_index, ...
                    'x_mean', mean(X_unique), ...
                    'y_mean', mean(Y_unique(:)), ...
                    'y_min', min(Y_unique(:)), ...
                    'y_max', max(Y_unique(:)), ...
                    'y_mean_min', mean(Y_min), ...
                    'y_mean_max', mean(Y_max) ...
                ));
                
            end
            
            hold off;
            
            lm = fitlm(stats.fields.x_mean, stats.fields.y_mean);
        
            tmp = lm.Coefficients.Variables;
            
            trend = trend.assign_field('estimate', tmp(2, 1));
            trend = trend.assign_field('std_err',       tmp(2, 2));
            trend = trend.assign_field('t',        tmp(2, 3));
            trend = trend.assign_field('p',        tmp(2, 4));
        end
        
        
        function selectors = selectors_from_quantiles(values, Q)
            
            qs = [-Inf, quantile(values, Q), Inf];
            
            selectors = zeros(numel(values), numel(qs) - 1, 'logical');
            
            for index=2:numel(qs)
                qmin = qs(index - 1);
                qmax = qs(index);
                selectors(:, index - 1) = values >= qmin & values < qmax;
            end
        end


    end
end
