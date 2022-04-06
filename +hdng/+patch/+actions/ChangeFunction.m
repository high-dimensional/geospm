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

classdef ChangeFunction < hdng.patch.actions.PatchAction
    %ChangeFunction Summary goes here.
    %
    
    properties

        file_name
        file_location
        
        install_location
        
        function_name
        
        match_arguments
        match_return_values
        
        body_text
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = ChangeFunction()
            obj = obj@hdng.patch.actions.PatchAction();
            
            obj.file_name = '';
            obj.file_location = hdng.patch.Local();
            
            obj.function_name = '';
            obj.match_arguments = {};
            obj.match_return_values = {};
            
            obj.body_text = '';
            
            obj.install_location = hdng.patch.Local();
            obj.install_location.path = 'files';
            
        end
        
        function execute(obj, context)
            
            
            file_at = obj.file_location.resolve_path(context.patch, true);
            
            if isempty(file_at)
                
                diagnostic = hdng.patch.Diagnostic.error(...
                    'Couldn''t resolve file location for %s', obj.file_name);
                
                context.cancel(diagnostic);
                return
            end
            
            file_at = fullfile(file_at, obj.file_name);
            
            source_file = hdng.patch.SourceFile();
            source_file.parse(file_at);
            F = source_file.match_function(obj.function_name, obj.match_arguments, obj.match_return_values);
            
            if isempty(F)
                return
            end
            
            F.body_text = obj.body_text;
            
            install_at = obj.install_location.resolve_path(context.patch, true);
            
            if isempty(install_at)
                
                diagnostic = hdng.patch.Diagnostic.error(...
                    'Couldn''t resolve install location for %s', source_file.name);
                
                context.cancel(diagnostic);
                return
            end
            
            source_file.write(install_at);
        end
        
        function result = encode_json_proxy(obj)
            result = encode_json_proxy@hdng.patch.actions.PatchAction(obj);
            result.type = obj.type;
            
            result.file_name = obj.file_name;
            result.file_location = obj.file_location.encode_json_proxy();
            
            result.function_name = obj.function_name;
            result.match_arguments = obj.match_arguments;
            result.match_return_values = obj.match_return_values;
            result.body_text = obj.body_text;
            result.install_location = obj.install_location.encode_json_proxy();
        end
    end
    
    methods (Access = protected)
       
        function result = access_type(~)
            result = hdng.patch.actions.ChangeFunction.type();
        end
        
        function result = access_required_path(~)
            result = 'is_required.m';
        end
        
    end
    
    methods (Static)
        
        function result = type()
            result = 'change-function';
        end
        
        function action = load_from_json_proxy(proxy, action)
            
            if ~exist('action', 'var')
                action = hdng.patch.actions.ChangeFunction();
            end
            
            if ~isfield(proxy, 'file_name')
                error('ChangeFunction.load_from_json_proxy(): Missing file_name field.');
            end
            
            if ~ischar(proxy.file_name)
                error('ChangeFunction.load_from_json_proxy(): file_name field must be a char vector.');
            end
            
            action.file_name = proxy.file_name;
            
            
            if ~isfield(proxy, 'file_location')
                error('ChangeFunction.load_from_json_proxy(): Missing file_location field.');
            end
            
            if ~isstruct(proxy.file_location)
                error('ChangeFunction.load_from_json_proxy(): file_location field must be a struct.');
            end
           
            action.file_location = hdng.patch.InstallLocation.load_from_json_proxy(proxy.file_location);
            
            
            if ~isfield(proxy, 'function_name')
                error('ChangeFunction.load_from_json_proxy(): Missing function_name field.');
            end
            
            if ~ischar(proxy.function_name)
                error('ChangeFunction.load_from_json_proxy(): function_name field must be a char vector.');
            end
            
            action.function_name = proxy.function_name;
            
            if ~isfield(proxy, 'match_arguments')
                action.match_arguments = {};
            else
                if isnumeric(proxy.match_arguments)
                    action.match_arguments = proxy.match_arguments;
                elseif iscell(proxy.match_arguments)
                    action.match_arguments = cell(numel(proxy.match_arguments));
                    
                    for i=1:numel(proxy.match_arguments)
                        match_argument = proxy.match_arguments{i};
                        
                        if ~ischar(match_argument)
                            error('ChangeFunction.load_from_json_proxy(): Elements of match_arguments field must char vectors.');
                        end
                        
                        action.match_arguments{i} = match_argument;
                    end
                else
                    error('ChangeFunction.load_from_json_proxy(): Unexpected type for match_arguments field.');
                end
            end
            
            if ~isfield(proxy, 'match_return_values')
                action.match_return_values = {};
            else
                if isnumeric(proxy.match_return_values)
                    action.match_return_values = proxy.match_return_values;
                elseif iscell(proxy.match_return_values)
                    action.match_return_values = cell(numel(proxy.match_return_values));
                    
                    for i=1:numel(proxy.match_return_values)
                        match_return_value = proxy.match_return_values{i};
                        
                        if ~ischar(match_return_value)
                            error('ChangeFunction.load_from_json_proxy(): Elements of match_return_values field must char vectors.');
                        end
                        
                        action.match_return_values{i} = match_return_value;
                    end
                else
                    error('ChangeFunction.load_from_json_proxy(): Unexpected type for match_return_values field.');
                end
            end
            
            if ~isfield(proxy, 'body_text')
                error('ChangeFunction.load_from_json_proxy(): Missing body_text field.');
            end
            
            if ~ischar(proxy.body_text)
                error('ChangeFunction.load_from_json_proxy(): body_text field must be a char vector.');
            end
            
            action.body_text = proxy.body_text;
            
            
            if ~isfield(proxy, 'install_location')
                error('ChangeFunction.load_from_json_proxy(): Missing install_location field.');
            end
            
            if ~isstruct(proxy.install_location)
                error('ChangeFunction.load_from_json_proxy(): install_location field must be a struct.');
            end
           
            action.install_location = hdng.patch.InstallLocation.load_from_json_proxy(proxy.install_location);
        end
    end
end
