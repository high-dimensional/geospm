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

classdef Point < hdng.geometry.Primitive
    %Point Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        x
        y
        z
        has_z
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = Point()
            obj = obj@hdng.geometry.Primitive();
        end
        
        function result = get.x(obj)
            result = obj.access_x();
        end
        
        function result = get.y(obj)
            result = obj.access_y();
        end
        
        function result = get.z(obj)
            result = obj.access_z();
        end
       
        function result = get.has_z(obj)
            result = obj.access_has_z();
        end
        
        function result = nth_point(obj, index)
            
            if index ~= 1
                error('nth_point(): index argument is out of bounds.');
            end
            
            result = obj;
        end
        
        function result = contains(obj, primitive) %#ok<INUSD>
            result = false;
        end
    end
    
    methods (Static)
        
        function result = select_handler_method(handler)
            result = @(primitive) handler.handle_points(primitive);
        end
        
        function result = define(x, y, z)
            
            if ~exist('z', 'var')
                result = hdng.geometry.impl.Point2Impl(x, y);
            else
                result = hdng.geometry.impl.Point3Impl(x, y, z);
            end
        end
        
        function result = define_collection(vertices)

            function point = generate_point(index, vertices, ~)
                point = vertices.nth_vertex_as_point(index);
            end
            
            result = hdng.geometry.Collection.define('hdng.geometry.Point', vertices.N_vertices, vertices, {}, @generate_point);
        end
    end
    
    methods (Access = protected)
        
        function result = access_N_points(~)
            result = 1;
        end
        
        function result = access_x(~) %#ok<STOUT>
            error('access_x() must be implemented by a subclass.');
        end
        
        function result = access_y(~) %#ok<STOUT>
            error('access_y() must be implemented by a subclass.');
        end
        
        function result = access_z(~) %#ok<STOUT>
            error('access_z() must be implemented by a subclass.');
        end
        
        function result = access_has_z(~) %#ok<STOUT>
            error('access_has_z() must be implemented by a subclass.');
        end
    end
    
end
