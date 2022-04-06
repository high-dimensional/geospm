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

classdef ShapeStyle
    %ShapeStyle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fill_1_value
        fill_2_value
        
        line_width
        line_value
    end
    
    methods
        
        function obj = ShapeStyle(settings) %fill_1_value, fill_2_value, line_width, line_value)
            
            if ~exist('settings', 'var')
                settings = struct();
            end
            
            if ~isfield(settings, 'fill_1_value')
                settings.fill_1_value = 1.0;
            end
            
            if ~isfield(settings, 'fill_2_value')
                settings.fill_2_value = NaN;
            end
            
            if ~isfield(settings, 'line_width')
                settings.line_width = 0.0;
            end
            
            if ~isfield(settings, 'line_value')
                settings.line_value = NaN;
            end
            
            obj.fill_1_value = settings.fill_1_value;
            obj.fill_2_value = settings.fill_2_value;

            obj.line_width = settings.line_width;
            obj.line_value = settings.line_value;
        end
        
        
        function apply(obj, raster_context)
            
            raster_context.set_fill(obj.fill_1_value, obj.fill_2_value);
            raster_context.set_stroke(obj.line_width, obj.line_value);
            
        end
        
        function draw_polygon(obj, raster_context, xi, yi)
            
            obj.apply(raster_context);
            raster_context.fill_polygon(xi, yi);
        end
        
        function draw_rect(obj, raster_context, x, y, width, height)
            
            obj.apply(raster_context);
            raster_context.fill_rect(x, y, width, height);
            
            if obj.line_width ~= 0
                raster_context.stroke_rect(x, y, width, height);
            end
        end
        
        function draw_ellipse(obj, raster_context, x, y, radiusX, radiusY)
            
            obj.apply(raster_context);
            raster_context.fill_ellipse(x, y, radiusX, radiusY);
            
            if obj.line_width ~= 0
                raster_context.stroke_ellipse(x, y, radiusX, radiusY);
            end
        end
    end
    
    
end
