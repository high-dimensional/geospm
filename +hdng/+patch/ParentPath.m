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

classdef ParentPath < hdng.patch.InstallLocation
    %ParentPath Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        path
    end
    
    properties (Dependent, Transient)
    end
        
    methods
        
        function obj = ParentPath()
            obj = obj@hdng.patch.InstallLocation();
            obj.path = '';
        end
        
        function result = encode_json_proxy(obj)
            result = encode_json_proxy@hdng.patch.InstallLocation(obj);
            result.type = obj.type;
            result.path = obj.path;
        end
        
        function result = resolve_path(obj, patch, create)
            
            result = '';
            directory = patch.path;
            parts = split(obj.path, {filesep});
            
            if isempty(parts{1})
                parts = parts(2:end);
            end
            
            directory_name = parts{1};
            destination_path = join(parts(2:end), filesep);
            destination_path = destination_path{1};
            
            while true
            
                [parent_directory, match_candidate, ext] = fileparts(directory);
                match_candidate = [match_candidate, ext]; %#ok<AGROW>

                if isempty(directory) || strcmp(parent_directory, directory)
                    break;
                end
                
                if strcmp(directory_name, match_candidate)
                    result = join({directory, destination_path}, filesep);
                    result = result{1};
                    
                    if create
                        [dirstatus, dirmsg] = mkdir(result);
                        if dirstatus ~= 1; error(dirmsg); end
                    end
                    
                    return;
                end
                
                directory = parent_directory;
            end
        end
    end
    
    methods (Access=protected)
        
        function result = access_type(~)
            result = hdng.patch.ParentPath.type();
        end
        
    end
    
    methods (Static)
        
        function result = type()
            result = 'parent';
        end
        
        function location = load_from_json_proxy(proxy, location)
            
            if ~exist('location', 'var')
                location = hdng.patch.ParentPath();
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
