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

classdef ReportResourceManager < hdng.resources.ResourceManager

    %ReportResourceManager Summary.
    %   Detailed description 
    
    properties
        slice_name
    end

    properties (Dependent, Transient)
    end

    properties (GetAccess=private, SetAccess=private)
    end

    methods
        
        function obj = ReportResourceManager()
            obj = obj@hdng.resources.ResourceManager();

            obj.slice_name = '';
        end
        
        function gather_resources_in_volume(obj, volume, resources)

            url_prefix = obj.host_name;

            path =  obj.resolve_path_alias(volume.image.path);

            [url, identifier] = obj.build_resource_url_and_identifier(...
                url_prefix, volume.image.source_ref, path); 

            slice_index = volume.slice_map.index_for_name(obj.slice_name, 1);
            
            if ~resources.holds_key(identifier)
                resource = hdng.resources.Resource(url, 'image');
                resource.identifier = identifier;
                %resource.is_shared = false;
                %resource.attachments.image_style = 'image-rendering: crisp-edges;';
                resource.attachments.image_style = 'image-rendering: pixelated;';
                resources(resource.identifier) = resource; %#ok<NASGU>

                resource.delegate = hdng.one_struct( ...
                    'assemble', @(resource) obj.assemble_volume(resource, volume, slice_index) ...
                );
            end
        end        

        function gather_resources_in_slice_shapes(obj, slice_shapes, resources)


            url_prefix = obj.host_name;

            slice_index = slice_shapes.slice_map.index_for_name(obj.slice_name, 1);
            path = slice_shapes.shape_paths{slice_index};
            
            path =  obj.resolve_path_alias(path);
            
            [url, identifier] = obj.build_resource_url_and_identifier(...
                url_prefix, slice_shapes.source_ref, path); 

            if ~resources.holds_key(identifier)
                resource = hdng.resources.Resource(url, 'shape');

                resource.identifier = identifier;
                %resource.is_shared = false;

                resource.delegate = hdng.one_struct( ...
                    'create_request', @(resource, context) obj.create_slice_shapes_resource_request(resource, context), ...
                    'assemble', @(resource) obj.assemble_slice_shapes(resource, slice_index) ...
                );
        
                resource.attachments.slice_shapes = slice_shapes;
        
                resources(resource.identifier) = resource; %#ok<NASGU>
            end
        end
    end
    
    methods (Access=protected)

        
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

        function result = assemble_volume(obj, resource, volume, slice_index)

            result = obj.assemble_image(resource);

            slice_offset = obj.compute_volume_slice_offset(slice_index, volume.height, 1);
            
            result.y = -slice_offset;
            result.width = volume.width;
            result.height = volume.height;
            result.slice_index = slice_index;
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
    end
end
