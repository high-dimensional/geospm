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

classdef ResourceManager < handle

    %ResourceManager Summary.
    %   Detailed description 
    
    properties
        host_name
        resource_identifier_expr
        path_aliases
    end

    properties (Dependent, Transient)
    end

    properties (GetAccess=private, SetAccess=private)
    end

    methods
        
        function obj = ResourceManager()
            obj.host_name = '';
            obj.resource_identifier_expr = '';
            obj.path_aliases = containers.Map('KeyType', 'char', 'ValueType', 'char');
        end

        function path = resolve_path_alias(obj, path)
            if obj.path_aliases.isKey(path)
                path = obj.path_aliases(path);
            end
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
            
            function send_request(index)
                r_resource = request_resources{index};
                r_resource.send_request(requests{index});
            end

            arrayfun(@(r) send_request(r), 1:numel(request_resources));
        end
        
        function gather_resources_in_image(obj, image, resources)

            url_prefix = obj.host_name;

            path =  obj.resolve_path_alias(image.path);
            
            [url, identifier] = obj.build_resource_url_and_identifier(...
                url_prefix, image.source_ref, path); 

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

        function gather_resources_in_file(obj, file, resources)
            
            url_prefix = obj.host_name;

            path =  obj.resolve_path_alias(file.path);

            [url, identifier] = obj.build_resource_url_and_identifier(...
                url_prefix, file.source_ref, path); 

            if ~resources.holds_key(identifier)
                resource = hdng.resources.Resource(url, 'file');

                resource.identifier = identifier;
                %resource.is_shared = false;

                resource.delegate = hdng.one_struct( ...
                    'create_request', @(resource, context) obj.create_file_resource_request(resource, context), ...
                    'assemble', @(resource) obj.assemble_file(resource) ...
                );
        
                resource.attachments.file_type = file.type;
        
                resources(resource.identifier) = resource; %#ok<NASGU>
            end
        end
        
        function result = load_resources(obj, callback_fn, resources, varargin)
        
            result = [];

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'service')
                options.service = hdng.resources.ResourceService();
            end

            if isnumeric(resources) && isempty(resources)
                resources = hdng.utilities.Dictionary();
            end

            service = options.service;
            
            requests = obj.launch_resource_requests(...
                service, resources); %#ok<NASGU>
            

            % Not running asynchronously, so all requests should have stopped
            if service.total_requests == service.stopped_requests
                result = callback_fn(obj, service);
            end
            
            % Explicitly clear all requests

            requests = []; %#ok<NASGU>
        end

        function [url, identifier] = build_resource_url_and_identifier(obj, url_prefix, source_ref, path, varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'resource_identifier_expr')
                options.resource_identifier_expr = obj.resource_identifier_expr;
            end

            url = fullfile(url_prefix, source_ref, path);
            url = replace(url, '//', '/');

            identifier = regexprep(path, '^\w+:/|^\/|\/$', '');
            
            if ~isempty(options.resource_identifier_expr)
                matches = regexp(path, options.resource_identifier_expr, 'names');
                
                if numel(matches) == 1 && isfield(matches, 'identifier') && ~isempty(matches.identifier)
                    identifier = matches.identifier;
    
                    if isfield(matches, 'prefix') && ~isempty(matches.prefix)
                        identifier = [matches.prefix identifier];
                    end
                end
            end
        end
    end

    methods (Access=protected)
        

        function result = assemble_image(~, resource)

            result = struct();
            
            result.data = cat(1, resource.loaded_chunks{:});
            
            [image_data, ~, image_transparency] = imread(resource.url);
            combined_data = cat(3, image_data, image_transparency);
            combined_data = reshape(combined_data, [size(combined_data, 1), size(combined_data, 2), 1, size(combined_data, 3)]);
            
            result.image_data = combined_data;
            result.image = hdng.images.ImageVolume(combined_data, '', resource.url);
            result.url = resource.url;
            result.x = 0;
            result.y = 0;
            result.height = result.image.x;
            result.width = result.image.y;
        end
        

        function request = create_file_resource_request(obj, resource, context)
            
            function request = file_request_ctor(varargin)
                request = hdng.resources.Request(varargin{:});
                request.send_delegate = @(request) obj.send_file_resource_request(request);
            end

            request = context.service.create_request(resource, @file_request_ctor);
        end

        function send_file_resource_request(~, request)

            request.request_started();
            
            resource = request.attachments.resource;

            if startsWith(lower(request.url), 'file:')
                path = request.url(6:end);
                
                switch resource.attachments.file_type
                    case 'binary'
                        contents = hdng.utilities.load_bytes(path);
                    case 'json'
                        contents = hdng.utilities.load_json(path);
                    case 'text'
                        contents = hdng.utilities.load_text(path);
                    otherwise
                        contents = [];
                end
            else
                contents = [];
            end
            
            resource.attachments.file_contents = contents;
            
            status = request.status;
            status.stop_reason = 'completed';

            request.request_stopped(status);
        end

        function result = assemble_file(~, resource)
            result = struct();
            result.contents = resource.attachments.file_contents;
            result.type = resource.attachments.file_type;

            resource.attachments = rmfield(resource.attachments, 'file_contents');
            resource.attachments = rmfield(resource.attachments, 'file_type');
        end
    end
end
