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

classdef SVGRenderer < hdng.diagrams.rendering.Renderer
    %SVGRenderer Summary.
    %   Detailed description 
    
    properties
        origin

        trace_stroke_width
        trace_stroke_foreground_colour
        trace_stroke_background_colour

        default_view_box
    end

    properties (Dependent, Transient)
    end

    properties (GetAccess=private, SetAccess=private)
    end

    methods
        
        function obj = SVGRenderer()
            obj = obj@hdng.diagrams.rendering.Renderer();

            obj.origin = [0, 0];

            obj.trace_stroke_width = 2;
            obj.trace_stroke_foreground_colour = 'white';
            obj.trace_stroke_background_colour = '#663399';

            obj.default_view_box = [0, 0, 3740, 3740];
            
        end
        
        %{
        function result = create_context_for(obj, stack, callback, render_options)

            result = create_context_for@hdng.diagrams.rendering.Renderer(obj, stack, callback, render_options);
            result.origin = obj.origin;
        end
        %}

        function result = define_svg_attributes(obj, view_box)

            if ~exist('view_box', 'var')
                view_box = obj.default_view_box;
            end

            result = hdng.utilities.Dictionary();
            result('xmlns') = 'http://www.w3.org/2000/svg';
            result('xmlns:xlink') = 'http://www.w3.org/1999/xlink';
            result('xml:space') = 'preserve';
            result('version') = '1.1';
            result('viewBox') = obj.format_view_box(...
                view_box(1), view_box(2), view_box(3), view_box(4));
            result('preserveAspectRatio') = 'xMidYMid meet';
            result('width') = sprintf('%d', view_box(3));
            result('height') = sprintf('%d', view_box(4));
        end

        function result = generate_xmlid(~, str)
            %ID and NAME tokens must begin with a letter ([A-Za-z]) and may be followed by any number of letters,
            %digits ([0-9]), hyphens ("-"), underscores ("_"), colons (":"), and periods (".").
            
            result = regexprep(str, '^[^A-Za-z_]', ':');
            result = regexprep(result, '[^A-Za-z_0-9\-:.]', ':');
        end

        function result = data_url_from_image(~, resource, x, y, width, height)

            if ~exist('x', 'var')
                x = 0;
            end

            if ~exist('y', 'var')
                y = 0;
            end

            image_height = resource.assembly.image.x;
            image_width = resource.assembly.image.y;
            
            if ~exist('width', 'var')
                width = image_width;
            end

            if ~exist('height', 'var')
                height = image_height;
            end
            
            [~, ~, image_ext] = fileparts(resource.assembly.image.path);
            
            if width ~= image_width || height ~= image_height
                image_data = resource.assembly.image.data(y + 1:y + height, x + 1:x + width, :, :);
                
                if resource.assembly.image.alpha_channel_index ~= 0
                    alpha_data = image_data(:, :, 1, resource.assembly.image.alpha_channel_index);
                else
                    alpha_data = [];
                end

                image_data = image_data(:, :, 1, resource.assembly.image.non_alpha_indices);
                image_data = reshape(image_data, size(image_data, 1), size(image_data, 2), size(image_data, 4));
                
                switch class(image_data)
                    case 'uint8'
                        bit_depth = 8;
                    case 'uint16'
                        bit_depth = 16;
                    otherwise
                        error('SVGRenderer.data_url_from_image(): Cannot determine bit depth.');
                end
                

                options = struct();

                if ~isempty(alpha_data)
                    options.Alpha = alpha_data;
                end

                options.BitDepth = bit_depth;

                arguments = hdng.utilities.struct_to_name_value_sequence(options);

                image_file = [tempname image_ext];
                imwrite(image_data, image_file, arguments{:});
                data = hdng.utilities.load_bytes(image_file);
                svd_state = recycle('off');
                delete(image_file);
                recycle(svd_state);
            else
                data = resource.assembly.data;
            end

            image_type = ['image/' image_ext(2:end)];
            result = ['data:' image_type ';base64' ',' matlab.net.base64encode(data)];
        end
        


        function render_image(obj, image, context, varargin)

            render_options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(render_options, 'host_name')
                render_options.host_name = '';
            end

            if ~isfield(render_options, 'blend_mode')
                render_options.blend_mode = [];
            end
            
            if ~isfield(render_options, 'opacity')
                render_options.opacity = [];
            end

            if ~isfield(render_options, 'resource_identifier_expr')
                render_options.resource_identifier_expr = '';
            end

            url_prefix = render_options.host_name;
            
            [~, identifier] = context.resource_manager.build_resource_url_and_identifier(...
                url_prefix, image.source_ref, image.path, ...
                render_options.resource_identifier_expr); 
            
            resource = context.resources(identifier);
            id = obj.generate_xmlid(resource.identifier);
            
            image_width = resource.assembly.image.y;
            image_height = resource.assembly.image.x;

            scale_factor = 1; %context.stack.size(1) / image_width;

            % After trial and error, we specify the original height and width and then use the transform
            % to scale it to the desired magnification size. This way the output appears to render consistently
            % across different viewers.
            
            result = [sprintf('<use href="#%s" ', id), ... 
                      sprintf('style="mix-blend-mode: %s;" ', render_options.blend_mode), ...
                      sprintf('transform="translate(%d %d) scale(%g)" ', context.origin(1), context.origin(2), scale_factor), ...
                      sprintf('width="%d" ', image_width), ...
                      sprintf('height="%d" ', image_height), ...
                      sprintf('opacity="%g" ', render_options.opacity), ...
                      '/>'];
            
            context.target.content.text = result;
        end


        function render_shared_resources(obj, resources, context, varargin)

            render_options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(render_options, 'host_name')
                render_options.host_name = '';
            end
            
            keys = resources.keys();
            values = cell(size(keys));

            for index=1:numel(keys)
                key = keys{index};

                resource = resources(key);

                values{index} = '';

                if ~resource.is_shared
                    continue
                end
                
                switch resource.type
                    case 'image'
                        url = obj.data_url_from_image(resource, resource.assembly.x, resource.assembly.y, resource.assembly.width, resource.assembly.height);
                        id = obj.generate_xmlid(resource.identifier);
                        
                        image_width = resource.assembly.width;
                        image_height = resource.assembly.height;
                        
                        image_style = '';

                        if isfield(resource.attachments, 'image_style')
                            image_style = [' style="' resource.attachments.image_style '"'];
                        end

                        if isfield(resource.assembly, 'slice_index')
                            slice_index_property = sprintf(' data-slice-index="%d" ', resource.assembly.slice_index);
                        else
                            slice_index_property = '';
                        end

                        values{index} = [...
                            sprintf('<symbol id="%s" viewBox="0 0 %d %d"', id, image_width, image_height), ...
                            sprintf(' width="%d" height="%d"', image_width, image_height), ...
                            slice_index_property, ...
                            ' preserveAspectRatio="xMidYMid meet">' ....
                            sprintf(' <image x="0" y="0" width="%d" height="%d" xlink:href="%s"%s/>', image_width, image_height, url, image_style), ...
                            '</symbol>' newline
                        ];

                    %case 'shape'
                    %    values{index} = obj.render_slice_shapes(resource, render_options);

                end
            end

            result = join(values, '');
            context.target.prologue.text = sprintf('<defs>%s</defs>', result{1});
        end

        %{
        function result = render_slice_shapes(obj, resource, render_options)
            
            slice_shapes = resource.attachments.slice_shapes;
            symbol_id = obj.generate_xmlid(slice_shapes.shape_paths{resource.assembly.slice_index});

            transform = [ 1,  0, -slice_shapes.origin(1); 
                          0, -1, slice_shapes.origin(2) + slice_shapes.span(2)];
            
            paths = cell(numel(resource.assembly.shapes), 1);
            
            for index=1:numel(resource.assembly.shapes)
                shape = resource.assembly.shapes(index);

                paths{index} = geospm.reports.render_shape(shape, transform);
            end
            
            paths = join(paths, newline);
            paths = paths{1};

            result = [...
                sprintf('<symbol id="%s" viewBox="0 0 %d %d"', symbol_id, slice_shapes.span(1), slice_shapes.span(2)), ...
                sprintf(' width="%d" height="%d">', slice_shapes.span(1), slice_shapes.span(2)), ...
                sprintf(' data-slice-index="%d" ', resource.assembly.slice_index), ...
                paths, ...
                '</symbol>' newline
            ];
        end
        %}
        
        %{
        function result = render_slice_shapes_layer(obj, layer, context)

            %identifier = regexprep(layer.shape_paths{1}, '^\/|\/$', '');

            url_prefix = '';

            if isfield(context, 'host_name')
                url_prefix = context.host_name;
            end
            
            slice_name = '';

            if isfield(context, 'slice_name')
                slice_name = context.slice_name;
            end

            slice_index = layer.slice_map.index_for_name(slice_name, 1);

            path = layer.shape_paths{slice_index};

            [~, identifier] = obj.build_resource_url_and_identifier(url_prefix, layer.source_ref, path, context); 
            
            resource = context.resources(identifier);
            
            slice_shapes = resource.attachments.slice_shapes;
            symbol_id = obj.generate_xmlid(slice_shapes.shape_paths{resource.assembly.slice_index});
            
            pixel_size = slice_shapes.span(1) / slice_shapes.resolution(1) * obj.trace_stroke_width;
            stroke_width = pixel_size / context.magnification;
            dash_length = stroke_width * 2;
            scale_factor = (slice_shapes.resolution(1) * context.magnification) / slice_shapes.span(1);
            
            result = ['<g ', ...
                      sprintf('transform="translate(%d %d) scale(%g)" ', context.origin(1), context.origin(2), scale_factor), ...
                      sprintf('opacity="%g"', layer.opacity), ...
                      '>', newline, ...
                      sprintf('<use href="#%s" ', symbol_id), ... 
                      sprintf('fill="none" stroke="%s" fill-rule="evenodd" clip-rule="evenodd" ', obj.trace_stroke_foreground_colour), ...
                      sprintf('stroke-line-join="miter" stroke-width="%g" ', stroke_width), ...
                      sprintf('width="%d" height="%d" ', slice_shapes.span(1), slice_shapes.span(2)), ...
                      '/>', ...
                      newline, ...
                      sprintf('<use href="#%s" ', symbol_id), ... 
                      sprintf('fill="none" stroke="%s" fill-rule="evenodd" clip-rule="evenodd" ', obj.trace_stroke_foreground_colour), ...
                      sprintf('stroke-line-join="miter" stroke-width="%g" ', stroke_width), ...
                      sprintf('stroke-dasharray="%g %g" ', dash_length * 2, dash_length), ...
                      sprintf('width="%d" height="%d" ', slice_shapes.span(1), slice_shapes.span(2)), ...
                      '/>', ...
                      newline, ...
                      '</g>', newline ...
                      ];
        end
        %}

        function begin_rect(obj, x1, x2, y1, y2, context, varargin)
            attributes = obj.parse_render_attributes(varargin{:});

            result = ['<rect ', ...
                      sprintf('x="%g" width="%g" y="%g" height="%g" ', x1, x2 - x1, y1, y2 - y1), ...
                      obj.format_markup_attributes(attributes), newline, ...
                      '>', newline, ...
                      ];
            
            context.target.content.text = result;
        end

        function end_rect(obj, context) %#ok<INUSD>

            result = ['</rect>', newline, ...
                      ];
            
            context.target.content.text = result;
        end

        function render_rect(obj, x1, x2, y1, y2, context, varargin)
            obj.begin_rect(x1, x2, y1, y2, context, varargin{:});
            obj.end_rect(context);
        end
        
        function begin_circle(obj, cx, cy, r, context, varargin)
            attributes = obj.parse_render_attributes(varargin{:});
            
            result = ['<circle ', ...
                      sprintf('cx="%g" cy="%g" r="%g" ', cx, cy, r), ...
                      obj.format_markup_attributes(attributes), ...
                      '>', newline, ...
                      ];
            
            context.target.content.text = result;
        end
        
        function end_circle(obj, context) %#ok<INUSD>

            result = ['</circle>', newline, ...
                      ];
            
            context.target.content.text = result;
        end
        
        function render_circle(obj, cx, cy, r, context, varargin)
            obj.begin_circle(cx, cy, r, context, varargin{:});
            obj.end_circle(context);
        end

        function begin_line(obj, x1, x2, y1, y2, context, varargin)
            attributes = obj.parse_render_attributes(varargin{:});
            
            result = ['<line ', ...
                      sprintf('x1="%g" x2="%g" y1="%g" y2="%g" ', x1, x2, y1, y2), ...
                      obj.format_markup_attributes(attributes), ...
                      '>', newline, ...
                      ];
            
            context.target.content.text = result;
        end

        function end_line(obj, context) %#ok<INUSD>
            
            result = ['</line>', newline, ...
                      ];
            
            context.target.content.text = result;
        end

        function render_line(obj, x1, x2, y1, y2, context, varargin)
            obj.begin_line(x1, x2, y1, y2, context, varargin{:});
            obj.end_line(context);
        end
        
        function begin_text(obj, x, y, x_is_increment, y_is_increment, ...
                    text, context, varargin)
            
            attributes = obj.parse_render_attributes(varargin{:});
            
            x_name = 'x';
            
            if x_is_increment
                x_name = 'dx';
            end

            y_name = 'y';

            if y_is_increment
                y_name = 'dy';
            end

            x_specifier = '%g';

            if ischar(x)
                x_specifier = '%s';
            end

            y_specifier = '%g';

            if ischar(y)
                y_specifier = '%s';
            end

            result = ['<text ', ...
                      sprintf('%s="%s" %s="%s" ', ...
                      x_name, sprintf(x_specifier, x), ...
                      y_name, sprintf(y_specifier, y)), ...
                      obj.format_markup_attributes(attributes), ...
                      '>', ...
                      text, ...
                       %'</text>', newline ...
                      ];
            
            context.target.content.text = result;
        end
        
        function end_text(obj, context) %#ok<INUSD>
            result = ['</text>', newline ...
                      ];
            
            context.target.content.text = result;
        end

        function render_text(obj, x, y, x_is_increment, y_is_increment, ...
                    text, context, varargin)
            
            obj.begin_text(x, y, x_is_increment, y_is_increment, ...
                    text, context, varargin{:});
            obj.end_text(context);
        end

        function begin_group(obj, x, y, context, varargin) %#ok<INUSD>
            result = [sprintf('<g transform="translate(%g %g)"', x, y), ...
                      '>', newline, ...
                      ];
            
            context.target.content.text = result;
        end

        function end_group(obj, x, y, context, varargin) %#ok<INUSD>
            result = [newline, ...
                      '</g>', newline, ...
                      ];
            
            context.target.content.text = result;
        end

        function render_style_definitions(obj, style_definitions, context, varargin) %#ok<INUSD>
           result = [sprintf('<style type="text/css"'), ...
                     '>', newline, ...
                     style_definitions, newline, ...
                     '</style>', newline
                     ];

           context.target.styles.text = result; 
        end

        %{
        function begin_style(obj, target, context, varargin) %#ok<INUSD>

            if isempty(target)
                target = 'styles';
            end

            result = [sprintf('<style'), ...
                      '>', newline, ...
                      ];
            
            context.target.(target).text = result;
        end

        function end_style(obj, target, context, varargin) %#ok<INUSD>

            if isempty(target)
                target = 'styles';
            end
            
            result = [newline, ...
                      '</style>', newline, ...
                      ];
            
            context.target.(target).text = result;
        end
        %}

        function result = create_target_proxy(obj)

            fragments = struct();
            fragments.svg_start = ...
                hdng.diagrams.rendering.svg.SVGPseudoTarget('part', 'svg_start', 'renderer', obj);
            fragments.styles = hdng.diagrams.rendering.BufferedTarget();
            fragments.prologue = hdng.diagrams.rendering.BufferedTarget();
            fragments.content = hdng.diagrams.rendering.BufferedTarget();
            fragments.epilogue = hdng.diagrams.rendering.BufferedTarget();
            fragments.svg_end = ...
                hdng.diagrams.rendering.svg.SVGPseudoTarget('part', 'svg_end', 'renderer', obj);
            
            result = hdng.diagrams.rendering.TargetProxy(...
                'fragments', fragments ...
            );
        end

        function result = format_svg_part(obj, part, context)
            result = '';

            switch part
                case 'svg_start'

                    svg_attributes = obj.define_svg_attributes();
                    svg_attributes = obj.format_markup_attributes(svg_attributes);

                    result = [...
                        '<?xml version="1.0" encoding="utf-8" ?>', newline, ...
                        '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">', newline, ...
                        sprintf('<svg %s>', svg_attributes) ...
                        ];

                case 'svg_end'
                    result = sprintf('</svg>');
            end
        end
    end

    methods (Access=protected)

        function result = parse_render_attributes(~, varargin)
        
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'class')
                options.class = [];
            end

            if ~isfield(options, 'style')
                options.style = [];
            end

            if ~isfield(options, 'fill')
                options.fill = [];
            end

            if ~isfield(options, 'stroke')
                options.stroke = [];
            end

            if ~isfield(options, 'stroke_width')
                options.stroke_width = [];
            end

            if ~isfield(options, 'stroke_linecap')
                options.stroke_linecap = [];
            end

            if ~isfield(options, 'stroke_linejoin')
                options.stroke_linejoin = [];
            end

            result = hdng.utilities.Dictionary();

            if ~isempty(options.class)
                result('class') = options.class;
            end

            if ~isempty(options.style)
                result('style') = options.style;
            end

            if ~isempty(options.fill)
                result('fill') = options.fill;
            end

            if ~isempty(options.stroke)
                result('stroke') = options.stroke;
            end

            if ~isempty(options.stroke_width)
                result('stroke-width') = options.stroke_width;
            end

            if ~isempty(options.stroke_linecap)
                result('stroke-linecap') = options.stroke_linecap;
            end

            if ~isempty(options.stroke_linejoin)
                result('stroke-linejoin') = options.stroke_linejoin;
            end


        end
        function result = format_markup_attributes(~, attributes)
            
            result = '';
            keys = attributes.keys();
            
            for index=1:numel(keys)
                key = keys{index};
                value = attributes(key);
                delimiter = ' ';
        
                if isempty(result)
                    delimiter = '';
                end
                
                result = [result sprintf('%s%s="%s"', delimiter, key, value)]; %#ok<AGROW>
            end
        end

        function result = format_view_box(~, x, y, width, height)
            result = sprintf('%d %d %d %d', x, y, width, height);
        end
    end
end
