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

classdef Polygon < hdng.geometry.Surface
    %Polygon Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        N_rings
        N_holes
        exterior
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = Polygon()
            obj = obj@hdng.geometry.Surface();
        end
        
        function result = get.N_rings(obj)
            result = obj.access_N_rings();
        end
        
        function result = get.N_holes(obj)
            result = obj.access_N_holes();
        end
        
        function result = get.exterior(obj)
            result = obj.access_exterior();
        end
        
        function result = contains(obj, primitive)
            
            result = false;
            
            if obj.N_rings == 0
                return
            end
            
            for i=1:primitive.N_points
                point = primitive.nth_point(i);
                vertices = obj.nth_ring(1, false).vertices;
                
                if ~vertices.contains(point.x, point.y, 1, vertices.N_vertices)
                    return
                end
                
                for j=1:obj.N_holes

                    vertices = obj.nth_ring(1 + j, false).vertices;

                    if vertices.contains(point.x, point.y, 1, vertices.N_vertices)
                        return
                    end
                end
            end
            
            result = true;
        end
        
        function result = nth_ring(obj, index, as_polyline) %#ok<STOUT,INUSD>
            error('nth_ring() must be implemented by a subclass.');
        end
        
        function result = nth_hole(obj, index, as_polyline)
            
            if ~exist('as_polyline', 'var')
                as_polyline = false;
            end
            
            if index < 1 || index > obj.N_holes
                error('nth_hole(): index argument is out of bounds.');
            end
            
            result = obj.nth_ring(index + 1, as_polyline);
        end
        
        function result = collect_rings(obj, exclude_exterior, as_polylines) %#ok<INUSD,STOUT>
            error('collect_rings() must be implemented by a subclass.');
        end
        
        function result = collect_holes(obj, as_polylines)
            
            if ~exist('as_polylines', 'var')
                as_polylines = false;
            end
            
            result = obj.collect_rings(false, true, as_polylines);
        end

        function result = collect_nan_delimited_ring_vertices(obj)
            
            result = NaN([obj.vertices.N_vertices + obj.N_rings - 1, 2]);
            offset = 0;

            for i=1:obj.N_rings
                ring = obj.nth_ring(i);
                result(offset + 1:offset + ring.vertices.N_vertices, :) = ...
                    ring.vertices.coordinates(:, 1:2);

                offset = offset + ring.vertices.N_vertices + 1;
            end
        end
        
    end
    
    methods (Static)
        
        function result = select_handler_method(handler)
            result = @(primitive) handler.handle_polygons(primitive);
        end
        
        function result = define(vertices, ring_offsets, ring_base)
            
            if ~exist('ring_base', 'var')
                ring_base = 0;
            end
            
            if isnumeric(vertices)
                vertices = hdng.geometry.Vertices.define(vertices);
            end
            
            if isnumeric(ring_offsets)
                ring_offsets = hdng.geometry.Buffer.define(ring_offsets);
            end
            
            result = hdng.geometry.impl.PolygonImpl(vertices, ring_offsets, ring_base);
        end
        
        function result = define_collection(vertices, ring_offsets, polygon_offsets, ring_base, polygon_base)
            
            if ~exist('ring_base', 'var')
                ring_base = 0;
            end
            
            if ~exist('polygon_base', 'var')
                polygon_base = 0;
            end
            
            if isnumeric(vertices)
                vertices = hdng.geometry.Vertices.define(vertices);
            end
            
            if isnumeric(ring_offsets)
                ring_offsets = hdng.geometry.Buffer.define(ring_offsets);
            end
            
            if isnumeric(polygon_offsets)
                polygon_offsets = hdng.geometry.Buffer.define(polygon_offsets);
            end

            function polygon = generate_polygon(index, vertices, ring_offsets, polygon_offsets, ring_base, polygon_base)

                N_vertices = vertices.N_vertices;
                N_rings = ring_offsets.N_strides;
                N_polygons = polygon_offsets.N_strides;

                rings_offset = polygon_offsets.nth_stride(index) - polygon_base;
                vertices_offset = ring_offsets.nth_stride(rings_offset) - ring_base;

                if index < N_polygons
                    rings_limit = polygon_offsets.nth_stride(index + 1) - polygon_base;
                    vertices_limit = ring_offsets.nth_stride(rings_limit) - ring_base;
                else
                    rings_limit = N_rings + 1;
                    vertices_limit = N_vertices + 1;
                end
                
                polygon_rings = ring_offsets.slice(rings_offset, rings_limit);
                polygon_vertices = vertices.slice(vertices_offset, vertices_limit);

                polygon = hdng.geometry.Polygon.define(polygon_vertices, polygon_rings, ring_base + vertices_offset - 1);
            end
            
            result = hdng.geometry.Collection.define('hdng.geometry.Polygon', polygon_offsets.N_strides, vertices, {ring_offsets, polygon_offsets, ring_base, polygon_base}, @generate_polygon);
        end
        
        function result = span_frame(point1, point2)
            
            min_point = [min(point1(1), point2(1)), min(point1(2), point2(2))];
            max_point = [max(point1(1), point2(1)), max(point1(2), point2(2))];
            
            coords = [min_point;
                      max_point(1), min_point(2);
                      max_point;
                      min_point(1), max_point(2)];
            
            vertices = hdng.geometry.Vertices.define(coords, 1);
            ring_offsets = hdng.geometry.Buffer.define(1, 1);
            
            result = hdng.geometry.impl.PolygonImpl(vertices, ring_offsets, 0);
        end
    end
    
    methods (Access = protected)
        
        function result = access_N_rings(~) %#ok<STOUT>
            error('access_N_rings() must be implemented by a subclass.');
        end
        
        function result = access_N_holes(obj)
            result = obj.N_rings;
            
            if result == 0
                return;
            end
            
            result = result - 1;
        end
        
        function result = access_exterior(obj)
            result = obj.nth_ring(1);
        end
    end
    
end
