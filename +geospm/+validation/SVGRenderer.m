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

classdef SVGRenderer < geospm.validation.PresentationRenderer
    %SVGRenderer Summary.
    %   Detailed description 
    
    properties
        origin

        trace_stroke_width
        trace_stroke_foreground_colour
        trace_stroke_background_colour
    end

    properties (Dependent, Transient)
    end

    properties (GetAccess=private, SetAccess=private)
    end

    methods
        
        function obj = SVGRenderer()
            obj = obj@geospm.validation.PresentationRenderer();

            obj.origin = [0, 0];

            obj.trace_stroke_width = 2;
            obj.trace_stroke_foreground_colour = 'white';
            obj.trace_stroke_background_colour = '#663399';

        end
        
        function result = create_context_for(obj, stack, callback, render_options)

            result = create_context_for@geospm.validation.PresentationRenderer(obj, stack, callback, render_options);
            result.origin = obj.origin;
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

        function result = render_shared_resources(obj, resources, render_options)
            
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

                    case 'shape'
                        values{index} = obj.render_slice_shapes(resource, render_options);

                end
            end

            result = join(values, '');

            result = sprintf('<defs>%s</defs>', result{1});
        end

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

        function result = render_image_layer(obj, layer, context)

            url_prefix = '';

            if isfield(context, 'host_name')
                url_prefix = context.host_name;
            end
            
            [~, identifier] = obj.build_resource_url_and_identifier(url_prefix, layer.image.source_ref, layer.image.path, context); 

            %identifier = obj.create_resource_identifier_from_path(layer.image.path, context);
            resource = context.resources(identifier);
            id = obj.generate_xmlid(resource.identifier);
            
            image_width = resource.assembly.image.y;
            image_height = resource.assembly.image.x;

            scale_factor = context.stack.size(1) / image_width;

            % After trial and error, we specify the original height and width and then use the transform
            % to scale it to the desired magnification size. This way the output appears to render consistently
            % across different viewers.
            
            result = [sprintf('<use href="#%s" ', id), ... 
                      sprintf('style="mix-blend-mode: %s;" ', layer.blend_mode), ...
                      sprintf('transform="translate(%d %d) scale(%g)" ', context.origin(1), context.origin(2), scale_factor), ...
                      sprintf('width="%d" ', image_width), ...
                      sprintf('height="%d" ', image_height), ...
                      sprintf('opacity="%g" ', layer.opacity), ...
                      '/>'];
        end
        
        %{
        function result = render_volume_layer(obj, layer, context)

            slice_index = layer.slice_map.index_for_name(obj.slice_name, 0);
            slice_offset = obj.compute_volume_slice_offset(slice_index, layer.height, 1);

            resource = context.resources(layer.image.path);
            url = obj.data_url_from_image(resource, 0, -slice_offset, layer.width, layer.height);
            
            result = [
                '<image class="volume-image" ' ...
                sprintf('style="image-rendering: crisp-edges; mix-blend-mode: %s;" ', layer.blend_mode) ...
                sprintf('x="%d" y="%d" ', context.origin(1), context.origin(2)) ...
                sprintf('width="%d" height="%d" ', context.stack.size(1), context.stack.size(2)) ...
                sprintf('opacity="%g" ', layer.opacity) ...
                sprintf('xlink:href="%s" ', url) ...
                '/>'
                ];
        end
        %}
        
        function result = render_volume_layer(obj, layer, context)

            url_prefix = '';

            if isfield(context, 'host_name')
                url_prefix = context.host_name;
            end
            
            [~, identifier] = obj.build_resource_url_and_identifier(url_prefix, layer.image.source_ref, layer.image.path, context); 
            
            %identifier = obj.create_resource_identifier_from_path(layer.image.path, context);
            resource = context.resources(identifier);
            id = obj.generate_xmlid(resource.identifier);
            
            image_width = resource.assembly.width;
            image_height = resource.assembly.height;
            
            scale_factor = context.stack.size(1) / image_width;
            
            % After trial and error, we specify the original height and width and then use the transform
            % to scale it to the desired magnification size. This way the output appears to render consistently
            % across different viewers.
            
            result = [sprintf('<use href="#%s" ', id), ... 
                      sprintf('style="mix-blend-mode: %s;" ', layer.blend_mode), ...
                      sprintf('transform="translate(%d %d) scale(%g)" ', context.origin(1), context.origin(2), scale_factor), ...
                      sprintf('width="%d" ', image_width), ...
                      sprintf('height="%d" ', image_height), ...
                      sprintf('opacity="%g" ', layer.opacity), ...
                      '/>' ...
                      ];
        end

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
            
            %identifier = obj.create_resource_identifier_from_path(layer.shape_paths{1}, context);
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

        function result = render_layer(obj, layer, context)

            result = '';

            if ~isa(layer, 'geospm.validation.PresentationLayer')
                return;
            end

            if isa(layer, 'geospm.validation.VolumeLayer')
                result = obj.render_volume_layer(layer, context);
            elseif isa(layer, 'geospm.validation.SliceShapesLayer')
                result = obj.render_slice_shapes_layer(layer, context);
            elseif isa(layer, 'geospm.validation.ImageLayer')
                result = obj.render_image_layer(layer, context);
            else
                error('Unknown layer type!')
            end
        end

        function result = render_loaded_context(obj, context)
            
            layers = context.stack.selected_layers;
            fragments = cell(size(layers));

            for index=1:numel(layers)
                layer = layers{index};
                fragments{index} = obj.render_layer(layer, context);
            end
            
            result = join(fragments, newline);
            result = result{1};

            %view_box = sprintf('0 0 %f %f}', context.stack.size(1), context.stack.size(2));
        end
    end
    
    methods (Static)
    end
end
