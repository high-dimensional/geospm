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

classdef Request < handle
    
    %Request [Description]
    %
    
    properties
    end
    
    properties (Dependent, Transient)
        service
        url
        credentials
        http_method
        headers
        status

        parser_callback
        send_delegate
        attachments
    end
    
    properties (GetAccess=private, SetAccess=private)
        service_
        url_
        credentials_
        http_method_
        headers_
        transfer_size_
        expected_size_
        stop_reason_
        error_message_
        http_code_

        parser_callback_
        send_delegate_
        attachments_
    end
    
    methods
        
        function obj = Request(service, url, http_method)
            
            if ~exist('url', 'var')
                url = '';
            end

            if ~exist('http_method', 'var')
                http_method = 'GET';
            end
            
            obj.service_ = service;
            obj.url_ = url;
            obj.credentials_ = [];
            obj.http_method_ = http_method;
            obj.headers_ = [];

            obj.transfer_size_ = 0;
            obj.expected_size_ = [];

            obj.stop_reason_ = [];
            obj.error_message_ = [];
            obj.http_code_ = [];

            obj.parser_callback_ = [];
            obj.send_delegate_ = [];
            obj.attachments_ = struct();
        end
        
        function result = get.service(obj)
            result = obj.service_;
        end
        
        function result = get.url(obj)
            result = obj.url_;
        end
        
        function set.url(obj, value)
            obj.url_ = value;
        end
        
        function result = get.credentials(obj)
            result = obj.credentials_;
        end

        function set.credentials(obj, value)
            obj.credentials_ = value;
        end

        function result = get.http_method(obj)
            result = obj.http_method_;
        end

        function set.http_method_(obj, value)
            obj.http_method_ = value;
        end
        
        function result = get.status(obj)
            result = obj.build_status();
        end
        
        function result = get.headers(obj)
            result = obj.headers_;
        end
        
        function result = get.parser_callback(obj)
            result = obj.parser_callback_;
        end

        function set.parser_callback(obj, value)
            obj.parser_callback_ = value;
        end

        function result = get.send_delegate(obj)
            result = obj.send_delegate_;
        end

        function set.send_delegate(obj, value)
            obj.send_delegate_ = value;
        end

        function result = get.attachments(obj)
            result = obj.attachments_;
        end
        
        function set.attachments(obj, value)
            obj.attachments_ = value;
        end
        
        function request_started(obj)
            
            obj.start_parser();

            if ~isempty(obj.service)
                obj.service.request_started(obj);
            end
        end
        
        function request_progressed(obj)
            if ~isempty(obj.service)
                obj.service.request_progressed(obj);
            end
        end
        
        function request_stopped(obj, status)
            
            if exist('status', 'var')

                obj.transfer_size_ = status.transfer_size;
                obj.expected_size_ = status.expected_size;
    
                obj.stop_reason_ = status.stop_reason;
                obj.error_message_ = status.error_message;
                obj.http_code_ = status.http_code;
            end

            obj.stop_parser();

            if ~isempty(obj.service)
                obj.service.request_stopped(obj);
            end
        end
        
        function send(obj, expected_size)
            
            if exist('expected_size', 'var')
                obj.expected_size_ = expected_size;
            else
                obj.expected_size_ = [];
            end

            obj.transfer_size_ = 0;
            obj.stop_reason_ = [];
            obj.error_message_ = [];
            obj.http_code_ = [];
            
            obj.send_impl();
        end
        
    end
    
    methods (Access=protected)

        function send_impl(obj)

            if ~isempty(obj.send_delegate)
                obj.send_delegate(obj);
                return;
            end

            obj.request_started();

            if startsWith(lower(obj.url), 'file:')
                data = hdng.utilities.load_bytes(obj.url(6:end));
            else
                data = webread(obj.url);
            end

            obj.parse_chunk(data);

            obj.stop_reason_ = 'completed';
            obj.request_stopped();
        end

        function status = build_status(obj)
            status = hdng.resources.RequestStatus(...
                obj.transfer_size_, obj.expected_size_, ...
                obj.stop_reason_, obj.error_message_, obj.http_code_);
        end

        function start_parser(~)
        end

        function parse_chunk(obj, chunk)
            if ~isempty(obj.parser_callback)
                obj.parser_callback(obj, chunk, false);
            end
        end

        function stop_parser(obj)
            if ~isempty(obj.parser_callback)
                obj.parser_callback(obj, [], true);
            end
        end
    end
    
end
