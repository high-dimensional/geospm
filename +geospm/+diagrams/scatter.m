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

    %{

        The following name-value arguments are supported:
        -------------------------------------------------------------------
        
        marker_sizes - A scalar or array of marker sizes.

    %}
    
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
    
    if ~isscalar(options.marker_sizes) && N ~= size(options.marker_sizes, 1)
        error('geospm.diagrams.scatter(): X and marker_sizes size do not match.');
    end
    
    diagram_size = options.max_pixel_size * (frame_size ./ max(frame_size));
    cell_size = options.max_pixel_size / max(frame_size) * options.marker_scale;
    
    f = gcf;
    ax = gca;


    set(f, 'MenuBar', 'none', ...
           'ToolBar', 'none', ...
           'Units', 'points' );

    set(f, 'Position', [0, 0, diagram_size]);

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
    
    scatter_size = cell_size - scatter_options.LineWidth / 2;

    props = scatter(x, y, arguments{:});
    props.SizeData = options.marker_sizes * scatter_size * scatter_size * scale_factor;
    
    
    hold off;
    
    %If we don't pause here the window might not yet have been displayed by
    %the time we check f.Position(3:4) below and we won't detect changes
    %in window size properly.
    
    state = pause('on');
    pause(2);
    
    actual_size = f.Position(3:4);

    if ~isequal(actual_size, diagram_size)

        % diagram size might be smaller than minimum figure window size...
        %fprintf('geospm.diagrams.scatter(): Figure position deviates from set position.\n');
        
        corrective_scale_factor = ceil(max(actual_size ./ diagram_size));
        diagram_size = diagram_size * corrective_scale_factor;
        
        set(f, 'Position', [0, 0, diagram_size]);
        set(ax, 'Position', [0, 0, diagram_size]);
        
        props.LineWidth = props.LineWidth * corrective_scale_factor;
        scatter_size = cell_size * corrective_scale_factor - props.LineWidth / 2;
        props.SizeData = options.marker_sizes * scatter_size * scatter_size;
        
        result.corrective_scale_factor = corrective_scale_factor;
    end
    
    pause(state);
    
    set(f, 'PaperUnits', 'points', ...
           'PaperPositionMode', 'manual', ...
           'PaperSize', diagram_size, ...
           'PaperPosition', [0, 0, diagram_size]);
end
