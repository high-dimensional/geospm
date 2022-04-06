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

classdef PatchV1 < hdng.patch.PatchImpl
    %PatchCacheImpl Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        actions
        data_file_path
    end
    
    properties (GetAccess = private, SetAccess = private)
        path_
        metadata_
        actions_
    end
    
    methods
        function obj = PatchV1(path)
            obj = obj@hdng.patch.PatchImpl();
            
            obj.path_ = path;
            obj.metadata_ = struct();
            obj.actions_ = {};
        end
        
        function result = get.data_file_path(obj)
            result = fullfile(obj.path_, 'data');
        end
        
        function result = get.actions(obj)
            result = obj.actions_;
        end
        
        function add_action(obj, action)
            obj.actions_ = [obj.actions_; {action}];
        end
        
        function apply(obj, patch)
            
            context = hdng.patch.PatchContext(patch);
            
            for i=1:numel(obj.actions_)
                action = obj.actions_{i};
                action.execute(context);
                
                if context.was_cancelled
                    break
                end
            end
        end
        
        function load(obj, patch) %#ok<INUSD>
            
            json_text = hdng.utilities.load_text(obj.data_file_path);
            proxy = jsondecode(json_text);
            
            if ~isfield(proxy, 'actions')
                return;
            end
            
            if ~iscell(proxy.actions)
                return;
            end
            
            obj.actions_ = cell(numel(proxy.actions), 1);
            
            for i=1:numel(proxy.actions)
                action = proxy.actions{i};
                obj.actions_{i} = hdng.patch.actions.PatchAction.load_from_json_proxy(action);
            end
        end
        
        
        function save(obj, patch) %#ok<INUSD>
            proxy = struct();
            proxy.actions = {};
            
            for i=1:numel(obj.actions_)
                action = obj.actions_{i};
                proxy.actions{i} = action.encode_json_proxy();
            end
            
            hdng.utilities.save_json(proxy, obj.data_file_path);
        end
    end
    
    methods (Access=protected)
        
        function result = access_path(obj)
            result = obj.path_;
        end
        
        function result = access_metadata(obj)
            result = obj.metadata_;
        end
        
    end
end
