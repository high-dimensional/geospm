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

classdef PatchAction < handle
    %PatchAction Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        type
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = PatchAction()
        end
        
        function result = get.type(obj)
            result = obj.access_type();
        end
        
        function execute(obj, context) %#ok<INUSD>
        end
        
        function result = encode_json_proxy(~)
            result = struct();
        end
        
    end
    
    methods (Access = protected)
       
        function result = access_type(~) %#ok<STOUT>
            error('PatchAction.access_type() must be implemented by a subclass.');
        end
    end
    
    methods (Static)
        
        function action = load_from_json_proxy(proxy)
            
            if ~isfield(proxy, 'type')
                error('PatchAction.load_from_json_proxy(): Missing type field.');
            end
            
            type = proxy.type;
            
            if ~ischar(type)
                error('PatchAction.load_from_json_proxy(): Type field must be a char vector.');
            end
            
            action_class = hdng.patch.actions.PatchAction.lookup_type(type);
            
            if isempty(action_class)
                error('PatchAction.load_from_json_proxy(): Unknown action type %s', type);
            end
            
            load = str2func([action_class '.load_from_json_proxy']);
            action = load(proxy);
        end
    
        
        function register_type(identifier, cls)
            hdng.patch.actions.PatchAction.handle_types('register', identifier, cls);
        end
        
        function deregister_type(identifier)
            hdng.patch.actions.PatchAction.handle_types('deregister', identifier);
        end
        
        function result = lookup_type(identifier, default)
            
            if ~exist('default', 'var')
                default = [];
            end
            
            result = hdng.patch.actions.PatchAction.handle_types('lookup', identifier, default);
        end
    end
    
    methods (Static, Access=private)
        
        function result = handle_types(action, varargin)
            
            persistent types;
            
            if isempty(types)
                types = hdng.patch.actions.PatchAction.builtin_actions();
            end
            
            result = [];
            
            switch action
                
                case 'register'
                    
                    types(varargin{1}) = varargin{2};
                    
                case 'deregister'
                    
                    if ~isKey(types, varargin{1})
                        return;
                    end
                    
                    types.remove(varargin{1});
                    
                case 'lookup'
                    
                    
                    if ~isKey(types, varargin{1})
                        result = varargin{2};
                        return;
                    end
                    
                    result = types(varargin{1});
                    
                otherwise
                    
                    error('PatchAction.handle_types(): Unknown action %s', action);
            end
        end
        
        function result = builtin_actions()
            
            where = mfilename('fullpath');
            [actions_dir, ~, ~] = fileparts(where);

            files = what(actions_dir);

            result = containers.Map('KeyType', 'char','ValueType', 'any');

            for i=1:numel(files.m)
                class_file = fullfile(actions_dir, files.m{i});
                [~, class_name, ~] = fileparts(class_file);
                action_class_str = ['hdng.patch.actions.' class_name];

                if exist(action_class_str, 'class')
                    
                    if strcmp(action_class_str, 'hdng.patch.actions.PatchAction')
                        continue
                    end
                    
                    if ~hdng.utilities.issubclass(action_class_str, 'hdng.patch.actions.PatchAction')
                        continue
                    end
                    
                    %action_class = str2func(action_class_str);
                    class_type = str2func([action_class_str '.type']);
                    class_type = class_type();
                    result(class_type) = action_class_str;
                end
            end
        end
    end
end
