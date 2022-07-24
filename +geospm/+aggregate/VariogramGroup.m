% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2021,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %


classdef VariogramGroup < hdng.aggregate.FileAggregatorGroup
    
    properties
        categories
        names
        covariogram_models
        empirical_covariograms
    end
    
    methods
        
        function obj = VariogramGroup(name, mode, options)
            
            obj = obj@hdng.aggregate.FileAggregatorGroup(name, mode, options);
            
            obj.categories = {};
            obj.names = {};
            obj.covariogram_models = {};
            obj.empirical_covariograms = {};
            
            if ~isfield(obj.options, 'plot_resolution')
                obj.options.plot_resolution = 200;
            end
        end
        
        function prepare(obj)
            
            obj.categories = {};
            obj.names = {};
            obj.covariogram_models = {};
            obj.empirical_covariograms = {};
        end
        
        function gather_entry(obj, entry)
            
            obj.entries{end + 1} = entry;
            
            switch obj.mode
                
                case {'horizontal', 'vertical'}
                    
                    obj.merge_variograms(entry.category, entry.name, entry.covariogram_model, entry.empirical_covariogram);
            end
        end
        
        function gather_group(obj, group)
            
            obj.entries{end + 1} = group;
            
            switch obj.mode
                
                case {'horizontal', 'vertical'}
                    
                    for index=1:numel(group.covariogram_models)
                        obj.merge_variograms(group.categories{index}, ...
                                             group.names{index}, ...
                                             group.covariogram_models{index}, ...
                                             group.empirical_covariograms{index});
                    end
            end
        end
        
        function merge_variograms(obj, category, name, covariogram_model, empirical_covariogram)
            obj.categories{end + 1} = category;
            obj.names{end + 1} = name;
            obj.covariogram_models{end + 1} = covariogram_model;
            obj.empirical_covariograms{end + 1} = empirical_covariogram;
        end
        
        function finalise(obj) %#ok<MANU>
        end
        
        function process(obj, output_directory)
            
            if numel(obj.empirical_covariograms) == 0
                return;
            end
            
            output_directory = obj.make_output_path(output_directory);
            layout = 'row';
            marker_size = 15;
            
            f = figure;
            
            ax = gca;
            %axis(ax, 'equal', 'auto');
            axis(ax, 'square');
            
            N = obj.empirical_covariograms{1}.N_components;
            K = numel(obj.empirical_covariograms{1}.variograms);
            
            max_x = obj.round_scale(obj.compute_max_x());
            max_y = obj.round_scale(obj.compute_max_y_at_x(max_x, obj.options.plot_resolution) * 1.1);
            
            for index=1:numel(obj.empirical_covariograms)
                
                empirical_covariogram = obj.empirical_covariograms{index};
                fitted_model = obj.covariogram_models{index};
                
                empirical_covariogram.plot(fitted_model, ...
                    'distance_limit', max_x, ...
                    'gamma_limit', max_y, ...
                    'plot_resolution', obj.options.plot_resolution, ...
                    'LineWidth', 1.0, 'layout', layout, 'MarkerSize', marker_size);
            end

            colours = [
                  0, 103,  77;
                  0, 103,  77;
                 20, 184, 143;
                 20, 184, 143;
                121, 236, 207;
                121, 236, 207;
                 
            ] / 255.0;
            
            for index=1:K
                
                [x, y] = geospm.variograms.CovariogramModel.index_to_xy(index);
                
                
                switch layout
                    case 'row'
                        k = index;
                        ax = subplot(1, K + 1, k);
                        
                        if index == 1
                            ylabel('Semivariance', 'FontWeight', 'bold');
                        end
                        
                        xlabel('Distance', 'FontWeight', 'bold');
                        
                    otherwise
                        
                        k = (x - 1) * N + y;
                        ax = subplot(N, N, k);
                        

                        if y == 1
                            ylabel('Semivariance', 'FontWeight', 'bold');
                        end

                        if x == N
                            xlabel('Distance', 'FontWeight', 'bold');
                        end
                end

                ytickformat('%.2f');

                set(ax, 'FontName', 'Barlow-Regular');
    
                
                fitted_model = obj.covariogram_models{1};
                variogram = fitted_model.variograms{index};
                correlations = variogram.correlations(~variogram.nugget_components);

                if isempty(correlations)
                    correlations = variogram.correlations(variogram.nugget_components);
                end
                
                if ~isempty(correlations)
                    title([replace(variogram.name, '.', 'x') ': ' correlations{1}.name]);
                end
                
                ax.ColorOrder = colours;
            end
            
            %{
            for index=1:K

                [x, y] = geospm.variograms.CovariogramModel.index_to_xy(index);
                
                switch layout
                    case 'row'
                        k = index;
                        ax = subplot(1, K + 1, k);
                        
                    otherwise
                        
                        k = (x - 1) * N + y;
                        ax = subplot(N, N, k);
                end
                
                if isfinite(max_x) && max_x > 0.0
                    xlim([0, max_x]);
                end
                
                if isfinite(max_y) && max_y > 0.0
                    ylim([0, max_y]);
                end
                
                ax.ColorOrder = colours;
            end
            %}
            
            L = numel(obj.empirical_covariograms);
            
            mapped_labels = obj.categories;
            
            for index=1:numel(mapped_labels)
                label = mapped_labels{index};
                if isKey(obj.options.file_name_map, label)
                    label = obj.options.file_name_map(label);
                end
                
                mapped_labels{index} = label;
            end
            
            legend_labels = {};
            legend_labels(1:2:L + L) = mapped_labels;
            legend_labels(2:2:L + L) = mapped_labels;
            
            for index=1:2:L + L
                legend_labels{index} = ['Empirical ' legend_labels{index}];
                legend_labels{index + 1} = ['Fitted ' legend_labels{index + 1}];
            end
            
            lg = legend;
            lg.String = legend_labels;
            
            
            pos = lg.Position;

            switch layout
                case 'row'
                    pos(1) = 0.75; %0.42;
                    pos(2) = 0.51;

                otherwise
                    pos(2) = 0.93 - pos(4);
            end

            lg.Position = pos;
            
            
            set(lg,'Box','off');
            
            pp = f.PaperPosition * 1.4;
            
            set(f, 'PaperPositionMode', 'auto',  ...
                   'PaperSize', [pp(3), pp(4)], ...
                   'PaperPosition', [0, 0, pp(3), pp(4)]);
            
            save_eps = any(strcmp('eps', obj.options.output_formats));
            save_png = any(strcmp('png', obj.options.output_formats));
            
            if save_eps
                eps_path = [output_directory '.eps'];
                saveas(ax, eps_path, 'epsc');
            end
            
            if save_png
                png_path = [output_directory '.png'];
                saveas(ax, png_path, 'png');
            end
            
            close(f);
            
            if save_eps
                
                eps_text = hdng.utilities.load_text(eps_path);
                eps_text = regexprep(eps_text, 'Courier([^-])', 'Barlow-Regular$1');
                eps_text = regexprep(eps_text, 'Courier-', 'Barlow-');
                eps_text = regexprep(eps_text, 'Barlow-Bold([^-])', 'Barlow-Medium$1');

                hdng.utilities.save_text(eps_text, eps_path);
            end
        end
        
        function result = compute_max_x(obj)
            
            x_range = zeros(1, numel(obj.empirical_covariograms));
            
            for index=1:numel(obj.empirical_covariograms)
                
                empirical_covariogram = obj.empirical_covariograms{index};
                x_range(index) = empirical_covariogram.max_distance;
            end
            
            result = max(x_range);
        end
        
        function result = compute_max_y_at_x(obj, x, steps)
            
            y_range = zeros(1, numel(obj.empirical_covariograms));
            
            for index=1:numel(obj.empirical_covariograms)
                
                empirical_covariogram = obj.empirical_covariograms{index};
                fitted_model = obj.covariogram_models{index};
                
                y_range(index) = max([empirical_covariogram.max_gamma, fitted_model.max_y_at_x(x, steps)]);
            end
            
            result = max(y_range);
        end
    end
    
    methods (Static)
        
        function result = round_scale(x)
            
            log_x = log10(x);
            scale_x = power(10, sign(log_x) * ceil(abs(log_x)));
            
            result = ceil(x / scale_x) * scale_x;
        end
    end
end

