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

classdef PolygonImpl < hdng.geometry.Polygon
    %PolygonImpl Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
        vertices_
        ring_offsets_
        ring_base_
    end
    
    methods
        
        function obj = PolygonImpl(vertices, ring_offsets, ring_base)
            obj = obj@hdng.geometry.Polygon();
            obj.vertices_ = vertices;
            obj.ring_offsets_ = ring_offsets;
            obj.ring_base_ = ring_base;
        end
        
        function result = nth_ring(obj, index, as_polyline)
            
            if ~exist('as_polyline', 'var')
                as_polyline = false;
            end
            
            if index < 1 || index > obj.N_rings
                error('nth_ring(): index argument is out of bounds.');
            end
            
            N_vertices = obj.vertices.N_vertices;
            vertices_offset = obj.ring_offsets_.nth_stride(index) - obj.ring_base_;

            if index < obj.N_rings
                vertices_limit = obj.ring_offsets_.nth_stride(index + 1) - obj.ring_base_;
            else
                vertices_limit = N_vertices + 1;
            end
            
            ring_vertices = obj.vertices_.slice(vertices_offset, vertices_limit);
            
            if as_polyline
                result = hdng.geometry.Polyline.define(ring_vertices, true);
            else
                result = hdng.geometry.Polygon.define(ring_vertices, hdng.geometry.Buffer.define(zeros(1)));
            end
        end
        
        function result = collect_rings(obj, exclude_exterior, as_polylines)
            
            if ~exist('as_polylines', 'var')
                as_polylines = false;
            end
            
            if as_polylines
                
                if ~exclude_exterior
                    result = hdng.geometry.Polyline.define_collection(obj.vertices, obj.ring_offsets_, True, obj.ring_base_);
                else
                    
                    if obj.N_holes == 0
                        result = hdng.geometry.Collection.define(hdng.geometry.Polyline, 0, obj.vertices_, {}, @(index, vertices) []);
                    else
                        vertices_start = obj.ring_offsets_.nth_stride(2) - obj.ring_base_;
                        vertices_limit = obj.vertices_.N_vertices;
                        
                        ring_offsets = [];
                        ring_vertices = obj.vertices_.slice(vertices_start, vertices_limit);

                        result = hdng.geometry.Polyline.define_collection(ring_vertices, ring_offsets, True, obj.ring_base_);
                    end
                end
            else
                
                if ~exclude_exterior
                    polygon_offsets = 1:obj.N_rings;
                else
                    
                    polygon_offsets = 2:obj.N_rings;
                end
                
                polygon_offsets = hdng.geometry.Buffer.define(polygon_offsets');
                result = hdng.geometry.Polygon.define_collection(obj.vertices, obj.ring_offsets_, polygon_offsets, obj.ring_base_, 0);
            end
        end
        
        function result = substitute_vertices(obj, vertices)
            result = hdng.geometry.impl.PolygonImpl(vertices, obj.ring_offsets_, obj.ring_base_);
        end
        
    end
    
    methods (Access = protected)
        
        function result = access_element_type(~)
            result = 'hdng.geometry.Polygon';
        end
        
        function result = access_vertices(obj)
            result = obj.vertices_;
        end
        
        function result = access_N_points(obj)
            result = obj.vertices_.N_strides;
        end
        
        function result = access_N_rings(obj)
            result = obj.ring_offsets_.N_strides;
        end
    end
    
end
