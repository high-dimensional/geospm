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

classdef Fractal < geospm.models.Region
    %Fractal Summary
    %   Detailed explanation goes here
    
    properties
    end
    
    properties (SetAccess=private)
        fill
        x
        y
        width
        height
    end
    
    properties (GetAccess=private, SetAccess=private)
        graphic
        points
        min_point
        max_point
        size
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Fractal(map, name, arguments, fill, x, y, width, height)
            obj = obj@geospm.models.Region(map, fill, x, y, width, height);
            
            obj.graphic = [];
            obj.points = [];
            obj.min_point = [];
            obj.max_point = [];
            obj.size = [];
            
            [~, fractal] = hdng.fractals.Fractal.for_name(name);
            
            if ~isempty(fractal)
                obj.graphic = fractal.generate(arguments);
                obj.points = obj.graphic.to_polyline();
                obj.min_point(1) = min(obj.points(:,1));
                obj.min_point(2) = min(obj.points(:,2));
                obj.max_point(1) = max(obj.points(:,1));
                obj.max_point(2) = max(obj.points(:,2));
                obj.size = obj.max_point - obj.min_point;
                
                %fprintf('geospm.models.regions.Fractal.ctor(): Computed #%d points for fractal %s.\n', numel(obj.points(:, 1)), name);
            else
                
                %fprintf('geospm.models.regions.Fractal.ctor(): Couldn''t find fractal %s.\n', name);
                
                error('geospm.models.regions.Fractal.ctor(): Unknown fractal \"%s\".\n', name);
            end
            
            obj.fill = fill;
            obj.x = x;
            obj.y = y;
            obj.width = width;
            obj.height = height;
        end
        
        function render_impl(obj, ~, raster_context, fill, x, y, width, height)
            
            if isempty(obj.points)
                %fprintf('geospm.models.regions.Fractal.render_impl(): No points, exiting.\n');
                return;
            end
            
            %fprintf('geospm.models.regions.Fractal.render_impl(): Rendering #%d points...\n', numel(obj.points(:,1)));
            
            width = width + width;
            height = height + height;
            
            fudge = 1.15;
            
            width = fudge * width;
            height = fudge * height;
            
            s = [width / obj.size(1), height / obj.size(2)];
            s = min(s);
            d = - 0.5 * s * obj.size - s * obj.min_point;
            
            raster_context.translate(x + d(1), y + d(2));
            raster_context.scale(s, s);
            
            raster_context.set_fill(fill);
            
            raster_context.fill_polygon(obj.points(:,1), obj.points(:,2));
        end
    end
    
    methods (Static, Access=private)
    end
    
end
