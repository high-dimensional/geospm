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

classdef BaseGridSpatialIndex < geospm.BaseSpatialIndex
    %BaseGridSpatialIndex Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
        
        resolution % a 3-vector specifying the u, v and w size of the grid
        grid
    end
    
    properties (Dependent, Transient, GetAccess=protected)
        
        u % a column vector of length N (a N by 1 matrix) of observation grid u locations
        v % a column vector of length N (a N by 1 matrix) of observation grid v locations
        w % a column vector of length N (a N by 1 matrix) of observation grid w locations
        
        uvw
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
    end
    
   
    methods

        function obj = BaseGridSpatialIndex(N, resolution, grid, crs)
            
            %Construct a GridSpatialIndex object from u, v, and w integer vectors and
            % their analogue x, y and z vectors and their segments.
            %
            % resolution ? 3-vector specifying grid size in the u, v and w
            % dimensions.
            
            if ~exist('grid', 'var')
                grid = geospm.Grid();
            end
            
            if ~exist('crs', 'var')
                crs = hdng.SpatialCRS.empty;
            end
            
            if ~isequal(cast(resolution, 'int64'), cast(resolution, 'double'))
                error('resolution must be specified as integer values.');
            end
            
            obj = obj@geospm.BaseSpatialIndex(N, crs);

            obj.resolution = resolution;
            obj.grid = grid;
        end
        
        function result = get.u(obj)
            result = obj.access_u();
        end

        function result = get.v(obj)
            result = obj.access_v();
        end

        function result = get.w(obj)
            result = obj.access_w();
        end

        function result = get.u_min(obj)
            result = obj.access_u_min();
        end
        
        function result = get.u_max(obj)
            result = obj.access_u_max();
        end
        
        function result = get.v_min(obj)
            result = obj.access_v_min();
        end
        
        function result = get.v_max(obj)
            result = obj.access_v_max();
        end
        
        function result = get.w_min(obj)
            result = obj.access_w_min();
        end
        
        function result = get.w_max(obj)
            result = obj.access_w_max();
        end
        
        function result = get.min_uv(obj)
            result = obj.access_min_uv();
        end
        
        function result = get.max_uv(obj)
            result = obj.access_max_uv();
        end
        
        function result = get.min_uvw(obj)
            result = obj.access_min_uvw();
        end
        
        function result = get.max_uvw(obj)
            result = obj.access_max_uvw();
        end
        
        function result = get.uvw(obj)
            result = obj.access_uvw();
        end
        
        function [u, v, w] = uvw_coordinates_for_segment(obj, segment_index) %#ok<STOUT,INUSD>
            error('xyz_coordinates_for_segment() must be implemented by a subclass.');
        end

    end
    
    methods (Access=protected)

        function result = access_u(obj) %#ok<STOUT,MANU>
            error('access_u() must be implemented by a subclass.');
        end

        function result = access_v(obj) %#ok<STOUT,MANU>
            error('access_v() must be implemented by a subclass.');
        end

        function result = access_w(obj) %#ok<STOUT,MANU>
            error('access_w() must be implemented by a subclass.');
        end

        function result = access_u_min(obj) %#ok<STOUT,MANU>
            error('access_u_min() must be implemented by a subclass.');
        end
        
        function result = access_u_max(obj) %#ok<STOUT,MANU>
            error('access_u_max() must be implemented by a subclass.');
        end
        
        function result = access_v_min(obj) %#ok<STOUT,MANU>
            error('access_v_min() must be implemented by a subclass.');
        end
        
        function result = access_v_max(obj) %#ok<STOUT,MANU>
            error('access_v_max() must be implemented by a subclass.');
        end
        
        function result = access_w_min(obj) %#ok<STOUT,MANU>
            error('access_w_min() must be implemented by a subclass.');
        end
        
        function result = access_w_max(obj) %#ok<STOUT,MANU>
            error('access_w_max() must be implemented by a subclass.');
        end
        
        function result = access_min_uv(obj) %#ok<STOUT,MANU>
            error('access_min_uv() must be implemented by a subclass.');
        end
        
        function result = access_max_uv(obj) %#ok<STOUT,MANU>
            error('access_max_uv() must be implemented by a subclass.');
        end
        
        function result = access_min_uvw(obj) %#ok<STOUT,MANU>
            error('access_min_uvw() must be implemented by a subclass.');
        end
        
        function result = access_max_uvw(obj) %#ok<STOUT,MANU>
            error('access_max_uvw() must be implemented by a subclass.');
        end
        
        function result = access_uvw(obj) %#ok<STOUT,MANU>
            error('access_uvw() must be implemented by a subclass.');
        end
        
        function assign_property(obj, name, values)
            obj.(name) = values;
        end

        function [specifier, modifier] = define_clone_specifier(obj)
            
            [specifier, modifier] = define_clone_specifier@geospm.BaseSpatialIndex(obj);

            specifier.resolution = obj.resolution;
            specifier.grid = obj.grid.as_json_struct();
        end

    end

    methods (Static)

    end
end
