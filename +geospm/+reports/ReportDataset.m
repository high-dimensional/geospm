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

classdef ReportDataset < handle
    
    %ReportDataset 
    %

    properties (GetAccess=public, SetAccess=public)
        
        data % – A matrix of data values
        variable_names % – A cell array of column names
        identifiers % – A struct mapping identifiers to column indices

        selection % The selection by which this data set was derived
        
        query
    end

    methods
        
        function obj = ReportDataset(data, variable_names)

            obj.data = data;
            obj.variable_names = variable_names;
            obj.identifiers = struct();

            for index=1:numel(variable_names)
                obj.identifiers.(variable_names{index}) = index;
            end

            obj.selection = [];

            obj.query = [];
        end

        function result = select(obj, row_selector, column_selector, apply_transforms)
        
            if ~exist('apply_transforms', 'var')
                apply_transforms = struct.empty;
            end

            if isnumeric(row_selector) && isscalar(row_selector) && row_selector == -1
                row_selector = 1:size(obj.data, 1);
            end

            if isnumeric(column_selector) && isscalar(column_selector) && column_selector == -1
                column_selector = 1:size(obj.data, 2);
            end

            if iscell(column_selector)
                column_selector = obj.select_variables_by_name(column_selector);
            end
            
            new_data = obj.data(row_selector, column_selector);
            new_variable_names = obj.variable_names(column_selector);

            result = geospm.reports.ReportDataset(new_data, new_variable_names);
            
            result.selection = row_selector;
            result.query = obj.query;

            if ~isempty(apply_transforms)
                result = result.apply_transforms(apply_transforms);
            end
        end
        
        function polygon_datasets = select_polygons(obj, polygons, ...
                slice_index, record, raster_size, cell_size, ...
                min_location, max_location, easting, northing)
             
            polygon_datasets = [];

            N_polygons = 1;

            if ~isempty(polygons)
                N_polygons = polygons.N_elements;
            end

            ctx = hdng.rasters.RasterContext([raster_size 1]);
            
            x = obj.data(:, obj.identifiers.(easting));
            y = obj.data(:, obj.identifiers.(northing));
            
            for p=1:N_polygons
                
                if isempty(polygons)

                    polygon = [];
                    polygon_selection = [];

                else
                    polygon = polygons.nth_element(p);
                    polygon_vertices = polygon.collect_nan_delimited_ring_vertices();
            
                    polygon_selection = inpolygon(x, y, polygon_vertices(:, 1), polygon_vertices(:, 2))';
                end

                polygon_dataset = obj.select(polygon_selection, -1);

                polygon_query = geospm.reports.PolygonQuery(slice_index, p, polygon);
                
                polygon_query.min_location = min_location(1:2);
                polygon_query.max_location = max_location(1:2);
                polygon_query.cell_size = cell_size;
                polygon_query.record = record;
        
                polygon_query.mask = polygon_query.compute_mask(ctx);

                polygon_dataset.query = polygon_query;
                
                polygon_datasets = [polygon_datasets; polygon_dataset]; %#ok<AGROW>
            end
        end

        function [obj, parameters] = apply_transforms(obj, variable_transforms)
            
            if ~exist('variable_transforms', 'var') || isempty(variable_transforms)
                variable_transforms = obj.variable_names;
                variable_transforms(:, 2) = {'zscore'};
            end
            
            if isstruct(variable_transforms)
                    
                applicable_transforms = cell(numel(obj.variable_names), 2);
    
                T = 0;
            
                for k=1:numel(obj.variable_names)
    
                    name = obj.variable_names{k};
            
                    if isfield(variable_transforms, name)
    
                        T = T + 1;
                        
                        applicable_transforms{T, 1} = name;
                        applicable_transforms{T, 2} = variable_transforms.(name);
                    end
                end

                variable_transforms = applicable_transforms;
            end

            %column_order = obj.index_variables_by_name(variable_transforms(:, 1));

            %{
            column_order = zeros([size(variable_transforms, 1), 1], 'double');
            
            for index=1:size(variable_transforms, 1)
                name = variable_transforms{index, 1};
                name_index = find(strcmp(obj.variable_names, name), 1);
        
                column_order(index) = name_index;
            end
            %}

            result = geospm.reports.ReportDataset(obj.data, obj.variable_names);
            result.query = obj.query;

            parameters = struct();
        
            for index=1:size(variable_transforms, 1)
                name = variable_transforms{index, 1};
                name_index = find(strcmp(obj.variable_names, name), 1);
                
                transform_names = variable_transforms{index, 2};
                
                if ~iscell(transform_names)
                    transform_names = {transform_names};
                end
                
                P = {};
                
                for t=1:numel(transform_names)
                    transform_name = transform_names{t};
                    f = str2func(['geospm.reports.ReportDataset.transform_' transform_name]);
                    [result.data(:, name_index), p] = f(obj.data(:, name_index));
                    P{end + 1} = p; %#ok<AGROW>
                end
        
                parameters.(name) = P;
            end
        end
        
        function [variable_indices, selector] = select_variables_by_name(obj, selected_names, exclude_constants)
        
            if ~exist('exclude_constants', 'var')
                exclude_constants = false;
            end

            selector = zeros(size(obj.variable_names), 'logical');
            variable_indices = zeros(size(obj.variable_names));

            match_count = 0;
        
            for k=1:numel(selected_names)
                name = selected_names{k};

                variable_index = find(strcmp(obj.variable_names, name), 1);

                if isempty(variable_index)
                    continue;
                end
                
                match_count = match_count + 1;

                selector(variable_index) = 1;
                variable_indices(k) = variable_index;

                if exclude_constants && std(obj.data(:, variable_index)) == 0.0
                    selector(variable_index) = 0;
                    match_count = match_count - 1;
                end
            end

            variable_indices = variable_indices(1: match_count);
        end
        
        function variable_indices = index_variables_by_name(obj, selected_names)
        
            variable_indices = zeros(size(selected_names), 'int64');
        
            for k=1:numel(selected_names)
                variable_name = selected_names{k};

                variable_index = find(strcmp(obj.variable_names, variable_name), 1);
        
                if ~isempty(variable_index)
                    variable_indices(k) = variable_index;
                end
            end
        end
        
        function diary_file = apply_bayesreg(obj, identifier, covariate_names, covariate_transforms, output_directory, options)
        
            extra_dataset = obj.select(-1, options.extra_names);
            
            covariate_names = obj.select_variables_by_name(covariate_names, true);
            obj = obj.select(-1, covariate_names, covariate_transforms);
            
            dataset_file = fullfile(output_directory, sprintf('dataset_%s.mat', identifier));
            
            tmp_dataset = bayesreg_dataset(obj.data, obj.variable_names);
            
            tmp_dataset.extra_values = extra_dataset.data;
            tmp_dataset.extra_variable_names = extra_dataset.variable_names;
            
            save(dataset_file, '-struct', 'tmp_dataset');
        
            dataset_file_csv = fullfile(output_directory, sprintf('dataset_%s.csv', identifier));
            header_line = [extra_dataset.variable_names; obj.variable_names]';
        
            writecell(...
                [header_line;
                 num2cell([extra_dataset.data, obj.data])], dataset_file_csv);
            
            %{

            variable_indices = obj.index_variables_by_name(covariate_names);

            dataset_response = variable_indices(1);
            dataset_variant = variable_indices(2);
            
            dataset_response = dataset.data(:, dataset_response);
            dataset_variant = dataset.data(:, dataset_variant);
        
            f1 = figure;
            scatter(dataset_response, dataset_variant);
            diagram_file = fullfile(file_directory, sprintf('scatter_%s.pdf', identifier));
            exportgraphics(f1, diagram_file,'ContentType','vector');
            close(f1);

            diagram_file = fullfile(file_directory, sprintf('scatter_%s.pdf', identifier));
            dataset.plot_scatter(response_name, variant_name, diagram_file);
            %}

            bayesreg_options = struct();
            bayesreg_options.model = 'gaussian';
            bayesreg_options.prior = 'ridge';
            bayesreg_options.N_samples = 1e5;
            bayesreg_options.N_burn_in_samples = 1e5;
            bayesreg_options.seed = 841825397; % randi(intmax('int32') - 1);
            bayesreg_options.display = true;
            bayesreg_options.display_odds_ratio = false;
            bayesreg_options.display_sort = true;
            
            diary_file = fullfile(output_directory, sprintf('dataset_%s_result.txt', identifier));
            
            diary(diary_file);
            
        
            del = '=======================================================================================================================';

            %{
            C = corrcoef(dataset_response, dataset_variant);
            C = C(1, 2);
            
            fprintf('%s\nPolygon: %d\nResponse: %s\nVariant:  %s\nCorrelation Coefficient:  %.4f\n', del, index, response_name, variant_name, C);
            %}

            polygon_symbol = obj.mask_to_ascii_art(obj.query.mask);
        
            %print_region_transforms(region, suffix);
            fprintf('%s\n%s\n\n', polygon_symbol, del);
            
            bayesreg_fit_regression(dataset_file, 1, bayesreg_options);
            diary off;
        end

        function plot_scatter(obj, independent_variable, dependent_variable, diagram_file)

            indices = obj.index_variables_by_name({independent_variable, dependent_variable});

            independent_variable = obj.data(:, indices(1));
            dependent_variable = obj.data(:, indices(2));
        
            f1 = figure;
            scatter(independent_variable, dependent_variable);
            exportgraphics(f1, diagram_file, 'ContentType', 'vector');
            close(f1);
        end

    end

    methods (Static)
    
        function result = load(file_path, cache, aliases, ctor)
            
            if ~cache.holds_key(file_path)

                if ~exist('ctor', 'var')
                    ctor = @geospm.reports.ReportDataset;
                end
                
                [file_directory, file_name, file_ext] = fileparts(file_path);
        
                actual_file_path = file_path;
        
                if aliases.holds_key(file_path)
                    actual_file_path = aliases(file_path);
                elseif aliases.holds_key(file_directory)
                    actual_file_path = fullfile(aliases(file_directory), [file_name, file_ext]);
                end
                
                data_opts = detectImportOptions(actual_file_path, 'VariableNamingRule', 'preserve');

                variable_names = data_opts.VariableNames';
                values = readmatrix(actual_file_path, data_opts);
                
                data_descriptor = ctor(values, variable_names);

                cache(file_path) = data_descriptor;
            end
        
            result = cache(file_path);
        end
    end

    methods (Static, Access=protected)
    
        function [result, parameters] = transform_zscore(values)
            parameters = struct();
            parameters.name = 'zscore';
            [result, parameters.mean, parameters.stddev] = normalize(values);
        end
        
        function [result, parameters] = transform_boxcox(values)
            parameters = struct();
            parameters.name = 'boxcox';
            [result, parameters.lambda] = boxcox(values);
        end
        
        function [result, parameters] = transform_reciprocal(values)
            parameters = struct();
            parameters.name = 'reciprocal';
            result = 1 ./ values;
        end
        
        function [result, parameters] = transform_log(values)
            parameters = struct();
            parameters.name = 'log';
            result = log(values);
        end
        
        function [result, parameters] = transform_quantilenorm(values)
            parameters = struct();
            parameters.name = 'quantilenorm';
            
            [~, order] = sort(values);
        
            ranks = zeros(size(values));
            ranks(order) = 1:numel(values);
        
            result = norminv((ranks - 0.5) / numel(values));
        
            %{
            normal_values = normrnd(mean(values), std(values), size(values));
            result = quantilenorm([values(:), normal_values(:)]);
            result = result(:, 1);
            %}
        end

        
        function mask_symbol = mask_to_ascii_art(mask)
            mask_symbol = [];
        
            for row_index=size(mask, 2):-1:1
                row = char(size(mask, 1));
                row(mask(:, row_index)) = '+';
                row(~mask(:, row_index)) = ' ';
                mask_symbol = [mask_symbol, newline, '|', row, '|']; %#ok<AGROW>
            end
        
            mask_symbol = mask_symbol(2:end);
            
            border = '';
        
            for col_index=1:size(mask, 2) + 2
                border = [border, '-']; %#ok<AGROW>
            end
        
            mask_symbol = [border, newline, mask_symbol, newline, border];
        end
    
    end
end
