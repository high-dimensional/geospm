% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2019,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef Graphic < matlab.mixin.Copyable
    %Graphic Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fractal
        arguments
    end
    
    methods
        
        function obj = Graphic(fractal, arguments)
            obj.fractal = fractal;
            obj.arguments = arguments;
        end
        
        function [points, metadata] = to_polyline(obj) %#ok<MANU>
            points = zeros(1, 2);
            metadata = struct();
        end
        
        function draw(obj, raster_context, fill, x, y, width, height, points, min_point, max_point)
            
            if ~exist('points', 'var')
                [points, ~] = obj.to_polyline();
            end
            
            if ~exist('points', 'var') || ~exist('min_point', 'var') || ~exist('max_point', 'var')
                min_point = [];
                max_point = [];

                min_point(1) = min(points(:,1));
                min_point(2) = min(points(:,2));
                max_point(1) = max(points(:,1));
                max_point(2) = max(points(:,2));
            end
            
            size = max_point - min_point;
            
            s = [width / size(1), height / size(2)];
            s = min(s);
            d = - 0.5 * s * size - s * min_point;
            
            raster_context.translate(x + d(1), y + d(2));
            raster_context.scale(s, s);
            
            raster_context.set_fill(fill);
            raster_context.fill_polygon(points(:,1), points(:,2));
        end
        
        function show_impl(obj, points, metadata) %#ok<INUSD>
            
            axis('equal');
            set(gca,'Color','k'); 
            title(obj.fractal.name);
            
            line(points(:,1), points(:,2), 'Color', 'white', 'LineWidth', 3);
        end
        
        function show(obj)
            [points, ~] = obj.to_polyline();
            
            points = points .* 3;
            
            margin = 20;
            
            x_min = min(points(:,1));
            y_min = min(points(:,2));
            x_max = max(points(:,1));
            y_max = max(points(:,2));
            
            width = int32(ceil(x_max - x_min + 1) + 2 * margin);
            height = int32(ceil(y_max - y_min + 1) + 2 * margin);
            
            points(:,1) = points(:,1) - x_min + margin;
            points(:,2) = points(:,2) - y_min + margin;
            
            raster_context = hdng.rasters.RasterContext([width, height, 3]);
            raster_context.set_fill([255 230 20], NaN(1, 3));
            raster_context.fill_polygon(points(:,1), points(:,2));
            imshow(raster_context.canvas);
        end
    end
end
