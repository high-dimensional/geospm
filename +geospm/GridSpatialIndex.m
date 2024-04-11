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

classdef GridSpatialIndex < geospm.SpatialIndex
    %GridSpatialIndex Summary goes here.
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

        min_uv % [min_u, min_v]
        max_uv % [max_u, max_v]
        
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
        
        function obj = GridSpatialIndex(u, v, w, x, y, z, segment_sizes, resolution, grid, crs)
            
            %Construct a GridSpatialIndex object from u, v, and w integer vectors and
            % their analogue x, y and z vectors and their segments.
            %
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
            
            if ~isinteger(u)
                error('u is not an integral numeric type.');
            end
            
            if ~isinteger(v)
                error('v is not an integral numeric type.');
            end
            
            if ~isempty(w) && ~isinteger(w)
                error('w is not an integral numeric type.');
            end
            
            if ~isequal(cast(resolution, 'int64'), cast(resolution, 'double'))
                error('resolution must be specified as integer values.');
            end
            
            obj = obj@geospm.SpatialIndex(x, y, z, segment_sizes, crs);
            
            obj.u = u;
            obj.v = v;
            obj.w = w;
            
            if (obj.u_min < 1) || (obj.u_max > resolution(1))
                error(['One or more u locations are not in the specified resolution [' num2str(resolution(1), '%d') '].']);
            end
            
            if (obj.v_min < 1) || (obj.v_max > resolution(2))
                error(['One or more v locations are not in the specified resolution [' num2str(resolution(2), '%d') '].']);
            end
            
            if (obj.w_min < 1) || (obj.w_max > resolution(3))
                error(['One or more w locations are not in the specified resolution [' num2str(resolution(3), '%d') '].']);
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
        
        function result = get.min_uv(obj)
            result = [obj.u_min, obj.v_min];
        end
        
        function result = get.max_uv(obj)
            result = [obj.u_max, obj.v_max];
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

        function [u, v, w] = uvw_coordinates_for_segment(obj, segment_index)
            
            [first, last] = obj.range_for_segment(segment_index);

            u = obj.u(first:last);
            v = obj.v(first:last);
            w = obj.w(first:last);
        end
        
        function result = as_json_struct(obj, varargin)

            result = as_json_struct@geospm.SpatialIndex(obj, varargin{:});
            
            result.ctor = 'geospm.GridSpatialIndex';

            result.u = obj.u;
            result.v = obj.v;
            result.w = obj.w;

            result.resolution = obj.resolution;
            result.grid = obj.grid.as_json_struct();
        end
    end
    
    methods (Access=protected)

        function assign_property(obj, name, values)
            obj.(name) = values;
        end

        function [specifier, modifier] = define_clone_specifier(obj)
            
            [specifier, modifier] = define_clone_specifier@geospm.SpatialIndex(obj);
            
            specifier.per_row.u = obj.u;
            specifier.per_row.v = obj.v;
            specifier.per_row.w = obj.w;

            specifier.resolution = obj.resolution;
            specifier.grid = obj.grid.as_json_struct();
        end

        function result = create_clone_from_specifier(~, specifier)

            result = geospm.GridSpatialIndex(specifier.per_row.u, ...
                                             specifier.per_row.v, ...
                                             specifier.per_row.w, ...
                                             specifier.per_row.x, ...
                                             specifier.per_row.y, ...
                                             specifier.per_row.z, ...
                                             specifier.segment_sizes, ...
                                             specifier.resolution, ...
                                             specifier.grid, ...
                                             specifier.crs);
        end

    end

    methods (Static)

        function result = from_json_struct(specifier)
            


            if ~isfield(specifier, 'x') || ~isnumeric(specifier.x)
                error('Missing ''x'' field in json struct or ''x'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'y') || ~isnumeric(specifier.y)
                error('Missing ''y'' field in json struct or ''y'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'z') || ~isnumeric(specifier.z)
                error('Missing ''z'' field in json struct or ''z'' field is not numeric.');
            end

            
            if ~isfield(specifier, 'u') || ~isnumeric(specifier.u)
                error('Missing ''u'' field in json struct or ''u'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'v') || ~isnumeric(specifier.v)
                error('Missing ''v'' field in json struct or ''v'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'w') || ~isnumeric(specifier.w)
                error('Missing ''w'' field in json struct or ''w'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'segment_sizes') || ~isnumeric(specifier.segment_sizes)
                error('Missing ''segment_sizes'' field in json struct or ''segment_sizes'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'resolution') || ~isnumeric(specifier.resolution)
                error('Missing ''resolution'' field in json struct or ''resolution'' field is not numeric.');
            end
            
            if isfield(specifier, 'crs') && ~ischar(specifier.crs)
                error('''crs'' field is not char.');
            end
            
            if isfield(specifier, 'grid') && ~isstruct(specifier.grid)
                error('''grid'' field is not a struct.');
            end
            
            crs = '';

            if isfield(specifier, 'crs') && ~isempty(specifier.crs)
                crs = specifier.crs;
            end

            grid = [];

            if isfield(specifier, 'grid') && ~isempty(specifier.grid)
                grid = specifier.grid;
            end
            
            result = geospm.GridSpatialIndex(specifier.u, specifier.v, specifier.w, specifier.x, specifier.y, specifier.z, specifier.segment_sizes, specifier.resolution, grid, crs);

        end
    end
end
