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

classdef WriteRelease < hdng.patch.actions.PatchAction
    %WriteRelease Summary goes here.
    %
    
    properties
        filename
        destination_location
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = WriteRelease()
            obj = obj@hdng.patch.actions.PatchAction();
            obj.filename = 'release';
            obj.destination_location = hdng.patch.Local();
        end
        
        function execute(obj, context)
            
            destination = obj.destination_location.resolve_path(context.patch, true);
            
            if isempty(destination)
                
                diagnostic = hdng.patch.Diagnostic.error(...
                    'Couldn''t resolve destination location for %s', obj.file_name);
                
                context.cancel(diagnostic);
                return
            end
            
            release_value = version('-release');
            hdng.utilities.save_text(release_value, ...
                fullfile(destination, obj.filename));
        end
        
        function result = encode_json_proxy(obj)
            result = encode_json_proxy@hdng.patch.actions.PatchAction(obj);
            result.type = obj.type;
            result.filename = obj.filename;
            result.destination_location = obj.destination_location.encode_json_proxy();
        end
    end
    
    methods (Access = protected)
       
        function result = access_type(~)
            result = hdng.patch.actions.WriteRelease.type();
        end
    end
    
    methods (Static)
        
        function result = type()
            result = 'write_release';
        end
        
        function action = load_from_json_proxy(proxy, action)
            
            if ~exist('action', 'var')
                action = hdng.patch.actions.WriteRelease();
            end
            
            if ~isfield(proxy, 'filename')
                error('WriteRelease.load_from_json_proxy(): Missing filename field.');
            end
            
            if ~ischar(proxy.filename)
                error('WriteRelease.load_from_json_proxy(): filename field must be a char vector.');
            end
            
            action.filename = proxy.filename;
            
            if ~isfield(proxy, 'destination_location')
                error('WriteRelease.load_from_json_proxy(): Missing destination_location field.');
            end
            
            if ~isstruct(proxy.destination_location)
                error('WriteRelease.load_from_json_proxy(): destination_location field must be a struct.');
            end
            
            action.destination_location = hdng.patch.InstallLocation.load_from_json_proxy(proxy.destination_location);
        end
    end
end
