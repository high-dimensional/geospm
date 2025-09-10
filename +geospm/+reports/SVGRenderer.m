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

classdef SVGRenderer < hdng.diagrams.rendering.svg.SVGRenderer
    %SVGRenderer Summary.
    %   Detailed description 
    
    properties

        trace_stroke_width
        trace_stroke_foreground_colour
        trace_stroke_background_colour

        render_pixels_as_rects
    end

    properties (Dependent, Transient)
    end

    properties (GetAccess=private, SetAccess=private)
    end

    methods
        
        function obj = SVGRenderer()
            obj = obj@hdng.diagrams.rendering.svg.SVGRenderer();
            
            obj.trace_stroke_width = 6;
            obj.trace_stroke_foreground_colour = 'white';
            obj.trace_stroke_background_colour = '#663399';

            obj.render_pixels_as_rects = false;
        end

        function render_volume(obj, volume, x, y, scale_factor, context, varargin)
            
            render_options = obj.parse_render_options(varargin);

            url_prefix = context.resource_manager.host_name;
            
            path = context.resource_manager.resolve_path_alias(volume.image.path);

            [~, identifier] = context.resource_manager.build_resource_url_and_identifier(...
                url_prefix, volume.image.source_ref, path); 
            
            resource = context.resources(identifier);
            id = obj.generate_xmlid(resource.identifier);
            
            image_width = resource.assembly.width;
            image_height = resource.assembly.height;

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
                      '/>' ...
                      ];
            
            context.target.content.text = result;
        end
        

        function render_slice_shapes(obj, specifier, x, y, scale_factor, context, varargin)
            
            render_options = obj.parse_render_options(varargin);
            
            slice_index = specifier.slice_map.index_for_name(context.resource_manager.slice_name, 1);
            path = specifier.shape_paths{slice_index};

            url_prefix = context.resource_manager.host_name;
            
            path = context.resource_manager.resolve_path_alias(path);

            [~, identifier] = context.resource_manager.build_resource_url_and_identifier(...
                url_prefix, specifier.source_ref, path); 
            
            resource = context.resources(identifier);
            
            symbol_id = obj.generate_xmlid(specifier.shape_paths{resource.assembly.slice_index});
            
            pixel_size = specifier.span(1) / specifier.resolution(1) * obj.trace_stroke_width;
            stroke_width = pixel_size / render_options.magnification;
            dash_length = stroke_width * 2;

            %scale_factor = (specifier.resolution(1) * render_options.magnification) / specifier.span(1);
            
            scale_factor = obj.adjust_scale_factor(resource, scale_factor);

            result = ['<g ', ...
                      sprintf('transform="translate(%d %d) scale(%g)" ', x, y, scale_factor), ...
                      sprintf('opacity="%g"', render_options.opacity), ...
                      '>', newline, ...
                      sprintf('<use xlink:href="#%s" ', symbol_id), ... 
                      sprintf('fill="none" stroke="%s" fill-rule="evenodd" clip-rule="evenodd" ', obj.trace_stroke_foreground_colour), ...
                      sprintf('stroke-linejoin="miter" stroke-width="%gpx" ', stroke_width), ...
                      sprintf('width="%dpx" height="%dpx" ', specifier.span(1), specifier.span(2)), ...
                      '/>', ...
                      newline, ...
                      sprintf('<use xlink:href="#%s" ', symbol_id), ... 
                      sprintf('fill="none" stroke="%s" fill-rule="evenodd" clip-rule="evenodd" ', obj.trace_stroke_foreground_colour), ...
                      sprintf('stroke-linejoin="miter" stroke-width="%gpx" ', stroke_width), ...
                      sprintf('stroke-dasharray="%g %g" ', dash_length * 2, dash_length), ...
                      sprintf('width="%dpx" height="%dpx" ', specifier.span(1), specifier.span(2)), ...
                      '/>', ...
                      newline, ...
                      '</g>', newline ...
                      ];
            
            context.target.content.text = result;
        end

        function render_layer(obj, layer, x, y, scale_factor, context, varargin)
            
            if ~isa(layer, 'geospm.validation.PresentationLayer')
                return;
            end
            
            layer_options = {...
                'blend_mode', layer.blend_mode, ...
                'opacity', layer.opacity ...
            };
            
            if isa(layer, 'geospm.validation.VolumeLayer')
                obj.render_volume(layer, x, y, scale_factor, context, varargin{:}, layer_options{:});
            elseif isa(layer, 'geospm.validation.SliceShapesLayer')
                obj.render_slice_shapes(layer, x, y, scale_factor, context, varargin{:}, layer_options{:});
            elseif isa(layer, 'geospm.validation.ImageLayer')
                obj.render_image(layer.image, x, y, scale_factor, context, varargin{:}, layer_options{:});
            elseif isa(layer, 'geospm.validation.GroupLayer')

                %obj.begin_inline_definitions(context);

                group_layer_id = ['id_' replace(char(java.util.UUID.randomUUID), '-', '')];
                
                obj.begin_group(0, 0, context, 'id', group_layer_id, 'style', sprintf('mix-blend-mode: %s; opacity: %g;', layer.blend_mode, layer.opacity));

                for index=1:numel(layer.sublayers)
                    sublayer = layer.sublayers{index};
                    obj.render_layer(sublayer, x, y, scale_factor, context, varargin{:});
                end
                
                obj.end_group(0, 0, context);

                %obj.end_inline_definitions(context);

                %context.target.content.text = [sprintf('<use xlink:href="#%s" ', group_layer_id), ... 
                %      sprintf('style="mix-blend-mode: %s; opacity: %g;" ', layer.blend_mode, layer.opacity), ...
                %      ... %sprintf('width="%dpx" ', image_width), ...
                %      ... %sprintf('height="%dpx" ', image_height), ...
                %      ... %sprintf('opacity="%g" ', layer.opacity), ...
                %      '/>' ...
                %      ];
            else
                error('Unknown layer type!')
            end
        end

        function render_layers(obj, layers, x, y, scale_function, context, varargin)
            
            for index=1:numel(layers)
                layer = layers{index};
                obj.render_layer(layer, x, y, scale_function, context, varargin{:});
            end
        end
    end
    
    methods (Access=protected)
        
        function did_render = render_shared_resource(obj, resource, context)
            
            did_render = render_shared_resource@hdng.diagrams.rendering.svg.SVGRenderer(obj, resource, context);
            
            if did_render
                return
            end

            switch resource.type
                case 'shape'
                    obj.render_shared_slice_shapes(resource, context);
                    did_render = true;
            end
        end
        
        function render_shared_slice_shapes(obj, resource, context)
            
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

            %{
            context.target.prologue.text = [...
                sprintf('<symbol id="%s" viewBox="0 0 %d %d"', symbol_id, slice_shapes.span(1), slice_shapes.span(2)), ...
                sprintf(' width="%d" height="%d"', slice_shapes.span(1), slice_shapes.span(2)), ...
                sprintf(' data-slice-index="%d"', resource.assembly.slice_index), ...
                '>', newline, ...
                paths, ...
                '</symbol>' newline
            ];
            %}
            context.target.prologue.text = [...
                sprintf('<g id="%s" ', symbol_id), ...
                '>', newline, ...
                paths, ...
                '</g>' newline
            ];
        end


        function render_image_pixels(~, resource, x, y, width, height, context)

            if ~exist('x', 'var') || isempty(x)
                x = 0;
            end

            if ~exist('y', 'var') || isempty(y)
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
            
            data = resource.assembly.image.data(y + 1:y + height, x + 1:x + width, :, :);
            
            switch class(data)
                case 'uint8'
                    factor = 2^8 - 1;
                case 'uint16'
                    factor = 2^16 - 1;
                otherwise
                    error('SVGRenderer.render_pixels_from_image(): Cannot determine bit depth.');
            end
            
            for row=1:height
                for col=1:width
                    colour = data(row, col, 1, resource.assembly.image.non_alpha_indices);
                    alpha = data(row, col, 1, resource.assembly.image.alpha_channel_index) / factor;

                    if alpha == 1
                        fill = sprintf('rgb(%d, %d, %d)', colour(1), colour(2), colour(3));
                    else
                        fill = sprintf('rgba(%d, %d, %d, %g)', colour(1), colour(2), colour(3), alpha);
                    end
                    %obj.render_rect(col, col + 1, row, row + 1, context, 'stroke', 'none', 'fill', colour);

                    rect = [sprintf('<rect x="%gpx" width="%gpx" y="%gpx" height="%gpx" stroke="none" fill="%s"/>', col - 1, 1, row - 1, 1, fill), ...
                              newline ...
                             ];

                    context.target.prologue.text = rect;
                    
                end
            end
        end

        function render_shared_image(obj, resource, context)
            
            if ~obj.render_pixels_as_rects || ~isfield(resource.assembly, 'slice_index')
               render_shared_image@hdng.diagrams.rendering.svg.SVGRenderer(obj, resource, context);
               return;
            end

            
            id = obj.generate_xmlid(resource.identifier);
            

            context.target.prologue.text = [sprintf('<g transform="translate(0 0)" id="%s">', id), newline];
            obj.render_image_pixels(resource, resource.assembly.x, resource.assembly.y, resource.assembly.width, resource.assembly.height, context);
            context.target.prologue.text = ['</g>', newline];
        end

    end

    methods (Static)
    end
end
