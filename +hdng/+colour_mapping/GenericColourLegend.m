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

classdef GenericColourLegend < hdng.colour_mapping.ColourLegend
    %GenericColourLegend Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        
        stop_values
        stop_fractions
    end
    
    methods
        
        function obj = GenericColourLegend(colour_map, stop_values, stop_fractions)
            
            obj = obj@hdng.colour_mapping.ColourLegend(colour_map);
            
            obj.stop_values = stop_values;
            obj.stop_fractions = stop_fractions;
        end
        
        function result = render_colours(obj, resolution)

            t = obj.interpolate_steps(resolution);
            
            colours = obj.colour_map.apply({t});
            result = reshape(colours{1}, [resolution 3]);
        end

        function result = render_and_save_as(obj, resolution, filename, title) %#ok<STOUT>
            
            if ~exist('title', 'var')
                title = '';
            end
            
            colours = obj.render_colours(resolution);
            
            f = figure;
            ax = gca;
            
            set(f,'renderer','Painters', 'Position', [0 0 80 600]);
            axis(ax, 'equal', 'auto');

            axis off;
            
            colormap(colours);
            
            caxis([0, 1]);
            
            c = colorbar('east');
    
            if numel(title) ~= 0
                c.Label.String = title;
            end
            
            c.LimitsMode = 'manual';
            c.Limits = [0, 1];
            c.TicksMode = 'manual';
            c.Ticks = 0:1/(numel(obj.stop_values) - 1):1;
            c.TickLabels = obj.format_labels();
            
            saveas(f, filename, 'png');

            close(f);
        end
        
        function labels = format_labels(obj)

            labels = cell(numel(obj.stop_values), 1);
            
            ex = log10(obj.stop_values);
            ex(isinf(ex)) = 0;
            factor = abs(ex) < 1.0;
            ex = (ceil(real( ex .* -(factor * 2 - 1))) - factor) .* -(factor * 2 - 1);
            ex = min(ex);

            if ex > 0
                ex = -3;
            else
                ex = ex - 2;
            end

            ex = -ex;

            fstr = sprintf('%%.%df', ex);

            for i=1:numel(obj.stop_values)
                labels{i} = sprintf(fstr, obj.stop_values(i));
            end
            
        end

        function result = as_json_struct(obj, resolution, title) 
            
            if ~exist('title', 'var')
                title = '';
            end

            result = struct();
            
            result.resolution = resolution;
            result.stop_values = obj.stop_values;
            result.stop_fractions = obj.stop_fractions;
            result.stop_labels = obj.format_labels();
            result.title = title;
            result.colours     = obj.render_colours(resolution);
            result.image_url = obj.encode_as_data_url(result.colours, '.png');
        end

        function result = as_svg(obj, width, height, title)
            
            if ~exist('title', 'var')
                title = '';
            end

            info = obj.as_json_struct(numel(obj.stop_values));
            
            %{
            stop_percentages = zeros(size(info.stop_values));

            for index=1:numel(info.stop_values)
                stop_percentages(index) = (info.stop_values(index) - info.stop_values(1)) / (info.stop_values(end) -  info.stop_values(1));
            end
            %}
            
            stop_offsets = info.stop_fractions;

            svg_stops = cell(size(info.stop_values));

            for index=1:numel(info.stop_values)
                svg_stops{index} = sprintf('<stop offset="%.2f%%" stop-color="rgb(%.2f%%, %.2f%%, %.2f%%)" />', ...
                    100 * stop_offsets(index), ...
                    100 * info.colours(index, 1), ...
                    100 * info.colours(index, 2), ...
                    100 * info.colours(index, 3));
            end
            

            t = hdng.typesetting.Typesetter();
            t.units = 'pixels';

            style = hdng.typesetting.Style();
            style.font_family = 'Barlow';
            style.font_size = 10;
            
            max_width = Inf;
            alignment = 'start';
            
            styles = cell(numel(info.stop_labels), 1);
            
            for index=1:numel(info.stop_values)
                styles{index} = style;
            end
            
            tokens = struct('text', [info.stop_labels; {'M'}], 'style', [styles; {style}]);
            line = t.layout(tokens, max_width, alignment);

            space = line.fragments(end);
            line.fragments = line.fragments(1:end - 1);

            labels_height = line.fragments(1).height;
            
            stop_proportions = stop_offsets(2:end) - stop_offsets(1:end - 1);
            label_gaps = zeros(numel(stop_offsets) - 1, 1);
            
            label_widths = 0;

            for index=1:numel(line.fragments)
                w = line.fragments(index).width + space.width;
                
                label_widths = label_widths + w;
                label_width = w / 2;
                
                if index > 1
                    label_gaps(index - 1) = label_gaps(index - 1)  + label_width;
                end

                if index <= numel(label_gaps)
                    label_gaps(index) = label_gaps(index) + label_width;
                end
            end
            
            label_gaps(1) = label_gaps(1) + (line.fragments(1).width + space.width) / 2;
            label_gaps(end) = label_gaps(end) + (line.fragments(end).width + space.width) / 2;

            label_widths = max([label_widths, width]);

            factor = max(label_gaps ./ (stop_proportions .* label_widths));

            revised_width = label_widths * factor;
            label_gaps = stop_proportions .* revised_width;
            
            gradient = join(svg_stops, newline);
            gradient = gradient{1};

            grad_attributes = hdng.utilities.Dictionary();
            grad_attributes('id') = 'color-map';
            
            grad_attributes = geospm.reports.render_markup_attributes(grad_attributes);
            gradient = sprintf('<linearGradient %s>%s%s%s</linearGradient>', grad_attributes, newline, gradient, newline);
            
            defs = join({'<defs>' ...
                         gradient, ...
                         '</defs>'
                        }, newline);
            defs = defs{1};
            
            origin = [0, 0];
            
            text_attributes = t.context.to_svg_attributes();
            
            stroke_attributes = hdng.utilities.Dictionary();
            stroke_attributes('stroke') = 'black';
            stroke_attributes('stroke-width') = '1pt';
            
            stroke_attributes = geospm.reports.render_markup_attributes(stroke_attributes);

            labels = cell(numel(info.stop_labels) - 2, 1);
            ticks = cell(numel(info.stop_labels), 1);

            x = label_gaps(1);
            text_y = origin(2) + labels_height * 0.75; % can't determine descender height programmatically
            tick_length = labels_height * 0.5;
            tick_offset = tick_length * 0.25;
            
            min_label = sprintf('<text %s x="%g" y="%g">%s</text>', text_attributes, origin(1), text_y, info.stop_labels{1});
            max_label = sprintf('<text %s x="%g" y="%g">%s</text>', text_attributes, origin(1) + revised_width - line.fragments(end).width, text_y, info.stop_labels{end});
            ticks{1} = sprintf('<line %s x1="%g" y1="%g" x2="%g" y2="%g"/>', stroke_attributes, origin(1), origin(2) + labels_height + tick_offset, origin(1), origin(2) + labels_height + tick_length - tick_offset);
            ticks{end} = sprintf('<line %s x1="%g" y1="%g" x2="%g" y2="%g"/>', stroke_attributes, origin(1) + revised_width, origin(2) + labels_height + tick_offset, origin(1) + revised_width, origin(2) + labels_height + tick_length - tick_offset );

            for index=2:numel(info.stop_labels) - 1
                
                dx = x - line.fragments(index).width / 2;

                labels{index - 1} = sprintf('<text %s x="%g" y="%g">%s</text>', text_attributes, origin(1) + dx, text_y, info.stop_labels{index});
                ticks{index} = sprintf('<line %s x1="%g" y1="%g" x2="%g" y2="%g"/>', stroke_attributes, origin(1) + x, origin(2) + labels_height + tick_offset, origin(1) + x, origin(2) + labels_height + tick_length - tick_offset);

                x = x + label_gaps(index);
            end


            rect = sprintf('<rect x="%d" y="%d" width="%d" height="%d" fill="url(''#color-map'')"/>', origin(1), origin(2) + labels_height + tick_length, revised_width, height);

            content = join([{rect, min_label} labels(:)' {max_label} ticks(:)'], newline);

            content = content{1};

            view_box = [
                0, ...
                0, ... 
                revised_width, ...
                labels_height + tick_length + height];
            
            svg_attributes = hdng.utilities.Dictionary();
            svg_attributes('xmlns') = 'http://www.w3.org/2000/svg';
            svg_attributes('xmlns:xlink') = 'http://www.w3.org/1999/xlink';
            svg_attributes('xml:space') = 'preserve';
            svg_attributes('version') = '1.1';
            svg_attributes('viewBox') = obj.render_view_box(view_box(1), view_box(2), view_box(3), view_box(4));
            svg_attributes('preserveAspectRatio') = 'xMidYMid meet';
            svg_attributes('width') = sprintf('%d', view_box(3));
            svg_attributes('height') = sprintf('%d', view_box(4));
            
            svg_attributes = geospm.reports.render_markup_attributes(svg_attributes);
        
            prologue = sprintf('<svg %s>', svg_attributes);
            epilogue = sprintf('</svg>');
            
            result = join({prologue ...
                           defs ...
                           content ...
                           epilogue, ...
                           }, newline);
        
            result = result{1};
        end
        
        function result = as_html(obj, size) %#ok<STOUT,INUSD>
            error('ColourLegend.as_json_struct() must be implemented by a subclass.');
        end
        
    end

    methods (Static)
        
        function result = render_view_box(x, y, width, height)
            result = sprintf('%d %d %d %d', x, y, width, height);
        end
        
        function result = encode_as_data_url(colours, image_ext)
            
            image_data = [colours(:, 1), colours(:, 2), colours(:, 3)];
            image_data = cast(image_data * 65535, 'uint16');
            
            options = struct();
            options.BitDepth = 16;
            
            arguments = hdng.utilities.struct_to_name_value_sequence(options);

            image_file = [tempname image_ext];
            imwrite(image_data, image_file, arguments{:});
            
            data = hdng.utilities.load_bytes(image_file);
            svd_state = recycle('off');
            delete(image_file);
            recycle(svd_state);

            image_type = ['image/' image_ext(2:end)];
            result = ['data:' image_type ';base64' ',' matlab.net.base64encode(data)];
        end

        function t = interpolate_steps(resolution)

            t = zeros(resolution, 1);
            
            for i=1:resolution
                t(i) = 2 * (i - 1) / (resolution - 1) - 1;
            end
        end
    end
end
