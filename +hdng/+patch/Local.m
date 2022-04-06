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

classdef Local < hdng.patch.InstallLocation
    %InstallLocation Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        path
    end
    
    properties (Dependent, Transient)
    end
        
    methods
        
        function obj = Local()
            obj = obj@hdng.patch.InstallLocation();
            obj.path = '';
        end
        
        function result = encode_json_proxy(obj)
            result = encode_json_proxy@hdng.patch.InstallLocation(obj);
            result.type = obj.type;
            result.path = obj.path;
        end
        
        function result = resolve_path(obj, patch, create)
            result = hdng.utilities.make_absolute_path(obj.path, patch.path);
            
            if create
                [dirstatus, dirmsg] = mkdir(result);
                if dirstatus ~= 1; error(dirmsg); end
            end
        end
    end
    
    methods (Access=protected)
        
        function result = access_type(~)
            result = hdng.patch.Local.type();
        end
        
    end
    
    methods (Static)
        
        function result = type()
            result = 'local';
        end
        
        function location = load_from_json_proxy(proxy, location)
            
            if ~exist('location', 'var')
                location = hdng.patch.Local();
            end
            
            if ~isfield(proxy, 'path')
                error('Local.load_from_json_proxy(): Missing path field.');
            end
            
            if ~ischar(proxy.path)
                error('Local.load_from_json_proxy(): path field must be a char vector.');
            end
            
            location.path = proxy.path;
            
        end
    end
end
