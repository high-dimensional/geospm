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

classdef Point3Impl < hdng.geometry.Point
    %Point Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
        x_
        y_
        z_
    end
    
    methods
        
        function obj = Point3Impl(x, y, z)
            obj = obj@hdng.geometry.Point();
            obj.x_ = x;
            obj.y_ = y;
            obj.z_ = z;
        end
        
        function result = substitute_vertices(~, vertices)
            coords = vertices.coordinates;
            result = hdng.geometry.impl.Point3Impl(coords(1, 1), coords(1, 2), coords(1, 3));
        end
        
    end
    
    methods (Access = protected)
        
        function result = access_element_type(~)
            result = 'hdng.geometry.Point';
        end
        
        function result = access_x(obj)
            result = obj.x_;
        end
        
        function result = access_y(obj)
            result = obj.y_;
        end
        
        function result = access_z(obj)
            result = obj.z_;
        end
        
        function result = access_has_z(~)
            result = True;
        end
        
        function result = access_vertices(obj)
            result = hdng.geometry.Vertices.define([obj.x, obj.y, obj.z]);
        end
    end
    
end
