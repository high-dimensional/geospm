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

classdef Point2Impl < hdng.geometry.Point
    %Point2Impl Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
        x_
        y_
    end
    
    methods
        
        function obj = Point2Impl(x, y)
            obj = obj@hdng.geometry.Point();
            obj.x_ = x;
            obj.y_ = y;
        end
        
        function result = substitute_vertices(~, vertices)
            coords = vertices.coordinates;
            result = hdng.geometry.impl.Point2Impl(coords(1, 1), coords(1, 2));
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
        
        function result = access_z(~)
            result = [];
        end
        
        function result = access_has_z(~)
            result = false;
        end
        
        function result = access_vertices(obj)
            result = hdng.geometry.Vertices.define([obj.x, obj.y]);
        end
        
    end
    
end
