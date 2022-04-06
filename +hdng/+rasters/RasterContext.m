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

classdef RasterContext < handle
    %RasterContext Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        canvas
    end
    
    properties (Transient, Dependent)
        
        transform
        mask
        fill_1
        fill_2
        
        line_width
        line_stroke
        
        dimensions
        width
        height
        
    end
    
    properties (SetAccess=private)
    end
    
    properties (GetAccess=private, SetAccess=private)
        states
        blank_mask
        channels
    end
    
    
    properties (Transient, Dependent, GetAccess=private)
        mask_level
        current_scale
        current_offset
        mask_fill_1
        mask_fill_2
    end
    
    
    methods
        
        function obj = RasterContext(dimensions)
            
            obj.canvas = zeros(dimensions);
            obj.blank_mask = zeros(dimensions(1), dimensions(2), 'logical');
            obj.channels = size(obj.canvas, 3);
            
            obj.states = cell(1, 1);
            obj.states{1} = hdng.rasters.RasterState(obj.blank_mask, obj.channels);
        end
        
        function result = get.transform(obj)
            result = obj.states{end}.transform;
        end
        
        function result = get.mask(obj)
            result = obj.states{end}.mask;
        end
        
        function set.mask(obj, value)
            obj.states{end}.mask = value;
        end
        
        function result = get.fill_1(obj)
            result = obj.states{end}.fill_1;
        end
        
        function result = get.fill_2(obj)
            result = obj.states{end}.fill_2;
        end
        
        function result = get.line_width(obj)
            result = obj.states{end}.line_width;
        end
        
        function result = get.line_stroke(obj)
            result = obj.states{end}.line_stroke;
        end
        
        function result = get.dimensions(obj)
            result = size(obj.canvas);
        end
        
        function result = get.width(obj)
            result = obj.dimensions(1);
        end
        
        function result = get.height(obj)
            result = obj.dimensions(2);
        end
        
        function result = get.mask_level(obj)
            result = obj.states{end}.mask_level;
        end
        
        function result = get.mask_fill_1(obj)
            result = obj.states{end}.mask_fill_1;
        end
        
        function result = get.mask_fill_2(obj)
            result = obj.states{end}.mask_fill_2;
        end
        
        function result = get.current_scale(obj)
            t = obj.transform;
            result = [t(1,1), t(2,2)];
        end
        
        function result = get.current_offset(obj)
            t = obj.transform;
            result = [t(1,3), t(2,3)];
        end
        
        function save(obj)
            obj.states{end + 1} = obj.states{end}.copy();
        end
        
        function restore(obj)
            obj.states = obj.states(1:end - 1);
        end
        
        function clear_mask(obj)
            obj.states{end}.mask = obj.blank_mask;
        end
        
        function begin_mask(obj)
            obj.states{end}.mask_level = obj.states{end}.mask_level + 1;
        end
        
        function end_mask(obj)
            obj.states{end}.mask_level = obj.mask_level - 1;
        end
        
        function set_fill(obj, fill_1, fill_2)
            
            if ~exist('fill_2', 'var')
                fill_2 = hdng.rasters.NoEffect();
            end
            
            if isnumeric(fill_1)
                fill_1 = hdng.rasters.ConstantEffect(fill_1);
            end
            
            if isnumeric(fill_2)
                fill_2 = hdng.rasters.ConstantEffect(fill_2);
            end
            
            if obj.mask_level == 0
                obj.states{end}.fill_1 = fill_1;
                obj.states{end}.fill_2 = fill_2;
            else
                obj.states{end}.mask_fill_1 = fill_1;
                obj.states{end}.mask_fill_2 = fill_2;
            end
            
        end
        
        function set_stroke(obj, line_width, line_stroke)
            
            if isnumeric(line_stroke)
                line_stroke = hdng.rasters.ConstantEffect(line_stroke);
            end
            
            obj.states{end}.line_width = line_width;
            obj.states{end}.line_stroke = line_stroke;
        end
        
        function translate(obj, dx, dy)
            t = obj.transform;
            
            d = eye(3);
            d(1,3) = dx;
            d(2,3) = dy;
            
            obj.states{end}.transform = t * d;
        end
        
        function scale(obj, sx, sy)
            t = obj.transform;
            
            d = eye(3);
            d(1,1) = sx;
            d(2,2) = sy;
            
            obj.states{end}.transform = t * d;
        end
        
        function rotate(obj, radians)
            t = obj.transform;
            
            r = eye(3);
            r(1,1) = cos(radians);
            r(2,1) = sin(radians);
            r(1,2) = -r(2,1);
            r(2,2) =  r(1,1);
            
            obj.states{end}.transform = t * r;
        end
        
        function apply_transform(obj, matrix23)
            
            t = obj.transform;
            obj.states{end}.transform = t * [matrix23; 0 0 1];
        end
        
        function fill_rect(obj, x, y, width, height)
            
            [xi, yi] = obj.transform_points([x; x + width; x + width; x], ...
                                           [y; y; y + height; y + height]);
                                       
            obj.render_polygon(xi, yi);
        end
        
        function fill_ellipse(obj, x, y, radiusX, radiusY)
            
            renderSize = max(obj.current_scale .* [radiusX radiusY]);
            N_sides = ceil(renderSize) * 4;
            
            [xi, yi] = hdng.rasters.regular_polygon(N_sides);
            
            xi = xi * radiusX + x;
            yi = yi * radiusY + y;
            
            [xi, yi] = obj.transform_points(xi, yi);
            obj.render_polygon(xi, yi);
        end
        
        function fill_polygon(obj, xi, yi)
            
            [xi, yi] = obj.transform_points(xi, yi);
            obj.render_polygon(xi, yi);
        end
        
        function stroke_rect(obj, x, y, width, height)
            
            obj.save();
            
            obj.clear_mask();
            obj.begin_mask();
            
            obj.set_fill(1);
            obj.fill_rect(x, y, width - obj.line_width, height - obj.line_width);
            
            obj.end_mask();
            
            obj.set_fill(obj.line_stroke);
            obj.fill_rect(x, y, width, height);
            
            obj.restore();
        end
        
        function stroke_ellipse(obj, x, y, radiusX, radiusY)
            
            obj.save();
            
            obj.clear_mask();
            obj.begin_mask();
            
            obj.set_fill(1);
            obj.fill_ellipse(x, y, radiusX - obj.line_width, radiusY - obj.line_width);
            
            obj.end_mask();
            
            obj.set_fill(obj.line_stroke);
            obj.fill_ellipse(x, y, radiusX, radiusY);
            
            obj.restore();
        end
        
        function result = canvas_as_image(obj)
            
            result = rot90(obj.canvas);
        end
        
        function save_canvas_as_png(obj, filepath, description, channel_selector, is_standardised)
        
            if ~exist('description', 'var') || isempty(description)
                description = datestr(datetime('now'));
            end
            
            if ~exist('channel_selector', 'var')
                channel_selector = ones(1, obj.channels, 'logical');
            end
            
            if ~exist('is_standardised', 'var')
                is_standardised = false;
            end
            
            if numel(channel_selector) ~= obj.channels
                error('RasterContext.save_canvas_as_png(): Channel selector must have as many elements as there are channels.');
            end
            
            channel_selector = cast(channel_selector, 'logical');
            
            I = obj.canvas;
            I = I(:,:,channel_selector);
            C = sum(channel_selector(:));
            image_data = reshape(I, [obj.width, obj.height, 1, C]);
            
            if is_standardised
                image_data = image_data * 255;
            end
            
            channel = [];
            
            if C == 1
                channel = 1;
            end
            
            image_data = uint8(image_data);
            
            image = hdng.images.ImageVolume(image_data, description, filepath);
            image.save_as_png(8, channel);
        end
        
        
        function save_mask_as_png(obj, filepath, description)
        
            if ~exist('description', 'var')
                description = datestr(datetime('now'));
            end
            
            if ~exist('description', 'var')
                description = '';
            end
            
            I = double(obj.mask);
            image_data = reshape(I, [obj.width, obj.height, 1, 1]);
            
            image = hdng.images.ImageVolume(image_data, description, filepath);
            image.save_as_png(8, 1);
        end
    end
    
    methods (Access=private)
        
        function [x_result, y_result] = transform_points(obj, xi, yi)
            
            t = obj.transform;
            
            x_result = xi * t(1,1) + yi * t(1, 2) + t(1, 3);
            y_result = xi * t(2,1) + yi * t(2, 2) + t(2, 3);
        end
        
        function render_polygon(obj, xi, yi)
            
            d = obj.dimensions;
            result = poly2mask(yi, xi, d(1), d(2));
            
            if obj.mask_level == 0
                
                if obj.fill_1.do_apply
                    selector = result == 1 & ~obj.mask;
                    obj.canvas = obj.fill_1.apply(obj.canvas, obj.channels, selector);
                end

                if obj.fill_2.do_apply
                    selector = result == 0 & ~obj.mask;
                    obj.canvas = obj.fill_2.apply(obj.canvas, obj.channels, selector);
                end
            else
                
                if obj.mask_fill_1.do_apply
                    selector = result == 1;
                    obj.mask = obj.mask_fill_1.apply(obj.mask, 1, selector);
                end

                if obj.mask_fill_2.do_apply
                    selector = result == 0;
                    obj.mask = obj.mask_fill_2.apply(obj.mask, 1, selector);
                end
            end
        end
    end
    
    methods (Static, Access=private)
    end
    
end
