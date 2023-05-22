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

classdef Copy < hdng.patch.actions.PatchAction
    %Copy Summary goes here.
    %
    
    properties
        source_location
        destination_location
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = Copy()
            obj = obj@hdng.patch.actions.PatchAction();
            
            obj.source_location = hdng.patch.Local();
            obj.destination_location = hdng.patch.Local();
        end
        
        function execute(obj, context)
            
            source = obj.source_location.resolve_path(context.patch, false);
            
            if isempty(source)
                
                diagnostic = hdng.patch.Diagnostic.error(...
                    'Couldn''t resolve source location for %s', obj.file_name);
                
                context.cancel(diagnostic);
                return
            end
            
            destination = obj.destination_location.resolve_path(context.patch, true);
            
            if isempty(destination)
                
                diagnostic = hdng.patch.Diagnostic.error(...
                    'Couldn''t resolve destination location for %s', obj.file_name);
                
                context.cancel(diagnostic);
                return
            end
            
            copyfile(source, destination, 'f');
        end
        
        function result = encode_json_proxy(obj)
            result = encode_json_proxy@hdng.patch.actions.PatchAction(obj);
            result.type = obj.type;
            result.source_location = obj.source_location.encode_json_proxy();
            result.destination_location = obj.destination_location.encode_json_proxy();
        end
    end
    
    methods (Access = protected)
       
        function result = access_type(~)
            result = hdng.patch.actions.Copy.type();
        end
    end
    
    methods (Static)
        
        function result = type()
            result = 'copy';
        end
        
        function action = load_from_json_proxy(proxy, action)
            
            if ~exist('action', 'var')
                action = hdng.patch.actions.Copy();
            end
            
            if ~isfield(proxy, 'source_location')
                error('Copy.load_from_json_proxy(): Missing source_location field.');
            end
            
            if ~isstruct(proxy.source_location)
                error('Copy.load_from_json_proxy(): source_location field must be a char vector.');
            end
            
            action.source_location = hdng.patch.InstallLocation.load_from_json_proxy(proxy.source_location);
            
            if ~isfield(proxy, 'destination_location')
                error('Copy.load_from_json_proxy(): Missing destination_location field.');
            end
            
            if ~isstruct(proxy.destination_location)
                error('Copy.load_from_json_proxy(): destination_location field must be a char vector.');
            end
            
            action.destination_location = hdng.patch.InstallLocation.load_from_json_proxy(proxy.destination_location);
        end
    end
end
