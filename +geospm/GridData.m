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

classdef GridData < geospm.SpatialData
    %GridData Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
        
        resolution % a 3-vector specifying the u, v and w size of the grid
        
        u % a column vector of length N (a N by 1 matrix) of observation grid x locations
        v % a column vector of length N (a N by 1 matrix) of observation grid y locations
        w % a column vector of length N (a N by 1 matrix) of observation grid z locations
        
        grid
    end
    
    properties (Dependent, Transient)
        
        u_min % minimum u value
        u_max % maximum u value
        
        v_min % minimum v value
        v_max % maximum v value
        
        w_min % minimum w value
        w_max % maximum w value
        
        min_uvw % [min_u, min_v, min_w]
        max_uvw % [max_u, max_v, max_w]
        
        uvw
    end
    
    properties (GetAccess = private, SetAccess = private)
        
        u_min_
        u_max_
        
        v_min_
        v_max_
        
        w_min_
        w_max_
    end
    
    
    methods
        
        function obj = GridData(u, v, w, x, y, z, observations, resolution, grid, crs)
            
            %Construct a GridData object from u, v, and w integer vectors and
            % their analogue x, y and z vectors and a matrix of corresponding observations.
            %
            % observations ? A matrix which is checked for NaN values, which will cause an error to be thrown. 
            % resolution ? 3-vector specifying grid size in the x and y
            % dimensions.
            
            if ~exist('grid', 'var')
                grid = geospm.Grid();
            end
            
            if ~exist('crs', 'var')
                crs = hdng.SpatialCRS.empty;
            end
            
            if ~isnumeric(u) || size(u, 2) ~= 1
                error('''u'' is not a numeric value; specify ''u'' as a N x 1 matrix');
            end
            
            if ~isnumeric(v) || size(v, 2) ~= 1
                error('''v'' is not a numeric value; specify ''v'' as a N x 1 matrix');
            end
            
            if ~isnumeric(w)
                error('''w'' is not a numeric value; specify ''w'' as a N x 1 matrix or []');
            end
            
            if size(u, 1) ~= size(v, 1)
                error('The number of elements in ''u'' (=%d) and ''v'' (=%d) do not match; specify both ''u'' and ''v'' as a N x 1 matrix', size(u,1), size(v,1));
            end
            
            if isempty(w)
                w = ones(size(u), 'int64');
            end
            
            if size(w, 2) ~= 1
                error('''w'' is not a numeric value; specify ''w'' as a N x 1 matrix or []');
            end
            
            if size(u, 1) ~= size(w, 1)
                error('The number of elements in ''u'' (=%d) and ''w'' (=%d) do not match; specify ''u'', ''v'' and ''w'' each as a N x 1 matrix', size(u,1), size(w,1));
            end
            
            if ~isnumeric(observations)
                error('''observations'' is not a numeric value; specify ''observations'' as a N x P matrix');
            end
            
            if ~isempty(observations) && size(u, 1) ~= size(observations, 1)
                error('The number of rows in ''u'' and ''v'' (=%d) and ''observations'' (=%d) do not match; specify both ''u'' and ''v'' as a N x 1 matrix, and ''observations'' as a N x P matrix', size(u,1), size(observations,1));
            end
            
            if ~isinteger(u)
                error('GridData(): u is not an integral numeric type.');
            end
            
            if ~isinteger(v)
                error('GridData(): v is not an integral numeric type.');
            end
            
            if ~isempty(w) && ~isinteger(w)
                error('GridData(): w is not an integral numeric type.');
            end
            
            if ~isequal(cast(resolution, 'int64'), cast(resolution, 'double'))
                error('GridData(): resolution must be specified as integer values.');
            end
            
            obj = obj@geospm.SpatialData(x, y, z, observations, crs);
            
            obj.u = u;
            obj.v = v;
            obj.w = w;
            
            if (obj.u_min < 1) || (obj.u_max > resolution(1))
                error(['GridData(): One or more u locations are not in the specified resolution [' num2str(resolution(1), '%d') '].']);
            end
            
            if (obj.v_min < 1) || (obj.v_max > resolution(2))
                error(['GridData(): One or more v locations are not in the specified resolution [' num2str(resolution(2), '%d') '].']);
            end
            
            if (obj.w_min < 1) || (obj.w_max > resolution(3))
                error(['GridData(): One or more w locations are not in the specified resolution [' num2str(resolution(3), '%d') '].']);
            end
            
            obj.resolution = resolution;
            obj.grid = grid;
        end
        
        function result = get.u_min(obj)
            if isempty(obj.u_min_)
                obj.u_min_ = min(obj.u);
            end
            
            result = obj.u_min_;
        end
        
        function result = get.u_max(obj)
            if isempty(obj.u_max_)
                obj.u_max_ = max(obj.u);
            end
            
            result = obj.u_max_;
        end
        
        function result = get.v_min(obj)
            if isempty(obj.v_min_)
                obj.v_min_ = min(obj.v);
            end
            
            result = obj.v_min_;
        end
        
        function result = get.v_max(obj)
            if isempty(obj.v_max_)
                obj.v_max_ = max(obj.v);
            end
            
            result = obj.v_max_;
        end
        
        function result = get.w_min(obj)
            if isempty(obj.w_min_)
                obj.w_min_ = min(obj.w);
            end
            
            result = obj.w_min_;
        end
        
        function result = get.w_max(obj)
            if isempty(obj.w_max_)
                obj.w_max_ = max(obj.w);
            end
            
            result = obj.w_max_;
        end
        
        function result = get.min_uvw(obj)
            result = [obj.u_min, obj.v_min, obj.w_min];
        end
        
        function result = get.max_uvw(obj)
            result = [obj.u_max, obj.v_max, obj.w_max];
        end
        
        function result = get.uvw(obj)
            result = [obj.u, obj.v, obj.w];
        end
        
        function render_in_figure(obj, origin, frame_size)
            
            if ~exist('origin', 'var')
                origin = [obj.u_min, obj.v_min];
            end
            
            if ~exist('frame_size', 'var')
                frame_size = [obj.u_max, obj.v_max] - origin;
            end
            
            obj.render_categories_in_figure(obj.u, obj.v, origin, frame_size);
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
            
            
            if ~isfield(options, 'drop_u')
                options.drop_u = false;
            end
            
            if ~isfield(options, 'drop_v')
                options.drop_v = false;
            end
            
            if ~isfield(options, 'drop_w')
                options.drop_w = false;
            end
            
            if ~isfield(options, 'u_name')
                options.u_name = 'u';
            end
            
            if ~isfield(options, 'v_name')
                options.v_name = 'v';
            end
            
            if ~isfield(options, 'w_name')
                options.w_name = 'w';
            end
            
            
            u_min_max = [obj.u_min, obj.u_max];
            v_min_max = [obj.v_min, obj.v_max];
            w_min_max = [obj.w_min, obj.w_max];
            
            if ~options.drop_u
                specifier.(options.u_name) = u_min_max(2) - obj.u;
            end
            
            if ~options.drop_v
                specifier.(options.v_name) = v_min_max(2) - obj.v;
            end
            
            if ~options.drop_w
                specifier.(options.w_name) = w_min_max(2) - obj.w;
            end
            
            result = specifier;
        end
        
        function result = as_table(obj, options)
            
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
            
            if ~isfield(options, 'drop_u')
                options.drop_u = false;
            end
            
            if ~isfield(options, 'drop_v')
                options.drop_v = false;
            end
            
            if ~isfield(options, 'drop_w')
                options.drop_w = false;
            end
            
            if ~isfield(options, 'u_name')
                options.u_name = 'u';
            end
            
            if ~isfield(options, 'v_name')
                options.v_name = 'v';
            end
            
            if ~isfield(options, 'w_name')
                options.w_name = 'w';
            end
            
            if ~isfield(options, 'drop_x')
                options.drop_x = options.drop_u;
            end
            
            if ~isfield(options, 'drop_y')
                options.drop_y = options.drop_v;
            end
            
            if ~isfield(options, 'drop_z')
                options.drop_z = options.drop_w;
            end
            
            if ~isfield(options, 'x_name')
                options.x_name = options.u_name;
            end
            
            if ~isfield(options, 'y_name')
                options.y_name = options.v_name;
            end
            
            if ~isfield(options, 'z_name')
                options.z_name = options.w_name;
            end
            
            if options.include_categories
                options.categories = obj.categories;
            end
            
            if options.include_labels
                options.labels = obj.labels;
            end
            
            result = obj.xyz_observations_as_table(obj.u, obj.v, obj.w, obj.observations, obj.variable_names, options);
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
            arguments.u = obj.u(row_selection);
            arguments.v = obj.v(row_selection);
            arguments.w = obj.w(row_selection);
            arguments.resolution = obj.resolution;
            arguments.grid = obj.grid;
            arguments.crs = obj.crs;
            arguments.check_for_nans = obj.did_check_for_nans;
            
            [arguments.row_map, arguments.column_map] = obj.clone_maps_from_selection(row_selection, column_selection);
            
            arguments = obj.apply_transform(arguments, transform);
            
            result = geospm.GridData(arguments.u, ...
                                   arguments.v, ...
                                   arguments.w, ...
                                   arguments.x, ...
                                   arguments.y, ...
                                   arguments.z, ...
                                   arguments.observations, ...
                                   arguments.resolution, ...
                                   arguments.grid, ...
                                   arguments.crs);
            
            result.description = obj.description;
            result.set_variable_names(arguments.variable_names);
            
            row_map = arguments.row_map;
            column_map = arguments.column_map;
        end
    end
    
end
