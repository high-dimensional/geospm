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

classdef DynamicHandler < hdng.geometry.Handler
    %Handler Summary goes here.
    %
    
    properties
        points_callback
        polylines_callback
        polygons_callback
    end
    
    methods
        
        function obj = DynamicHandler()
            obj = obj@hdng.geometry.Handler();
        end
        
        function result = handle_points(~, points)
            result = [];
            
            if ~isempty(obj.points_callback)
                result = obj.points_callback(points);
            end
        end
        
        function result = handle_polylines(obj, polylines)
            result = [];
            
            if ~isempty(obj.polylines_callback)
                result = obj.polylines_callback(polylines);
            end
        end
        
        function result = handle_polygons(obj, polygons)
            result = [];
            
            if ~isempty(obj.polygons_callback)
                result = obj.polygons_callback(polygons);
            end
        end
    end
    
end
