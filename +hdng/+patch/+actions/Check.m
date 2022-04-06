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

classdef Check < hdng.patch.actions.PatchAction
    %Check Summary goes here.
    %
    
    properties
        function_path
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = Check()
            obj = obj@hdng.patch.actions.PatchAction();
            
            obj.function_path = '';
        end
        
        function execute(obj, context)
            
            required_path = hdng.utilities.make_absolute_path(obj.function_path, context.patch.path);
            script = hdng.utilities.load_text(required_path);
            
            tmp_path = tempname;

            [dirstatus, dirmsg] = mkdir(tmp_path);
            if dirstatus ~= 1; error(dirmsg); end
            
            tmp_function_path = [tempname(tmp_path) '.m'];
            [~, required_function, ~] = fileparts(tmp_function_path);
            %check_function = ['function result = check(patch)' newline obj.script newline 'end' newline];
            hdng.utilities.save_text(script, tmp_function_path);
            
            old_path = cd(tmp_path);
            result = feval(required_function, context.patch);
            cd(old_path);
            
            hdng.utilities.delete(false, tmp_function_path);
            rmdir(tmp_path);
            
            if ~result
                context.cancel();
            end
        end
        
        function result = encode_json_proxy(obj)
            result = encode_json_proxy@hdng.patch.actions.PatchAction(obj);
            result.type = obj.type;
            result.function_path = obj.function_path;
        end
    end
    
    methods (Access = protected)
       
        function result = access_type(~)
            result = hdng.patch.actions.Check.type();
        end
        
    end
    
    methods (Static)
        
        function result = type()
            result = 'check';
        end
        
        function action = load_from_json_proxy(proxy, action)
            
            if ~exist('action', 'var')
                action = hdng.patch.actions.Check();
            end
            
            if ~isfield(proxy, 'function_path')
                error('ChangeFunction.load_from_json_proxy(): Missing function_path field.');
            end
            
            if ~ischar(proxy.function_path)
                error('ChangeFunction.load_from_json_proxy(): function_path field must be a char vector.');
            end
            
            action.function_path = proxy.function_path;
        end
    end
end
