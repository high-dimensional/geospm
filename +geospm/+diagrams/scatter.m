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

function result = scatter(x, y, origin, frame_size, varargin)
    
    result = struct();
    result.corrective_scale_factor = 1.0;

    if ~exist('origin', 'var') || isempty(origin)
        origin = [min(x), min(y)];
    end
    
    if ~exist('frame_size', 'var') || isempty(frame_size)
        frame_size = [max(x), max(y)] - origin;
    end
    
    options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    if ~isfield(options, 'no_background')
        options.no_background = false;
    end

    if ~isfield(options, 'marker_sizes')
        options.marker_sizes = 2;
    end

    if ~isfield(options, 'marker_scale')
        options.marker_scale = 1;
    end

    if ~isfield(options, 'marker_symbol')
        options.marker_symbol = '+';
    end
    
    if ~isfield(options, 'is_marker_filled')
        options.is_marker_filled = false;  
    end
    
    if ~isfield(options, 'max_pixel_size')
        options.max_pixel_size = 150;
    end
    
    if ~isfield(options, 'line_width')
        options.line_width = 0.5;
    end
    
    N = size(x, 1);
    
    if N ~= size(y, 1)
        error('geospm.diagrams.scatter(): X and Y size do not match.');
    end
    
    %if N ~= size(categories, 1)
    %    error('geospm.diagrams.scatter(): X and categories size do not match.');
    %end

    if ~isscalar(options.marker_sizes) && N ~= size(options.marker_sizes, 1)
        error('geospm.diagrams.scatter(): X and marker_sizes size do not match.');
    end
    
    diagram_size = options.max_pixel_size * (frame_size ./ max(frame_size));
    cell_size = options.marker_scale * options.max_pixel_size / max(frame_size);

    f = gcf;
    ax = gca;


    set(f, 'MenuBar', 'none', 'ToolBar', 'none');
    set(f, 'Units', 'points');
    set(f, 'PaperUnits', 'points');

    set(ax, 'Units','points');
    

    try
        set(ax,'PositionConstraint', 'innerposition');
    catch
    end
    
    set(ax, 'Position', [0 0 diagram_size]);

    set(ax,'DataAspectRatio', [1, 1, 1]);
    axis(ax, 'equal', 'manual', [origin(1), origin(1) + frame_size(1), ...
                                 origin(2), origin(2) + frame_size(2)]);
    
    set(ax,'color','none');
    set(ax,'visible','off');
    set(ax,'xtick',[], 'ytick', []);
    set(ax,'XColor', 'none','YColor','none');

    hold on;
    
    if ~options.no_background
    
        %Plot background polygon

        X = [origin(1) origin(1) origin(1) + frame_size(1) origin(1) + frame_size(1)];
        Y = [origin(2) origin(2) + frame_size(2) origin(2) + frame_size(2) origin(2)];
        
        frame = polyshape(X, Y);
        plot(frame, 'FaceColor', 'white', 'FaceAlpha', 1, 'LineStyle', 'none');
    
    end
    
    dpi = groot().ScreenPixelsPerInch;
    scale_factor = 72 / dpi;

    %Plot markers
    
    scatter_options = struct();
    scatter_options.Marker = options.marker_symbol;
    scatter_options.LineWidth = options.line_width * scale_factor;
    
    if options.is_marker_filled
        scatter_options.MarkerEdgeColor = 'none';
    else
        scatter_options.MarkerEdgeColor = 'black';
        scatter_options.MarkerFaceColor = 'none';
    end
    
    arguments = hdng.utilities.struct_to_name_value_sequence(scatter_options);

    if options.is_marker_filled
        arguments = ['filled', arguments];
    end
    
    cell_size = cell_size - scatter_options.LineWidth;

    props = scatter(x, y, arguments{:});
    props.SizeData = options.marker_sizes * cell_size * cell_size * scale_factor;
    
    %marker_colours = define_colours(N, categories);
    %props.CData = marker_colours;
    
    
    hold off;
    
    %margin = mark_size / 2;
    %set(ax,'Position', [margin, margin, pixel_size, pixel_size * ratio]);
    %set(f, 'PaperPositionMode', 'auto', 'PaperSize', [f.PaperPosition(3), f.PaperPosition(4)]);
    
    set(f, 'Position', [0, 0, diagram_size]);
    
    %If we don't pause here the window might not yet have been displayed by
    %the time we check f.Position(3:4) below and we won't detect changes
    %in window size properly.
    
    state = pause('on');
    pause(5);

    if ~isequal(f.Position(3:4), diagram_size)
        % diagram size might be smaller than minimum figure window size...
        sprintf('geospm.diagrams.scatter(): Figure position deviates from set position');
        
        scale_factor = ceil(max(f.Position(3:4) ./ diagram_size));
        diagram_size = diagram_size * scale_factor;

        
        set(f, 'Position', [0, 0, diagram_size]);
        set(ax, 'Position', [0, 0, diagram_size]);
        
        props.LineWidth = props.LineWidth * sqrt(scale_factor);
        
        cell_size = cell_size * scale_factor - props.LineWidth;

        props.SizeData = options.marker_sizes * cell_size * cell_size;

        result.corrective_scale_factor = scale_factor;
    end

    pause(state);

    set(f, 'PaperPositionMode', 'manual');
    set(f, 'PaperSize', diagram_size);
    set(f, 'PaperPosition', [0, 0, diagram_size]);
    %set(f, 'Position', [0, 0, f.PaperSize]);
end

function marker_colours = define_colours(N, categories)

    colours = {
        [153, 153, 153], ...
        [255, 102, 51], ...
        [0, 204, 153], ...
        [0, 204, 255], ...
        [255, 217,  100], ...
        [148, 96, 208], ...
        [69, 208, 59]
        };

    
    N_categories = 7;
    
    marker_colours = zeros(N, 3);
    
    for k=1:N_categories
        
        selector = categories == k;
        colour = repmat(colours{k}, sum(selector), 1);
        marker_colours(categories == k, :) = colour;
    end
    
    marker_colours = marker_colours ./ 255.0;
end
