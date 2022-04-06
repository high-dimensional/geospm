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

classdef WhichContainer < hdng.patch.InstallLocation
    %WhichContainer Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        which_item
        local_path
    end
    
    properties (Dependent, Transient)
    end
        
    methods
        
        function obj = WhichContainer()
            obj = obj@hdng.patch.InstallLocation();
            obj.which_item = '';
            obj.local_path = '';
        end
        
        function result = encode_json_proxy(obj)
            result = encode_json_proxy@hdng.patch.InstallLocation(obj);
            result.type = obj.type;
            result.which_item = obj.which_item;
            result.local_path = obj.local_path;
        end
        
        function result = resolve_path(obj, patch, create) %#ok<INUSL>
            
            
            result = '';
            which_path = which(obj.which_item);
            
            if isempty(which_path)
                return;
            end
            
            [which_path, ~, ~] = fileparts(which_path);
            
            result = fullfile(which_path, obj.local_path);
            
            if create
                [dirstatus, dirmsg] = mkdir(result);
                if dirstatus ~= 1; error(dirmsg); end
            end
        end
    end
    
    methods (Access=protected)
        
        function result = access_type(~)
            result = hdng.patch.WhichContainer.type();
        end
        
    end
    
    methods (Static)
        
        function result = type()
            result = 'which';
        end
        
        function location = load_from_json_proxy(proxy, location)
            
            if ~exist('location', 'var')
                location = hdng.patch.WhichContainer();
            end
            
            if ~isfield(proxy, 'which_item')
                error('Local.load_from_json_proxy(): Missing which_item field.');
            end
            
            if ~ischar(proxy.which_item)
                error('Local.load_from_json_proxy(): which_item field must be a char vector.');
            end
            
            location.which_item = proxy.which_item;
            
            if ~isfield(proxy, 'local_path')
                error('Local.load_from_json_proxy(): Missing local_path field.');
            end
            
            if ~ischar(proxy.local_path)
                error('Local.load_from_json_proxy(): local_path field must be a char vector.');
            end
            
            location.local_path = proxy.local_path;
            
        end
    end
end
