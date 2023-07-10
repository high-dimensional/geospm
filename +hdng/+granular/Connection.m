% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2020,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef Connection < handle
    
    %Service Description to follow.
    
    properties
    end
    
    
    properties (GetAccess=public, SetAccess=private)
        url
    end

    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = Connection(url)
            obj.url = url;
        end
        
        function [source, diagnostics] = add_local_directory_source(obj, path, name)
            
            import matlab.net.*;
            import matlab.net.http.*; 
            import matlab.net.http.io.*; 
            import matlab.net.http.field.*;

            %{
            response = webwrite([obj.url '/sources/add'], ...
                'common-name', name, ...
                'common-type', 'local-directory', ...
                'local-directory-path', path);
            %}


            media_type = MediaType('application/x-www-form-urlencoded');
            headers = [ContentTypeField(media_type), AcceptField(media_type)];

            body = FormProvider( ...
                'common-name', name, ...
                'common-type', 'local-directory', ...
                'local-directory-path', path);

            request = RequestMessage(RequestMethod.POST, headers, body);

            uri = URI([obj.url '/sources/add']);
            options = HTTPOptions;
            
            diagnostics = hdng.granular.Diagnostics();
            
            http_response = request.send(uri, options);
            
            if http_response.StatusCode ~= 200
                error('hdng.granular.Connection.add_local_directory_source(): Failed with HTTP status code %d', http_response.StatusCode);
            end

            if isempty(http_response.Body.Data) || ~isa(http_response.Body.Data, 'struct')
                error('hdng.granular.Connection.add_local_directory_source(): Couldn''t parse response with content-type %s', http_response.Body.ContentType.Value);
            end
            
            api_response = http_response.Body.Data;

            if ~api_response.successful
                error('hdng.granular.Connection.add_local_directory_source(): Couldn''t create source (''%s'')', api_response.message);
            end


            source = hdng.granular.Source.from_json(api_response.source);
        end


    end
    
    methods (Access=protected)
        
    end
    
    methods (Static, Access=public)
    end
    
end
