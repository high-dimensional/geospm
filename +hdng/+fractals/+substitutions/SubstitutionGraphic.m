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

classdef SubstitutionGraphic < hdng.fractals.Graphic
    %Graphic Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        iterator
        capacity
        scale_base
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = SubstitutionGraphic(fractal, arguments, iterator, capacity)
            
            obj = obj@hdng.fractals.Graphic(fractal, arguments);
            
            obj.iterator = iterator;
            obj.capacity = capacity;
        end
        
        function [points, metadata] = to_polyline(obj)
            
            do_debug = false;
            
            metadata = struct();
            domain = obj.iterator.domain;
            points = zeros(obj.capacity + 1, 2);
            metadata.indicators = zeros(obj.capacity, 1);
            
            for i=2:obj.capacity + 1
                
                [is_valid, transform] = obj.iterator.next();
                
                if ~is_valid
                    points = points(1:i, :);
                    break;
                end
                
                if do_debug
                    fprintf('%03d: %s\n', i - 1, domain.transform_to_string(transform)); %#ok<UNRCH>
                end
                
                metadata.indicators(i - 1) = transform.reversed * 2 + transform.flipped;
                
                point = points(i - 1, :);
                
                [x, y] = domain.compute_step(point(1), point(2), transform);
                
                points(i,1) = x;
                points(i,2) = y;
            end
        end
        
        function [shape, metadata] = to_polyshape(obj)
            
            [points, metadata] = obj.to_polyline();
            shape = polyshape(points(:, 1), points(:, 2));
        end
        
        function render_in_figure(obj, origin, frame_size)
            
            [points, ~] = obj.to_polyline();
            
            points = points(1:end - 1, :);
            
            x = points(:, 1);
            y = points(:, 2);
            
            if ~exist('origin', 'var')
                origin = [min(x), min(y)];
            end
            
            if ~exist('frame_size', 'var')
                frame_size = [max(x), max(y)] - origin;
            end
            
            ratio = frame_size(2) / frame_size(1);
            
            pixel_size = 150;
            mark_size = 2;
            
            f = gcf;
            set(f, 'MenuBar', 'none', 'ToolBar', 'none');
            set(f, 'Units', 'points');
            set(f, 'Position', [100 100 pixel_size + mark_size pixel_size * ratio + mark_size]);
            
            ax = gca;
            
            hold on;
            
            
            %Plot background polygon
            
            X = [origin(1) origin(1) origin(1) + frame_size(1) origin(1) + frame_size(1)];
            Y = [origin(2) origin(2) + frame_size(2) origin(2) + frame_size(2) origin(2)];
            
            frame = polyshape(X, Y);
            plot(frame, 'FaceColor', 'white', 'FaceAlpha', 0.5, 'LineStyle', 'none');
            
            outline = polyshape(x, y, 'Simplify', false);
            plot(outline, 'FaceColor', 'white', 'EdgeColor', 'black');
            
            hold off;
            
            set(ax,'units','points');
            
            axis(ax, 'equal', 'manual', [origin(1), origin(1) + frame_size(1), origin(2), origin(2) + frame_size(2)]);
            set(ax,'color','none')
            set(ax,'visible','off');
            set(ax,'xtick',[], 'ytick', []);
            set(ax,'XColor', 'none','YColor','none');
            
            try
                set(ax,'PositionConstraint', 'innerposition');
            catch
            end
            
            margin = mark_size / 2;
            
            set(ax,'Position', [margin, margin, pixel_size, pixel_size * ratio]);
            set(f, 'PaperPositionMode', 'auto', 'PaperSize', [f.PaperPosition(3), f.PaperPosition(4)]);
            
        end
        
        function write_as_eps(obj, file_path, point1, point2)
            
            
            figure('Renderer', 'painters');
            ax = gca;
            
            if ~exist('point1', 'var') && ~exist('point2', 'var')
                obj.render_in_figure();
                
            elseif exist('point1', 'var') && exist('point2', 'var')
            
                [origin, frame_size] = obj.span_frame(point1, point2);
                obj.render_in_figure(origin, frame_size);
            end
            
            saveas(ax, file_path, 'epsc');
            
            close;
        end
        
        function [origin, frame_size] = span_frame(~, point1, point2)
            
            min_point = [min(point1(1), point2(1)), min(point1(2), point2(2))];
            max_point = [max(point1(1), point2(1)), max(point1(2), point2(2))];
            
            origin = min_point;
            frame_size = max_point - min_point;
        end
    end
end
