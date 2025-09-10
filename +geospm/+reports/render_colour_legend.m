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

function height = render_colour_legend(obj, x, y, max_width, title, style, style_class, ...
    render_context)
    
    renderer = render_context.renderer;
    
    info = obj.as_json_struct(numel(obj.stop_values));

    t = hdng.typesetting.Typesetter();
    t.units = 'pixels';
    
    alignment = 'start';
    
    styles = cell(numel(info.stop_labels), 1);
    
    for index=1:numel(info.stop_values)
        styles{index} = style;
    end

    mid_index = ceil(numel(info.stop_labels) / 2);
    
    min_label = info.stop_labels{1};
    mid_label = info.stop_labels{mid_index};
    max_label = info.stop_labels{end};

    if ~isempty(str2double(mid_label))
        mid_label_tmp = str2double(mid_label);

        if isequal(mid_label_tmp, 0)
            mid_label = '0.0';
        end
    end

    tokens = struct('text', [min_label; mid_label; max_label; {title}], ...
                    'style', [styles(1); styles(mid_index); styles(end); {style}]);

    line = t.layout(tokens, Inf, alignment);

    title_line = line.fragments(end);

    line.fragments = line.fragments(1:end - 1);

    label_height = line.fragments(1).height;
    
    stop_offsets = info.stop_fractions;
    stops = struct.empty;

    for index=1:numel(info.stop_values)
        stops(index).offset = stop_offsets(index);
        stops(index).colour = sprintf('rgb(%g%%, %g%%, %g%%)', ...
            100 * info.colours(index, 1), ...
            100 * info.colours(index, 2), ...
            100 * info.colours(index, 3));
    end


    gradient_id = ['id_' replace(char(java.util.UUID.randomUUID), '-', '')];

    renderer.define_linear_gradient(gradient_id, stops, '', render_context);
    
    x_start = x;
    y_start = y;

    % can't determine descender height programmatically, so these are 
    % heuristics
    descender_height = label_height * 0.75;
    x_height = descender_height * 0.5;
    line_height = label_height * 1.125;

    tick_length = descender_height / 3;
    
    x_limit = x_start + max_width;
    x_mid = x_start + max_width / 2;
    
    ramp_height = descender_height;
    ramp_top = y_start + line_height;
    ramp_bottom = y_start + line_height + ramp_height;

    renderer.render_rect(x_start, x_limit, ramp_top, ramp_bottom, render_context, 'fill', sprintf('url(#%s)', gradient_id));
    
    stroke_width = 2;
    line_attrs = {'stroke', 'black', 'stroke_width', sprintf('%g', stroke_width)};

    stroke_half_width = stroke_width / 2;

    renderer.render_line(x_start + stroke_half_width, x_start + stroke_half_width, ramp_bottom, ramp_bottom + tick_length, render_context, line_attrs{:});
    renderer.render_line(x_mid,   x_mid,   ramp_bottom, ramp_bottom + tick_length, render_context, line_attrs{:});
    renderer.render_line(x_limit - stroke_half_width, x_limit - stroke_half_width, ramp_bottom, ramp_bottom + tick_length, render_context, line_attrs{:});
    
    renderer.render_text(x_mid - title_line.width / 2, y_start + descender_height, false, false, title, render_context, 'class', style_class);
    
    label_y = ramp_bottom + x_height + descender_height;

    renderer.render_text(x_start, label_y, false, false, min_label, render_context, 'class', style_class);
    renderer.render_text(x_start + max_width / 2 - line.fragments(end - 1).width / 2, label_y, false, false, mid_label, render_context, 'class', style_class);
    renderer.render_text(x_limit - line.fragments(end).width, label_y, false, false, max_label, render_context, 'class', style_class);
    
    height = line_height + ramp_height + x_height + label_height;
end
