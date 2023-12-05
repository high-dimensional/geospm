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

classdef Resource < handle
    
    %Resource [Description]
    %
    
    properties
    end
    
    properties (Dependent, Transient)
        url
        identifier
        is_shared
        type
        loaded_chunks
        assembly
        stop_reason
        callback
        delegate
        error
        attachments
    end
    
    properties (GetAccess=private, SetAccess=private)
        url_
        identifier_
        is_shared_
        type_
        loaded_chunks_
        assembly_
        stop_reason_
        callback_
        delegate_
        error_
        attachments_
    end
    
    methods
        
        function obj = Resource(url, type)


            obj.url_ = url;
            obj.identifier_= '';
            obj.is_shared_ = true;
            obj.type_ = type;
            obj.loaded_chunks_ = {};
            obj.assembly_ = [];
            obj.stop_reason_ = [];
            obj.delegate_ = [];
            obj.callback_ = [];
            obj.error_ = [];

            obj.attachments_ = struct();
        end
        
        function result = get.url(obj)
            result = obj.url_;
        end
        
        function set.url(obj, value)
            obj.url_ = value;
        end

        function result = get.identifier(obj)
            result = obj.identifier_;
        end

        function set.identifier(obj, value)
            obj.identifier_ = value;
        end

        function result = get.is_shared(obj)
            result = obj.is_shared_;
        end

        function set.is_shared(obj, value)
            obj.is_shared_ = value;
        end
        
        function result = get.type(obj)
            result = obj.type_;
        end
        
        function result = get.loaded_chunks(obj)
            result = obj.loaded_chunks_;
        end

        function set.loaded_chunks(obj, value)
            obj.loaded_chunks_ = value;
        end

        function result = get.assembly(obj)
            result = obj.assembly_;
        end
        
        function result = get.stop_reason(obj)
            result = obj.stop_reason_;
        end
        
        function set.stop_reason(obj, value)
            obj.stop_reason_ = value;

            if ~isempty(obj.callback)
                obj.callback(obj);
            end
        end
        
        function result = get.delegate(obj)
            result = obj.delegate_;
        end
        
        function set.delegate(obj, value)
            obj.delegate_ = value;
        end
        
        function result = get.callback(obj)
            result = obj.callback_;
        end
        
        function set.callback(obj, value)
            obj.callback_ = value;
        end
        
        
        function result = get.error(obj)
            result = obj.error_;
        end
        
        function set.error(obj, value)
            obj.error_ = value;
        end
        
        function result = get.attachments(obj)
            result = obj.attachments_;
        end
        
        function set.attachments(obj, value)
            obj.attachments_ = value;
        end
        
        function loaded(obj)
            obj.stop_reason = 'completed';
        end

        function failed(obj)
            obj.stop_reason = 'failed';
        end

        function request = create_request(obj, context)
            
            [did_delegate, request] = obj.call_delegate('create_request', context);
            
            if did_delegate
                return
            end

            request = context.service.create_request(obj);
        end

        function send_request(obj, request)
            
            did_delegate = obj.call_delegate('send_request', request);
            
            if did_delegate
                return
            end

            request.send();
        end
        
        function assemble(obj)
            
            [did_delegate, obj.assembly_] = obj.call_delegate('assemble');
            
            if did_delegate
                return
            end

            obj.assembly_ = cat(1, obj.loaded_chunks{:}); 
        end
        
    end
    
    methods (Access=protected)
        function [did_delegate, delegate_result] = call_delegate(obj, method, varargin)
            
            did_delegate = false;
            delegate_result = [];

            if isempty(obj.delegate) || ~isfield(obj.delegate, method)
                return;
            end
            
            did_delegate = true;
            delegate_result = obj.delegate.(method)(obj, varargin{:});
        end
    end
    
    methods (Static, Access=public)
    end
    
end
