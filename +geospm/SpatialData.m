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

classdef SpatialData < geospm.NumericData
    %SpatialData Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
        
        x % a column vector of length N (a N by 1 matrix) of observation x locations
        y % a column vector of length N (a N by 1 matrix) of observation y locations
        
        z % a column vector of length N (a N by 1 matrix) of observation z locations
        
        crs % an optional SpatialCRS or empty
    end
    
    properties (Dependent, Transient)
        
        has_crs % is a crs defined?
        
        x_min % minimum x value
        x_max % maximum x value
        
        y_min % minimum y value
        y_max % maximum y value
        
        z_min % minimum z value
        z_max % maximum z value
        
        min_xyz % [min_x, min_y, min_z]
        max_xyz % [max_x, max_y, max_z]
        
        centroid_x
        centroid_y
        centroid_z
        
        centroid_xyz
        
        xyz
    end
    
    properties (GetAccess = private, SetAccess = private)
        
        x_min_
        x_max_
        
        y_min_
        y_max_
        
        z_min_
        z_max_
        
        centroid_xyz_
    end
    
    methods
        
        function obj = SpatialData(x, y, z, observations, crs, checknans)
            %Construct a SpatialData object from x, y and z vectors and a matrix of corresponding observations.
            % x ? x locations
            % y ? y locations
            % z ? z locations
            % observations ? A matrix which is checked for NaN values, which will cause an error to be thrown. 
            
            if ~exist('crs', 'var')
                crs = hdng.SpatialCRS.empty;
            end
            
            if ~exist('checknans', 'var')
                checknans = true;
            end
            
            if ~ismatrix(x) || size(x, 2) ~= 1
                error('''x'' is not a numeric value; specify ''x'' as a N x 1 matrix');
            end
            
            if ~ismatrix(y) || size(y, 2) ~= 1
                error('''y'' is not a numeric value; specify ''y'' as a N x 1 matrix');
            end
            
            if ~ismatrix(z)
                error('''z'' is not a numeric value; specify ''z'' as a N x 1 matrix or []');
            end
            
            if size(x, 1) ~= size(y, 1)
                error('The number of elements in ''x'' (=%d) and ''y'' (=%d) do not match; specify both ''x'' and ''y'' as a N x 1 matrix', size(x,1), size(y,1));
            end
            
            if isempty(z)
                z = zeros(size(x));
            end
            
            if size(z, 2) ~= 1
                error('''z'' is not a numeric value; specify ''z'' as a N x 1 matrix or []');
            end
            
            if size(x, 1) ~= size(z, 1)
                error('The number of elements in ''x'' (=%d) and ''z'' (=%d) do not match; specify ''x'', ''y'' and ''z'' each as a N x 1 matrix', size(x,1), size(z,1));
            end
            
            if ~ismatrix(observations)
                error('''observations'' is not a numeric value; specify ''observations'' as a N x P matrix');
            end
            
            if ~isempty(observations) && size(x, 1) ~= size(observations, 1)
                error('The number of rows in ''x'' and ''y'' (=%d) and ''observations'' (=%d) do not match; specify both ''x'' and ''y'' as a N x 1 matrix, and ''observations'' as a N x P matrix', size(x,1), size(observations,1));
            end
            
            if ~isempty(crs) && ~isa(crs, 'hdng.SpatialCRS') && ~ischar(crs)
                error('''crs'' should be a hdng.SpatialCRS instance, empty ([]) or a string identifier.');
            end
            
            obj = obj@geospm.NumericData(observations, size(x, 1), checknans);
            
            obj.x = x;
            obj.y = y;
            obj.z = z;
            
            if isempty(crs)
                crs = hdng.SpatialCRS.empty;
            elseif ischar(crs)
                crs = hdng.SpatialCRS.from_identifier(crs);
            end
            
            obj.crs = crs;
        end
        
        function result = get.has_crs(obj)
            result = ~isempty(obj.crs);
        end
        
        function result = get.x_min(obj)
            if isempty(obj.x_min_)
                obj.x_min_ = min(obj.x);
            end
            
            result = obj.x_min_;
        end
        
        function result = get.x_max(obj)
            if isempty(obj.x_max_)
                obj.x_max_ = max(obj.x);
            end
            
            result = obj.x_max_;
        end
        
        function result = get.y_min(obj)
            if isempty(obj.y_min_)
                obj.y_min_ = min(obj.y);
            end
            
            result = obj.y_min_;
        end
        
        function result = get.y_max(obj)
            if isempty(obj.y_max_)
                obj.y_max_ = max(obj.y);
            end
            
            result = obj.y_max_;
        end
        
        function result = get.z_min(obj)
            if isempty(obj.z_min_)
                obj.z_min_ = min(obj.z);
            end
            
            result = obj.z_min_;
        end
        
        function result = get.z_max(obj)
            if isempty(obj.z_max_)
                obj.z_max_ = max(obj.z);
            end
            
            result = obj.z_max_;
        end
        
        function result = get.min_xyz(obj)
            result = [obj.x_min, obj.y_min, obj.z_min];
        end
        
        function result = get.max_xyz(obj)
            result = [obj.x_max, obj.y_max, obj.z_max];
        end
        
        function result = get.centroid_x(obj)
            result = obj.centroid_xyz(1);
        end
        
        function result = get.centroid_y(obj)
            result = obj.centroid_xyz(2);
        end
        
        function result = get.centroid_z(obj)
            result = obj.centroid_xyz(3);
        end
        
        function result = get.centroid_xyz(obj)
            if isempty(obj.centroid_xyz_)
                obj.centroid_xyz_ = [mean(obj.x), mean(obj.y), mean(obj.z)];
            end
            
            result = obj.centroid_xyz_;
        end
        
        function result = get.xyz(obj)
            result = [obj.x, obj.y, obj.z];
        end
        
        function show_variogram(obj, p_index)
            
            if ~exist('p_index', 'var')
                p_index = 1;
            end
            
            hdng.geostatistics.variogram_cloud(obj.x, obj.y, obj.observations(:,p_index));
        end
        
        function show_samples(obj)
            
            figure;
            
            ax = gca;
            axis(ax, 'equal', 'auto');
            
            s = scatter(obj.x, obj.y);
            
            s.Marker = 'o';
            s.MarkerEdgeColor = 'none';
            s.MarkerFaceColor = '#0072BD';
            
            dtt = s.DataTipTemplate;
            
            row = dataTipTextRow('Label',obj.labels);
            dtt.DataTipRows(1) = row;
            
            for i=1:obj.P
                row = dataTipTextRow(obj.labels{i,1}, obj.observations(:,i));
                dtt.DataTipRows(i + 1) = row;
            end
        end
        
        function render_in_figure(obj, origin, frame_size)
            
            if ~exist('origin', 'var')
                origin = [obj.x_min, obj.y_min];
            end
            
            if ~exist('frame_size', 'var')
                frame_size = [obj.x_max, obj.y_max] - origin;
            end
            
            obj.render_xy_in_figure(obj.x, obj.y, obj.categories, origin, frame_size);
        end
        
        function write_as_eps(obj, file_path, point1, point2)
            
            if ~exist('point1', 'var')
                point1 = [obj.x_min, obj.y_min];
            end
            
            if ~exist('point2', 'var')
                point2 = [obj.x_max, obj.y_max];
            end
            
            [origin, frame_size] = obj.span_frame(point1, point2);
            
            figure('Renderer', 'painters');
            ax = gca;
            obj.render_in_figure(origin, frame_size);

            saveas(ax, file_path, 'epsc');
            
            close;
        end
        
        function write_as_png(obj, file_path, point1, point2)
            
            if ~exist('point1', 'var')
                point1 = [obj.x_min, obj.y_min];
            end
            
            if ~exist('point2', 'var')
                point2 = [obj.x_max, obj.y_max];
            end
            
            [origin, frame_size] = obj.span_frame(point1, point2);
            
            figure('Renderer', 'painters');
            ax = gca;
            
            obj.render_in_figure(origin, frame_size);
            
            saveas(ax, file_path, 'png');
            
            close;
            
            
        end
        
        function [origin, frame_size] = span_frame(~, point1, point2)
            
            min_point = [min(point1(1), point2(1)), min(point1(2), point2(2))];
            max_point = [max(point1(1), point2(1)), max(point1(2), point2(2))];
            
            origin = min_point;
            frame_size = max_point - min_point;
        end
        
     
        function result = as_json_struct(obj, options)
            %Creates a JSON representation of this SpatialData object.
            % The following fields can be provided in the options
            % argument:
            % include_categories ? Indicates whether a field named
            % 'categories' should be created in the JSON record.
            % include_labels ? Indicates whether a field named
            % 'labels' shoudl be created in the JSON record.
            
            specifier = as_json_struct@geospm.NumericData(obj, options);
            
            if ~isfield(options, 'drop_x')
                options.drop_x = false;
            end
            
            if ~isfield(options, 'drop_y')
                options.drop_y = false;
            end
            
            if ~isfield(options, 'drop_z')
                options.drop_z = false;
            end
            
            if ~isfield(options, 'x_name')
                options.x_name = 'x';
            end
            
            if ~isfield(options, 'y_name')
                options.y_name = 'y';
            end
            
            if ~isfield(options, 'z_name')
                options.z_name = 'z';
            end
            
            x_min_max = [obj.x_min, obj.x_max];
            y_min_max = [obj.y_min, obj.y_max];
            z_min_max = [obj.z_min, obj.z_max];
            
            if ~options.drop_x
                specifier.(options.x_name) = x_min_max(2) - obj.x;
            end
            
            if ~options.drop_y
                specifier.(options.y_name) = y_min_max(2) - obj.y;
            end
            
            if ~options.drop_z
                specifier.(options.z_name) = z_min_max(2) - obj.z;
            end
            
            result = specifier;
        end
        
        function result = as_table(obj, options)
            %Creates a Matlab Table object for this SpatialData object.
            % The following fields can be provided in the options
            % argument:
            % include_categories ? Indicates whether a field named
            % 'categories' should be created in the table.
            % include_labels ? Indicates whether a field named
            % 'labels' shoudl be created in the table.
            % x_name ? Specifies the name of the x coordinate in the table.
            % y_name ? Specifies the name of the y coordinate in the table.
            
            if ~exist('options', 'var')
                options = struct();
            end
            
            if ~isfield(options, 'include_categories')
                options.include_categories = true;
            end
            
            if ~isfield(options, 'include_labels')
                options.include_labels = true;
            end
            
            if ~isfield(options, 'categories_name')
                options.categories_name = 'categories';
            end
            
            if ~isfield(options, 'labels_name')
                options.labels_name = 'labels';
            end
            
            if ~isfield(options, 'drop_x')
                options.drop_x = false;
            end
            
            if ~isfield(options, 'drop_y')
                options.drop_y = false;
            end
            
            if ~isfield(options, 'drop_z')
                options.drop_z = false;
            end
            
            if ~isfield(options, 'x_name')
                options.x_name = 'x';
            end
            
            if ~isfield(options, 'y_name')
                options.y_name = 'y';
            end
            
            if ~isfield(options, 'z_name')
                options.z_name = 'z';
            end
            
            if options.include_categories
                options.categories = obj.categories;
            end
            
            if options.include_labels
                options.labels = obj.labels;
            end
            
            result = obj.xyz_observations_as_table(obj.x, obj.y, obj.z, obj.observations, obj.variable_names, options);
        end
        
    end
    
    methods (Access=protected)
        
        function [result, row_map, column_map] = clone_impl(obj, row_selection, column_selection, transform)
            
            selected_observations = [];
            
            if ~isempty(row_selection) && ~isempty(column_selection)
                selected_observations = obj.observations(row_selection, column_selection);
            end
            
            arguments = struct();
            arguments.observations = selected_observations;
            arguments.variable_names = obj.variable_names(column_selection);
            arguments.x = obj.x(row_selection);
            arguments.y = obj.y(row_selection);
            arguments.z = obj.z(row_selection);
            arguments.crs = obj.crs;
            arguments.check_for_nans = obj.did_check_for_nans;
            
            [arguments.row_map, arguments.column_map] = obj.clone_maps_from_selection(row_selection, column_selection);
            
            arguments = obj.apply_transform(arguments, transform);
            
            result = geospm.SpatialData(arguments.x, ...
                                      arguments.y, ...
                                      arguments.z, ...
                                      arguments.observations, ...
                                      arguments.crs, ...
                                      arguments.check_for_nans);
            
            result.description = obj.description;
            result.set_variable_names(arguments.variable_names);
            
            row_map = arguments.row_map;
            column_map = arguments.column_map;
        end
    end
    methods (Static)
        
        
        function result = xyz_observations_as_table(x, y, z, observations, variable_names, options)
            %Creates a Matlab Table object for this SpatialData object.
            % The following fields can be provided in the options
            % argument:
            % include_categories ? Indicates whether a field named
            % 'categories' should be created in the table.
            % include_labels ? Indicates whether a field named
            % 'labels' shoudl be created in the table.
            
            if ~exist('options', 'var')
                options = struct();
            end
            
            if ~isfield(options, 'categories')
                options.categories = {};
            end
            
            if ~isfield(options, 'labels')
                options.labels = {};
            end
            
            if ~isfield(options, 'categories_name')
                options.categories_name = 'categories';
            end
            
            if ~isfield(options, 'labels_name')
                options.labels_name = 'labels';
            end
            
            if ~isfield(options, 'drop_x')
                options.drop_x = false;
            end
            
            if ~isfield(options, 'drop_y')
                options.drop_y = false;
            end
            
            if ~isfield(options, 'drop_z')
                options.drop_z = false;
            end
            
            if ~isfield(options, 'x_name')
                options.x_name = 'x';
            end
            
            if ~isfield(options, 'y_name')
                options.y_name = 'y';
            end
            
            if ~isfield(options, 'z_name')
                options.z_name = 'z';
            end
            
            include_categories = ~isempty(options.categories);
            include_labels = ~isempty(options.labels);
            
            N = size(x, 1);
            
            if N ~= size(y, 1)
                error('SpatialData.xy_as_table(): X and Y size do not match.');
            end
            
            if N ~= size(observations, 1)
                error('SpatialData.xy_as_table(): X and observations size do not match.');
            end
            
            if include_categories && N ~= size(options.categories, 1)
                error('SpatialData.xy_as_table(): X and categories size do not match.');
            end
            
            if include_labels && N ~= size(options.labels, 1)
                error('SpatialData.xy_as_table(): X and labels size do not match.');
            end
            
            N_cols = 0;
            col_names = {};
            p = {};
            
            if include_labels
                N_cols = N_cols + 1;
                col_names = [col_names {options.labels_name}];
                p = [p class(options.labels)];
            end
            
            if include_categories
                N_cols = N_cols + 1;
                col_names = [col_names {options.categories_name}];
                p = [p class(options.categories)];
            end
            
            if ~options.drop_x
                N_cols = N_cols + 1;
                col_names = [col_names {options.x_name}];
                p = [p class(x)];
            end
            
            if ~options.drop_y
                N_cols = N_cols + 1;
                col_names = [col_names {options.y_name}];
                p = [p class(y)];
            end
            
            if ~options.drop_z
                N_cols = N_cols + 1;
                col_names = [col_names {options.z_name}];
                p = [p class(z)];
            end
            
            P = size(observations, 2);
            
            p = [p repelem({class(observations)}, P)];
            
            N_cols = N_cols + P;
            col_names = [col_names variable_names];
            
            result = table('Size', [N, N_cols], 'VariableTypes', p);
            result.Properties.VariableNames = col_names;
            
            if include_labels
                result.(options.labels_name) = options.labels;
            end
            
            if include_categories
                result.(options.categories_name) = options.categories;
            end
            
            if ~options.drop_x
                result.(options.x_name) = x;
            end
            
            if ~options.drop_y
                result.(options.y_name) = y;
            end
            
            if ~options.drop_z
                result.(options.z_name) = z;
            end
            
            result{:, N_cols + 1 - P:end} = observations;
        end
        
        function render_xy_in_figure(x, y, categories, origin, frame_size)
            
            if ~exist('origin', 'var')
                origin = [min(x), min(y)];
            end
            
            if ~exist('frame_size', 'var')
                frame_size = [max(x), max(y)] - origin;
            end
            
            N = size(x, 1);
            
            if N ~= size(y, 1)
                error('SpatialData.render_xy_in_figure(): X and Y size do not match.');
            end
            
            if N ~= size(categories, 1)
                error('SpatialData.render_xy_in_figure(): X and categories size do not match.');
            end
            
            colours = {
                [153, 153, 153], ...
                [255, 102, 51], ...
                [0, 204, 153], ...
                [0, 204, 255], ...
                [255, 217,  100], ...
                [148, 96, 208], ...
                [69, 208, 59]
                };
            
            ratio = frame_size(2) / frame_size(1);
            
            pixel_size = 150;
            mark_size = 2;
            
            f = gcf;
            set(f, 'MenuBar', 'none', 'ToolBar', 'none');
            set(f, 'Units', 'points');
            set(f, 'Position', [100 100 pixel_size + mark_size pixel_size * ratio + mark_size]);
            
            ax = gca;
            
            hold on;
            
            
            %Plot background polygon
            
            X = [origin(1) origin(1) origin(1) + frame_size(1) origin(1) + frame_size(1)];
            Y = [origin(2) origin(2) + frame_size(2) origin(2) + frame_size(2) origin(2)];
            
            frame = polyshape(X, Y);
            plot(frame, 'FaceColor', 'white', 'FaceAlpha', 0.5, 'LineStyle', 'none');
            
            mark_size_squared = mark_size * mark_size;
            
            N_categories = 7;
            
            marker_colours = zeros(N, 3);
            
            for k=1:N_categories
                
                selector = categories == k;
                colour = repmat(colours{k}, sum(selector), 1);
                marker_colours(categories == k, :) = colour;
            end
            
            marker_colours = marker_colours ./ 255.0;
            
            props = scatter(x, y, mark_size_squared, 'filled', 'Marker', 'o', 'MarkerEdgeColor', 'none'); %, 'Marker', 'o', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', 'magenta');
            props.CData = marker_colours;
            
            
            hold off;
            
            set(ax,'units','points');
            
            axis(ax, 'equal', 'manual', [origin(1), origin(1) + frame_size(1), origin(2), origin(2) + frame_size(2)]);
            set(ax,'color','none')
            set(ax,'visible','off');
            set(ax,'xtick',[], 'ytick', []);
            set(ax,'XColor', 'none','YColor','none');
            
            try
                set(ax,'PositionConstraint', 'innerposition');
            catch
            end
            
            margin = mark_size / 2;
            
            set(ax,'Position', [margin, margin, pixel_size, pixel_size * ratio]);
            set(f, 'PaperPositionMode', 'auto', 'PaperSize', [f.PaperPosition(3), f.PaperPosition(4)]);
            
        end
        
        function [result, other_observations] = from_csv(file_path)
            
            result = [];
            
            opts = detectImportOptions(file_path);
            N_variables = numel(opts.VariableTypes);
            
            columns = {};
            numeric_columns = {};
            non_numeric_columns = {};
            
            x_column = 0;
            y_column = 0;
            z_column = 0;
            
            for i=1:N_variables
                
                type_name = opts.VariableTypes{i};
                
                column = struct();
                column.index = i;
                column.is_numeric = hdng.utilities.isnumerictypename(type_name);
                column.is_predictor = true;
                column.name = opts.VariableNames{i};
                column.type_name = type_name;
                
                if column.is_numeric
                    
                    if x_column == 0
                        x_column = cast(strcmpi(column.name, 'x'), 'double') * i;
                    end
                    
                    if y_column == 0
                        y_column = cast(strcmpi(column.name, 'y'), 'double') * i;
                    end
                    
                    if z_column == 0
                        z_column = cast(strcmpi(column.name, 'z'), 'double') * i;
                    end
                    
                    column.is_predictor = x_column ~= i && y_column ~= i && z_column ~= i;
                end
                
                columns = [columns; {column}]; %#ok<AGROW>
                
                if ~column.is_numeric
                    non_numeric_columns = [non_numeric_columns; {column}]; %#ok<AGROW>
                elseif column.is_predictor
                    numeric_columns = [numeric_columns; {column}]; %#ok<AGROW>
                end
            end
            
            if x_column == 0 || y_column == 0
                return
            end
            
            start_index = opts.DataLines(1);
            data = readcell(file_path, 'Range', start_index);
            N_observations = size(data, 1);
            
            observations = zeros(N_observations, numel(numeric_columns));
            variable_names = cell(1, numel(numeric_columns));
            
            for i=1:numel(numeric_columns)
                column = numeric_columns{i};
                values = data(:, column.index);
                values = cell2mat(values);
                observations(:, i) = values;
                variable_names{i} = column.name;
            end
            
            x = cell2mat(data(:, x_column));
            y = cell2mat(data(:, y_column));
            z = [];
            
            if z_column
                z = cell2mat(data(:, z_column));
            end
            
            other_observations = struct();
            
            for i=1:numel(non_numeric_columns)
                column = non_numeric_columns{i};
                
                other_observations(i).name = column.name;
                other_observations(i).type_name = column.type_name;
                other_observations(i).column_index = column.index;
                other_observations(i).values = data(:, column.index);
            end
            
            result = geospm.SpatialData(x, y, z, observations);
            result.set_variable_names(variable_names);
        end
        
    end
end
