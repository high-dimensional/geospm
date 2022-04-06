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

classdef PolylineImpl < hdng.geometry.Polyline
    %Polyline Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
        vertices_
        is_simple_
    end
    
    methods
        
        function obj = PolylineImpl(vertices, is_simple)
            obj = obj@hdng.geometry.Polyline();
            obj.vertices_ = vertices;
            obj.is_simple_ = is_simple;
        end
        
        function result = as_point_collection(~) %#ok<STOUT>
            error('as_point_collection() must be implemented by a subclass.');
        end
        
        function result = substitute_vertices(obj, vertices)
            result = hdng.geometry.impl.PolylineImpl(vertices, obj.is_simple_);
        end
        
    end
    
    methods (Access = protected)
        
        function result = access_element_type(~)
            result = 'hdng.geometry.Polyline';
        end
        
        function result = access_vertices(obj)
            result = obj.vertices_;
        end
        
        function result = access_buffers(obj)
            result = {obj.is_simple_};
        end
        
        function result = access_N_points(obj)
            result = obj.vertices.N_strides;
        end
        
        function result = access_start_point(obj)
            result = obj.vertices.nth_vertex_as_point(1);
        end
        
        function result = access_end_point(obj)
            result = obj.vertices.nth_vertex_as_point(obj.vertices.N_vertices);
        end
        
        function result = access_is_simple(obj)
            result = obj.is_simple_;
        end
        
    end
    
end
