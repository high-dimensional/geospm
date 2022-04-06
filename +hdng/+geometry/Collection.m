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

classdef Collection < handle
    %Collection Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        element_type
        N_elements
        vertices
        buffers
        generator
    end
    
    methods
        
        function obj = Collection()
        end
        
        function result = get.element_type(obj)
            result = obj.access_element_type();
        end
        
        function result = get.N_elements(obj)
            result = obj.access_N_elements();
        end
        
        function result = get.vertices(obj)
            result = obj.access_vertices();
        end
        
        function result = get.buffers(obj)
            result = obj.access_buffers();
        end
        
        function result = get.generator(obj)
            result = obj.access_generator();
        end
        
        function result = nth_element(obj, index)
            
            if index < 1 || index > obj.N_elements
                error('nth_element(): index argument is out of bounds.');
            end
            
            result = obj.generator(index, obj.vertices, obj.buffers{:});
        end
        
        function handle_with(obj, handler)
            ET = obj.element_type;
            m = str2func([ET '.select_handler_method']);
            m = m(handler);
            m(obj);
        end
        
        function result = premultiply_xy(obj, matrix23, first, last)
            
            if ~exist('first', 'var')
                first = 1;
            end
            
            if ~exist('last', 'var')
                last = obj.vertices.N_vertices;
            end
            
            transformed_vertices = obj.vertices.premultiply_xy(matrix23, first, last);
            result = obj.substitute_vertices(transformed_vertices);
        end
        
        function result = substitute_vertices(obj, vertices) %#ok<STOUT,INUSD>
            error('substitute_vertices() must be implemented by a subclass.');
        end
        
        
        function result = as_shapevector(obj)
            
            if obj.vertices.has_z
                error('as_shapevector(): Z coordinates not yet supported.');
            end
            
            if strcmpi(obj.element_type, 'hdng.geometry.Point')
                result = obj.build_point_geostruct();
            elseif strcmpi(obj.element_type, 'hdng.geometry.Polyline')
                result = obj.build_polyline_geostruct();
            elseif strcmpi(obj.element_type, 'hdng.geometry.Polygon')
                result = obj.build_polygon_geostruct();
            else
                error(['as_shapevector(): Unsupported element_type ''' obj.element_type '''.']);
            end
        end
    end
    
    
    methods (Static)
        
        function result = define(element_type, N_elements, vertices, buffers, generator)
            result = hdng.geometry.impl.CollectionImpl(element_type, N_elements, vertices, buffers, generator);
        end
        
        function result = from_file(file_path)
            [~, ~, ext] = fileparts(file_path);
            
            if strcmpi(ext, '.shp')
                result = hdng.geometry.Collection.from_shapefile(file_path);
            elseif strcmpi(ext, '.wkt')
                result = hdng.geometry.Collection.from_wkt(file_path);
            elseif strcmpi(ext, '.csv')
                result = hdng.geometry.Collection.from_csv(file_path);
            else
                error(['from_file(): Unrecognized collection geometry file format: ''' file_path '''']);
            end
            
        end
        
        function result = from_shapefile(file_path)
                shapes = shaperead(file_path);
                result = hdng.geometry.Collection.from_shapes(shapes);
        end
        
        function result = from_shapes(shapevector)
            result = hdng.geometry.impl.collection_from_shapes(shapevector);
        end
        
        function result = from_bounding_box_csv(file_path)
            result = hdng.geometry.impl.collection_from_bounding_box_csv(file_path);
        end
        
        function [result, additional_attributes] = from_csv(file_path, varargin)
            [result, additional_attributes] = ...
                hdng.geometry.impl.collection_from_csv(file_path, varargin{:});
        end
        
        function result = from_wkt(file_path)
            result = hdng.geometry.impl.collection_from_wkt(file_path);
        end
    end
    
    methods (Access = protected)
        
        
        function result = build_point_geostruct(obj)
            
            result = struct();
            result.Geometry = 'Point';
            result.Lat = 0;
            result.Lon = 0;
            
            coords = obj.vertices.coordinates;
            
            for i=1:obj.N_elements
                result(i).Geometry = 'Point';
                result(i).Lat = coords(i, 2);
                result(i).Lon = coords(i, 1);
            end
        end
        
        function result = build_polyline_geostruct(obj)
            
            result = struct();
            result.Geometry = 'Line';
            result.X = 0;
            result.Y = 0;
            
            coords = obj.vertices.coordinates;
            index = 1;
            
            for i=1:obj.N_elements
                
                polyline = obj.nth_element(i);
                range = index:index + polyline.N_points - 1;
                index = index + polyline.N_points;
                
                result(i).Geometry = 'Line';
                result(i).X = coords(range, 1);
                result(i).Y = coords(range, 2);
            end
        end
        
        function result = build_polygon_geostruct(obj)
            result = struct();
            result.Geometry = 'Polygon';
            result.X = 0;
            result.Y = 0;
            
            coords = obj.vertices.coordinates;
            index = 1;
            
            for i=1:obj.N_elements
                
                polygon = obj.nth_element(i);
                
                assembled_coords = zeros(polygon.N_points + polygon.N_rings, 2);
                assembled_index = 1;
                
                for j=1:polygon.N_rings

                    ring = polygon.nth_ring(j, true);
                    
                    range = [index, index + ring.N_points - 1];
                    index = index + ring.N_points;
                    
                    ring_coords = coords(range(1):range(2), 1:2);
                    
                    if j == 1
                        if ~obj.vertices.is_clockwise_xy(range(1), range(2))
                            ring_coords = flip(ring_coords, 1);
                        end
                    else
                        if obj.vertices.is_clockwise_xy(range(1), range(2))
                            ring_coords = flip(ring_coords, 1);
                        end
                    end
                    
                    assembled_coords(assembled_index:assembled_index + ring.N_points - 1, 1:2) = ring_coords;
                    assembled_index = assembled_index + ring.N_points;
                    
                    assembled_coords(assembled_index, 1:2) = [NaN, NaN];
                    assembled_index = assembled_index + 1;
                end
                
                assembled_coords = assembled_coords(1:assembled_index - 2, :);
                
                result(i).Geometry = 'Polygon';
                result(i).X = assembled_coords(:, 1);
                result(i).Y = assembled_coords(:, 2);
            end
            
        end
        
        function result = access_element_type(~) %#ok<STOUT>
            error('access_element_type() must be implemented by a subclass.');
        end
        
        function result = access_N_elements(~) %#ok<STOUT>
            error('access_N_elements() must be implemented by a subclass.');
        end
        
        function result = access_vertices(~) %#ok<STOUT>
            error('access_vertices() must be implemented by a subclass.');
        end
        
        function result = access_buffers(~) %#ok<STOUT>
            error('access_buffers() must be implemented by a subclass.');
        end
        
        function result = access_generator(~) %#ok<STOUT>
            error('access_generator() must be implemented by a subclass.');
        end
        
    end
    
end
