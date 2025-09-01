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
    end

    properties (Dependent, Transient)
    end

    properties (GetAccess=private, SetAccess=private)
    end

    methods
        
        function obj = ResourceManager()
            obj.host_name = '';
            obj.resource_identifier_expr = '';
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

        function identifier = create_resource_identifier_from_url(~, url, context)

            identifier = regexprep(url, '^\w+:/|^\/|\/$', '');
            
            if isfield(context, 'resource_identifier_expr') && ~isempty(context.resource_identifier_expr)
                matches = regexp(url, context.resource_identifier_expr, 'names');
                
                if numel(matches) == 1 && isfield(matches, 'identifier') && ~isempty(matches.identifier)
                    identifier = matches.identifier;
                end
            end
        end


        function result = assemble_image(~, resource)

            result = struct();
            
            result.data = cat(1, resource.loaded_chunks{:});
            
            [image_data, ~, image_transparency] = imread(resource.url);
            combined_data = cat(3, image_data, image_transparency);
            combined_data = reshape(combined_data, [size(combined_data, 1), size(combined_data, 2), 1, size(combined_data, 3)]);
            
            result.image_data = combined_data;
            result.url = resource.url;
            result.x = 0;
            result.y = 0;
            result.height = result.image.x;
            result.width = result.image.y;
        end
        
        function gather_image_resource(obj, image, context, resources)

            url_prefix = '';

            if isfield(context, 'host_name')
                url_prefix = context.host_name;
            end
            
            [url, identifier] = obj.build_resource_url_and_identifier(url_prefix, image.source_ref, image.path, context); 

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
        
        function gather_file_resource(obj, file, context, resources)


            url_prefix = '';

            if isfield(context, 'host_name')
                url_prefix = context.host_name;
            end

            [url, identifier] = obj.build_resource_url_and_identifier(url_prefix, file.source_ref, file.path, context); 
        
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
