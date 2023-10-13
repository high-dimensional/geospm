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

classdef ResourceService < handle
    
    %ResourceService [Description]
    %
    
    properties
    end
    
    properties (Dependent, Transient)
        total_requests
        stopped_requests
        completed_requests
        delegate
    end
    
    properties (GetAccess=private, SetAccess=private)
        total_requests_
        stopped_requests_
        completed_requests_
        delegate_
    end
    
    methods
        
        function obj = ResourceService()
            obj.total_requests_ = 0;
            obj.stopped_requests_ = 0;
            obj.completed_requests_ = 0;
            obj.delegate_ = [];
        end
        
        function result = get.total_requests(obj)
            result = obj.total_requests_;
        end
        
        function result = get.stopped_requests(obj)
            result = obj.stopped_requests_;
        end
        
        function result = get.completed_requests(obj)
            result = obj.completed_requests_;
        end

        function result = get.delegate(obj)
            result = obj.delegate_;
        end
        
        function set.delegate(obj, value)
            obj.delegate_ = value;
        end
        
        function update_idle_status(obj)
            if obj.total_requests_ == obj.stopped_requests_
                obj.call_delegate('service_idle', obj);
            end
        end

        function request_started(obj, request)
            obj.total_requests_ = obj.total_requests_ + 1;
        end

        function request_progressed(~, request)
        end

        function request_stopped(obj, request)

            obj.stopped_requests_ = obj.stopped_requests_ + 1;
            
            status = request.status;
            resource = request.attachments.resource;

            if strcmp(status.stop_reason, 'completed')
                obj.completed_requests_ = obj.completed_requests_ + 1;
                resource.assemble();
                resource.loaded();
            else
                resource.failed();
            end

            obj.update_idle_status();
        end

        function request = create_request(obj, resource, request_ctor)
            
            if ~exist('request_ctor', 'var')
                request_ctor = @(varargin) hdng.resources.Request(varargin{:});
            end

            request = request_ctor(obj, resource.url);
            request.attachments.resource = resource;
            
            function append_chunk(chunk)
                resource.loaded_chunks{end + 1} = chunk;
            end
            
            request.parser_callback = @(request, chunk, is_last) ...
                append_chunk(chunk);
        end
    end
    
    methods (Access=protected)
        function [did_delegate, delegate_result] = call_delegate(obj, method, varargin)
            
            did_delegate = false;
            delegate_result = [];

            if isempty(obj.delegate)
                return;
            end
            
            did_delegate = true;
            delegate_result = obj.delegate.(method)(obj, varargin{:});
        end
    end
    
    methods (Static, Access=public)
    end
    
end
