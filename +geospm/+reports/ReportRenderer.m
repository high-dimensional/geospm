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

classdef ReportRenderer < geospm.validation.SVGRenderer
    %ReportRenderer Summary.
    %   Detailed description 
    
    properties
    end

    properties (Dependent, Transient)
    end

    properties (GetAccess=private, SetAccess=private)
    end

    methods
        
        function obj = ReportRenderer()

            obj@geospm.validation.SVGRenderer();
        end
        
        function request = create_diagram_resource_request(obj, resource, context)
            
            function request = slice_shape_request_ctor(varargin)
                request = hdng.resources.Request(varargin{:});
                request.send_delegate = @(request) obj.send_diagram_resource_request(request);
            end

            request = context.service.create_request(resource, @slice_shape_request_ctor);
        end

        function send_diagram_resource_request(~, request)

            request.request_started();
            
            warning('off', 'map:shapefile:missingDBF');

            if startsWith(lower(request.url), 'file:')
                [shapes, ~] = shaperead(request.url(6:end));
                attributes = struct.empty;
                info = shapeinfo(request.url(6:end));
            else
                shapes = struct.empty;
                attributes = struct.empty;
                info = struct.empty;
            end
            
            warning('on', 'map:shapefile:missingDBF');

            resource = request.attachments.resource;
            resource.attachments.shapes = shapes;
            resource.attachments.shape_attrs = attributes;
            resource.attachments.shape_info = info;
            
            status = request.status;
            status.stop_reason = 'completed';

            request.request_stopped(status);
        end

        function result = assemble_slice_shapes(~, resource, slice_index)
            result = struct();
            result.shapes = resource.attachments.shapes;
            result.attributes = resource.attachments.shape_attrs;
            result.info = resource.attachments.shape_info;
            result.slice_index = slice_index;

            resource.attachments = rmfield(resource.attachments, 'shapes');
            resource.attachments = rmfield(resource.attachments, 'shape_attrs');
            resource.attachments = rmfield(resource.attachments, 'shape_info');
        end
        
        function gather_resources_in_diagram_layer(obj, layer, context, resources)


            url_prefix = '';

            if isfield(context, 'host_name')
                url_prefix = context.host_name;
            end
            
            %{
            slice_name = '';

            if isfield(context, 'slice_name')
                slice_name = context.slice_name;
            end

            slice_index = layer.slice_map.index_for_name(slice_name, 1);

            path = layer.shape_paths{slice_index};
        
            [url, identifier] = obj.build_resource_url_and_identifier(url_prefix, layer.source_ref, path, context); 
        
            if ~resources.holds_key(identifier)
                resource = hdng.resources.Resource(url, 'shape');

                resource.identifier = identifier;
                %resource.is_shared = false;

                resource.delegate = hdng.one_struct( ...
                    'create_request', @(resource, context) obj.create_diagram_resource_request(resource, context), ...
                    'assemble', @(resource) obj.assemble_slice_shapes(resource, slice_index) ...
                );
        
                resource.attachments.slice_shapes = layer;
        
                resources(resource.identifier) = resource; %#ok<NASGU>
            end
            %}
        end
        
        function gather_layer_resources(obj, layer, context, resources)
            
            if isa(layer, 'geospm.reports.DiagramLayer')
                obj.gather_resources_in_diagram_layer(layer, context, resources);
                return;
            end

            gather_layer_resources@geospm.validation.SVGRenderer(obj, layer, context, resources);
        end
        
        function result = render_diagram_layer(obj, layer, context)

            result = '';

            %{
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
            %}
        end

        function result = render_layer(obj, layer, context)

            if isa(layer, 'geospm.reports.DiagramLayer')
                result = obj.render_diagram_layer(layer, context);
                return;
            end

            result = render_layer@geospm.validation.SVGRenderer(obj, layer, context);
        end

    end
    
    methods (Static, Access=public)
    end
end
