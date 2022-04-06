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

classdef FileIntercept < hdng.patch.actions.PatchAction
    %FileIntercept Summary goes here.
    %
    
    properties
        file_name
        file_location
        intercept_location
        variables
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = FileIntercept()
            obj = obj@hdng.patch.actions.PatchAction();
            
            obj.file_name = '';
            obj.file_location = hdng.patch.Local();
            obj.intercept_location = hdng.patch.Local();
            obj.variables = struct();
        end
        
        function execute(obj, context)
            
            intercept = hdng.patch.Template();
            
            directory = fileparts(mfilename('fullpath'));
            intercept.parse(fullfile(directory, 'intercept_template.txt'));
            
            intercept_at = obj.intercept_location.resolve_path(context.patch, true);
            
            if isempty(intercept_at)
                
                diagnostic = hdng.patch.Diagnostic.error(...
                    'Couldn''t resolve intercept location for %s', obj.file_name);
                
                context.cancel(diagnostic);
                return
            end
            
            intercept.write(obj.variables, intercept_at, obj.file_name, '');
        end
        
        function result = encode_json_proxy(obj)
            result = encode_json_proxy@hdng.patch.actions.PatchAction(obj);
            result.type = obj.type;
            result.file_name = obj.file_name;
            result.file_location = obj.file_location.encode_json_proxy();
            result.intercept_location = obj.intercept_location.encode_json_proxy();
            result.variables = obj.variables;
        end
    end
    
    methods (Access = protected)
       
        function result = access_type(~)
            result = hdng.patch.actions.FileIntercept.type();
        end
    end
    
    methods (Static)
        
        function result = type()
            result = 'file-intercept';
        end
        
        function action = load_from_json_proxy(proxy, action)
            
            if ~exist('action', 'var')
                action = hdng.patch.actions.FileIntercept();
            end
            
            if ~isfield(proxy, 'file_name')
                error('FileIntercept.load_from_json_proxy(): Missing file_name field.');
            end
            
            if ~ischar(proxy.file_name)
                error('FileIntercept.load_from_json_proxy(): file_name field must be a char vector.');
            end
            
            action.file_name = proxy.file_name;
            
            if ~isfield(proxy, 'file_location')
                error('FileIntercept.load_from_json_proxy(): Missing file_location field.');
            end
            
            if ~isstruct(proxy.file_location)
                error('FileIntercept.load_from_json_proxy(): file_location field must be a char vector.');
            end
            
            action.file_location = hdng.patch.InstallLocation.load_from_json_proxy(proxy.file_location);
            
            if ~isfield(proxy, 'intercept_location')
                error('FileIntercept.load_from_json_proxy(): Missing intercept_location field.');
            end
            
            if ~isstruct(proxy.intercept_location)
                error('FileIntercept.load_from_json_proxy(): intercept_location field must be a char vector.');
            end
            
            action.intercept_location = hdng.patch.InstallLocation.load_from_json_proxy(proxy.intercept_location);
            
            if ~isfield(proxy, 'variables')
                error('FileIntercept.load_from_json_proxy(): Missing variables field.');
            end
            
            if ~isstruct(proxy.variables)
                error('FileIntercept.load_from_json_proxy(): variables field must be a char vector.');
            end
            
            action.variables = proxy.variables;
        end
    end
end
