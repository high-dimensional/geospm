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
                      sprintf('stroke-line-join="miter" stroke-width="%gpx" ', stroke_width), ...
                      sprintf('width="%dpx" height="%dpx" ', specifier.span(1), specifier.span(2)), ...
                      '/>', ...
                      newline, ...
                      sprintf('<use xlink:href="#%s" ', symbol_id), ... 
                      sprintf('fill="none" stroke="%s" fill-rule="evenodd" clip-rule="evenodd" ', obj.trace_stroke_foreground_colour), ...
                      sprintf('stroke-line-join="miter" stroke-width="%gpx" ', stroke_width), ...
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

                obj.begin_inline_definitions(context);

                group_layer_id = replace(char(java.util.UUID.randomUUID), '-', '');
                
                obj.begin_group(0, 0, context, 'id', group_layer_id);

                for index=1:numel(layer.sublayers)
                    sublayer = layer.sublayers{index};
                    obj.render_layer(sublayer, x, y, scale_factor, context, varargin{:});
                end
                
                obj.end_group(0, 0, context);

                obj.end_inline_definitions(context);

                context.target.content.text = [sprintf('<use xlink:href="#%s" ', group_layer_id), ... 
                      sprintf('style="mix-blend-mode: %s;" ', 'multiply'), ...
                      ... %sprintf('width="%dpx" ', image_width), ...
                      ... %sprintf('height="%dpx" ', image_height), ...
                      ... %sprintf('opacity="%g" ', render_options.opacity), ...
                      '/>' ...
                      ];
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

    end

    methods (Static)
    end
end
