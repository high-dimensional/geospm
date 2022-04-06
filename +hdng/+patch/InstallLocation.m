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

classdef InstallLocation < handle
    %InstallLocation Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess=public, SetAccess=protected)
    end
    
    properties
    end
    
    properties (Dependent, Transient)
        type
    end
        
    methods
        
        function obj = InstallLocation()
        end
        
        function result = get.type(obj)
            result = obj.access_type();
        end
        
        function result = encode_json_proxy(~)
            result = struct();
        end
        
        function result = resolve_path(obj, patch, create) %#ok<INUSD,STOUT>
            error('InstallLocation.resolve_path() must be implemented by a subclass.');
        end
    end
    
    methods (Access=protected)
        
        function result = access_type(~) %#ok<STOUT>
            error('InstallLocation.access_type() must be implemented by a subclass.');
        end
        
    end
    
    methods (Static)
        
        function location = load_from_json_proxy(proxy)
            
            if ~isfield(proxy, 'type')
                error('InstallLocation.load_from_json_proxy(): Missing type field.');
            end
            
            type = proxy.type;
            
            if ~ischar(type)
                error('InstallLocation.load_from_json_proxy(): Type field must be a char vector.');
            end
            
            location_class = hdng.patch.InstallLocation.lookup_type(type);
            
            if isempty(location_class)
                error('InstallLocation.load_from_json_proxy(): Unknown location type %s', type);
            end
            
            load = str2func([location_class '.load_from_json_proxy']);
            location = load(proxy);
        end
    
        
        function register_type(identifier, cls)
            hdng.patch.InstallLocation.handle_types('register', identifier, cls);
        end
        
        function deregister_type(identifier)
            hdng.patch.InstallLocation.handle_types('deregister', identifier);
        end
        
        function result = lookup_type(identifier, default)
            
            if ~exist('default', 'var')
                default = [];
            end
            
            result = hdng.patch.InstallLocation.handle_types('lookup', identifier, default);
        end
    end
    
    methods (Static, Access=private)
        
        function result = handle_types(action, varargin)
            
            persistent types;
            
            if isempty(types)
                types = hdng.patch.InstallLocation.builtin_locations();
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
                    
                    error('InstallLocation.handle_types(): Unknown action %s', action);
            end
        end
        function result = builtin_locations()
            
            where = mfilename('fullpath');
            [locations_dir, ~, ~] = fileparts(where);

            files = what(locations_dir);

            result = containers.Map('KeyType', 'char', 'ValueType', 'any');

            for i=1:numel(files.m)
                class_file = fullfile(locations_dir, files.m{i});
                [~, class_name, ~] = fileparts(class_file);
                location_class_str = ['hdng.patch.' class_name];
                
                if exist(location_class_str, 'class')
                    
                    if strcmp(location_class_str, 'hdng.patch.InstallLocation')
                        continue
                    end
                    
                    if ~hdng.utilities.issubclass(location_class_str, 'hdng.patch.InstallLocation')
                        continue
                    end
                    
                    %location_class = str2func(location_class_str);
                    
                    class_type = str2func([location_class_str '.type']);
                    class_type = class_type();
                    result(class_type) = location_class_str;
                end
            end
        end
    end
end
