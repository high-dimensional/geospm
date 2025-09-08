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
    end

    properties (Dependent, Transient)
    end

    properties (GetAccess=private, SetAccess=private)
    end

    methods
        
        function obj = SVGRenderer()
            obj = obj@hdng.diagrams.rendering.Renderer();
            
        end
        
        function result = define_svg_attributes(obj, context)

            view_box = context.view_box;
            
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

        function scale_factor = adjust_scale_factor(~, resource, scale_factor)
            
            if isa(scale_factor, 'function_handle')
                scale_factor = scale_factor(resource);
            elseif isempty(scale_factor)
                scale_factor = 1;
            end
        end

        function render_options = parse_render_options(~, name_value_pairs)

            render_options = hdng.utilities.parse_struct_from_varargin(name_value_pairs{:});

            if ~isfield(render_options, 'blend_mode')
                render_options.blend_mode = 'normal';
            end
            
            if ~isfield(render_options, 'opacity')
                render_options.opacity = '1';
            end
            
            if ~isfield(render_options, 'magnification')
                render_options.magnification = '1';
            end
        end
        
        function render_image(obj, image, x, y, scale_factor, context, varargin)

            render_options = obj.parse_render_options(varargin);
            
            url_prefix = context.resource_manager.host_name;

            path =  context.resource_manager.resolve_path_alias(image.path);
            
            %{
            if endsWith(path, 'model_data.png') && strcmp(render_options.blend_mode, 'multiply')
                render_options.blend_mode = 'soft-light';
                render_options.opacity = 0.7;
            end
            %}
            
            [~, identifier] = context.resource_manager.build_resource_url_and_identifier(...
                url_prefix, image.source_ref, path); 
            
            resource = context.resources(identifier);
            id = obj.generate_xmlid(resource.identifier);
            
            image_width = resource.assembly.image.y;
            image_height = resource.assembly.image.x;

            scale_factor = obj.adjust_scale_factor(resource, scale_factor);
            
            % After trial and error, we specify the original height and width and then use the transform
            % to scale it to the desired magnification size. This way the output appears to render consistently
            % across different viewers.
            
            result = [sprintf('<use xlink:href="#%s" ', id), ... 
                      sprintf('style="mix-blend-mode: %s;" ', render_options.blend_mode), ...
                      sprintf('transform="translate(%d %d) scale(%g)" ', x, y, scale_factor), ...
                      sprintf('width="%dpx" ', image_width), ...
                      sprintf('height="%dpx" ', image_height), ...
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

            for index=1:numel(keys)
                key = keys{index};

                resource = resources(key);

                if ~resource.is_shared
                    continue
                end
                
                obj.render_shared_resource(resource, context);
            end

            %result = join(values, '');
            %context.target.prologue.text = sprintf('<defs>%s</defs>', result{1});
        end
        
        function begin_rect(obj, x1, x2, y1, y2, context, varargin)
            attributes = obj.parse_render_attributes(varargin{:});

            result = ['<rect ', ...
                      sprintf('x="%gpx" width="%gpx" y="%gpx" height="%gpx" ', x1, x2 - x1, y1, y2 - y1), ...
                      obj.format_markup_attributes(attributes), ...
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
                      sprintf('cx="%gpx" cy="%gpx" r="%gpx" ', cx, cy, r), ...
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
                      sprintf('x1="%gpx" x2="%gpx" y1="%gpx" y2="%gpx" ', x1, x2, y1, y2), ...
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

            text = hdng.utilities.html_escape(text);

            result = ['<text ', ...
                      sprintf('%s="%spx" %s="%spx" ', ...
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

        function begin_group(obj, x, y, context, varargin)

            attributes = obj.parse_render_attributes(varargin{:});
            
            transform = '';

            if x ~= 0 || y ~= 0
                transform = sprintf('transform="translate(%g %g)"', x, y);
            end

            result = [sprintf('<g %s', transform), ..., ...
                      obj.format_markup_attributes(attributes), ...
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

        function define_linear_gradient(obj, id, stops, transform, context) %#ok<INUSD>
            % stops is a struct array with fields offset and colour
            
            formatted_stops = cell(numel(stops), 1);

            use_opacity = isfield(stops, 'opacity');

            for index=1:numel(stops)
                stop = stops(index);
                opacity = '';
                
                if use_opacity
                    opacity = sprintf(' stop-opacity="%g"', stop.opacity);
                end

                formatted_stops{index} = sprintf('<stop offset="%.2f%%" stop-color="%s"%s/>', stop.offset * 100, stop.colour, opacity);
            end

            formatted_stops = join(formatted_stops, [newline '  ']);
            formatted_stops = formatted_stops{1};
            
            if ~isempty(transform)
                transform = sprintf(' gradientTransform="%s"', transform);
            end

            result = ['<linearGradient ', ...
                      sprintf('id="%s"%s', id, transform), ...
                      '>', ...
                      formatted_stops, ...
                       '</linearGradient>', newline ...
                      ];

            context.target.prologue.text = result;
        end

        function render_style_definitions(obj, style_definitions, context, varargin) %#ok<INUSD>
           result = [sprintf('<style type="text/css"'), ...
                     '>', newline, ...
                     style_definitions, newline, ...
                     '</style>', newline
                     ];

           context.target.styles.text = result; 
        end


        function begin_inline_definitions(~, context)
            result = ['<defs>', newline ...
                      ];
            
            context.target.content.text = result;

        end

        function end_inline_definitions(~, context)
            result = [newline, ...
                      '</defs>', newline, ...
                      ];
            
            context.target.content.text = result;
        end


        function result = create_target_proxy(obj)

            fragments = struct();
            fragments.svg_start = ...
                hdng.diagrams.rendering.svg.SVGPseudoTarget('part', 'svg_start', 'renderer', obj);
            fragments.styles = hdng.diagrams.rendering.svg.SVGBufferedTarget('part', 'styles', 'renderer', obj);
            fragments.prologue = hdng.diagrams.rendering.svg.SVGBufferedTarget('part', 'prologue', 'renderer', obj);
            fragments.content = hdng.diagrams.rendering.svg.SVGBufferedTarget('part', 'content', 'renderer', obj);
            fragments.epilogue = hdng.diagrams.rendering.svg.SVGBufferedTarget('part', 'epilogue', 'renderer', obj);
            fragments.svg_end = ...
                hdng.diagrams.rendering.svg.SVGPseudoTarget('part', 'svg_end', 'renderer', obj);
            
            result = hdng.diagrams.rendering.TargetProxy(...
                'fragments', fragments ...
            );
        end

        function result = format_svg_part(obj, part, content, context)

            switch part
                case 'svg_start'

                    svg_attributes = obj.define_svg_attributes(context);
                    svg_attributes = obj.format_markup_attributes(svg_attributes);

                    result = [...
                        '<?xml version="1.0" encoding="utf-8" ?>', newline, ...
                        '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">', newline, ...
                        sprintf('<svg %s>', svg_attributes) ...
                        ];

                case 'svg_end'
                    result = sprintf('</svg>');
                
                case 'prologue'
                    result = sprintf('<defs>%s</defs>', content);

                otherwise
                    result = content;
            end
        end
    end

    methods (Access=protected)

        function result = parse_render_attributes(~, varargin)
        
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'id')
                options.id = [];
            end

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

            if ~isfield(options, 'opacity')
                options.opacity = [];
            end

            if ~isfield(options, 'mix_blend_mode')
                options.mix_blend_mode = [];
            end

            result = hdng.utilities.Dictionary();

            if ~isempty(options.id)
                result('id') = options.id;
            end

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

            if ~isempty(options.opacity)
                result('opacity') = options.opacity;
            end

            if ~isempty(options.mix_blend_mode)
                result('mix-blend-mode') = options.mix_blend_mode;
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


        function did_render = render_shared_resource(obj, resource, context)
            
            did_render = false;

            switch resource.type
                case 'image'
                    obj.render_shared_image(resource, context);
                    did_render = true;

            end
        end

        function render_shared_image(obj, resource, context)
                        
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

            %{
            context.target.prologue.text = [...
                sprintf('<symbol id="%s" viewBox="0 0 %d %d"', id, image_width, image_height), ...
                sprintf(' width="%d" height="%d"', image_width, image_height), ...
                slice_index_property, ...
                ' preserveAspectRatio="xMidYMid meet">' ....
                sprintf(' <image x="0" y="0" width="%d" height="%d" xlink:href="%s"%s/>', image_width, image_height, url, image_style), ...
                '</symbol>' newline
            ];
            %}
            context.target.prologue.text = [...
                sprintf(' <image id="%s" x="0" y="0" width="%dpx" height="%dpx" xlink:href="%s"%s/>', id, image_width, image_height, url, image_style), ...
                newline
            ];
        end
        
    end
end
