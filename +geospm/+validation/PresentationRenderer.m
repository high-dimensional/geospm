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

classdef PresentationRenderer < handle
    %PresentationRenderer Summary.
    %   Detailed description 
    
    properties
        host_name
        resource_identifier_expr
    end

    properties (Dependent, Transient)
    end

    properties (GetAccess=private, SetAccess=private)
    end

    methods
        
        function obj = PresentationRenderer()
            obj.host_name = '';
            obj.resource_identifier_expr = '';
        end
        
        function result = create_context_for(obj, stack, callback, render_options)
            result = render_options;
            result.callback = callback;
            result.stack = stack;

            result.host_name = obj.host_name;
            result.resource_identifier_expr = obj.resource_identifier_expr;
        end

        function requests = launch_resource_requests(~, service, resources)
            context = struct();
            context.service = service;
            
            resource_keys = resources.keys();

            requests = cell(numel(resource_keys), 1);
            request_resources = cell(numel(resource_keys), 1);
            
            for index=1:numel(resource_keys)

                key = resource_keys{index};

                resource = resources(key);
                request = resource.create_request(context);
                
                requests{index} = request;
                request_resources{index} = resource;
            end
            
            index = 1;

            function send_request(resource)
                resource.send_request(requests{index});
                index = index + 1;
            end

            cellfun(@(r) send_request(r), request_resources);
        end

        function is_done = load_resources(obj, context)
            
            service = struct();
            service.context = context;
            service.requests = obj.launch_resource_requests(service, context.resources);

            is_done = isempty(service.requests);
        end

        function result = render_shared_resources(obj, resources, render_options)
            result = '';
        end

        function result = assemble_image(~, resource)

            result = struct();
            
            result.data = cat(1, resource.loaded_chunks{:});
            
            [image_data, ~, image_transparency] = imread(resource.url);
            combined_data = cat(3, image_data, image_transparency);
            combined_data = reshape(combined_data, [size(combined_data, 1), size(combined_data, 2), 1, size(combined_data, 3)]);
            result.image = hdng.images.ImageVolume(combined_data, '', resource.url);
            result.x = 0;
            result.y = 0;
            result.height = result.image.x;
            result.width = result.image.y;
            result.slice_index = -1;
        end
        
        function identifier = create_resource_identifier_from_url(~, url, context)

            identifier = regexprep(url, '^\w+:/|^\/|\/$', '');
            
            if isfield(context, 'resource_identifier_expr') && ~isempty(context.resource_identifier_expr)
                matches = regexp(url, context.resource_identifier_expr, 'names');
                
                if numel(matches) == 1 && isfield(matches, 'identifier') && ~isempty(matches.identifier)
                    identifier = matches.identifier;
                end
            end
        end

        function gather_resources_in_image_layer(obj, layer, context, resources)

            url_prefix = '';

            if isfield(context, 'host_name')
                url_prefix = context.host_name;
            end
            
            %{
            url = join({url, layer.image.source_ref, layer.image.path}, '/');
            url = url{1};
            url = replace(url, '//', '/');
            
            identifier = obj.create_resource_identifier_from_url(url, context);
            %}
            
            [url, identifier] = obj.build_resource_url_and_identifier(url_prefix, layer.image.source_ref, layer.image.path, context); 

            if ~resources.holds_key(identifier)
                resource = hdng.resources.Resource(url, 'image');
                resource.identifier = identifier;
                resource.attachments.image_style = '';
                resources(resource.identifier) = resource; %#ok<NASGU>

                resource.delegate = hdng.one_struct( ...
                    'assemble', @(resource) obj.assemble_image(resource) ...
                );
            end
        end

        function result = compute_volume_slice_offset(~, slice_index, slice_increment, magnification)
            
            result = [];

            if isempty(slice_index)
                return;
            end

            if ~exist('magnification', 'var')
                magnification = 1;
            end

            result = -floor((slice_index - 1) * magnification * slice_increment);
        end

        function result = assemble_volume(obj, resource, layer, slice_index)

            result = obj.assemble_image(resource);

            slice_offset = obj.compute_volume_slice_offset(slice_index, layer.height, 1);
            
            result.y = -slice_offset;
            result.width = layer.width;
            result.height = layer.height;
            result.slice_index = slice_index;
        end

        function gather_resources_in_volume_layer(obj, layer, context, resources)

            url_prefix = '';

            if isfield(context, 'host_name')
                url_prefix = context.host_name;
            end

            slice_name = '';

            if isfield(context, 'slice_name')
                slice_name = context.slice_name;
            end

            slice_index = layer.slice_map.index_for_name(slice_name, 1);
            
            %{
            url = join({url, layer.image.source_ref, layer.image.path}, '/');
            url = url{1};
            url = replace(url, '//', '/');

            identifier = regexprep(layer.image.path, '^\/|\/$', '');
            %}

            [url, identifier] = obj.build_resource_url_and_identifier(url_prefix, layer.image.source_ref, layer.image.path, context); 

            if ~resources.holds_key(identifier)
                resource = hdng.resources.Resource(url, 'image');
                resource.identifier = identifier;
                %resource.is_shared = false;
                resource.attachments.image_style = 'image-rendering: crisp-edges;';
                resources(resource.identifier) = resource; %#ok<NASGU>

                resource.delegate = hdng.one_struct( ...
                    'assemble', @(resource) obj.assemble_volume(resource, layer, slice_index) ...
                );
            end
        end

        function request = create_slice_shapes_resource_request(obj, resource, context)
            
            function request = slice_shape_request_ctor(varargin)
                request = hdng.resources.Request(varargin{:});
                request.send_delegate = @(request) obj.send_slice_shapes_resource_request(request);
            end

            request = context.service.create_request(resource, @slice_shape_request_ctor);
        end

        function send_slice_shapes_resource_request(~, request)

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
        
        function gather_resources_in_slice_shapes_layer(obj, layer, context, resources)


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
            
            %{
            url = join({url, layer.source_ref, path}, '/');
            url = url{1};
            url = replace(url, '//', '/');

            identifier = regexprep(layer.shape_paths{1}, '^\/|\/$', '');
            %}

            [url, identifier] = obj.build_resource_url_and_identifier(url_prefix, layer.source_ref, path, context); 
        
            if ~resources.holds_key(identifier)
                resource = hdng.resources.Resource(url, 'shape');

                resource.identifier = identifier;
                %resource.is_shared = false;

                resource.delegate = hdng.one_struct( ...
                    'create_request', @(resource, context) obj.create_slice_shapes_resource_request(resource, context), ...
                    'assemble', @(resource) obj.assemble_slice_shapes(resource, slice_index) ...
                );
        
                resource.attachments.slice_shapes = layer;
        
                resources(resource.identifier) = resource; %#ok<NASGU>
            end
        end

        function gather_layer_resources(obj, layers, context, resources)
            
            for index=1:numel(layers)
                layer = layers{index};

                if ~isa(layer, 'geospm.validation.PresentationLayer')
                    continue;
                end

                if isa(layer, 'geospm.validation.VolumeLayer')
                    obj.gather_resources_in_volume_layer(layer, context, resources);
                elseif isa(layer, 'geospm.validation.SliceShapesLayer')
                    obj.gather_resources_in_slice_shapes_layer(layer, context, resources);
                elseif isa(layer, 'geospm.validation.ImageLayer')
                    obj.gather_resources_in_image_layer(layer, context, resources);
                else
                    error('Unknown layer type!')
                end
            end
        end
    end
    
    methods (Static, Access=public)
        
        function [url, identifier] = build_resource_url_and_identifier(url_prefix, source_ref, path, context)
            
            if ~exist('context', 'var')
                context = struct();
            end

            url = fullfile(url_prefix, source_ref, path);
            url = replace(url, '//', '/');

            identifier = regexprep(path, '^\w+:/|^\/|\/$', '');
            
            if isfield(context, 'resource_identifier_expr') && ~isempty(context.resource_identifier_expr)
                matches = regexp(url, context.resource_identifier_expr, 'names');
                
                if numel(matches) == 1 && isfield(matches, 'identifier') && ~isempty(matches.identifier)
                    identifier = matches.identifier;
                end
            end
        end
    end
end
