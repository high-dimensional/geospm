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

classdef VolumeSet < dynamicprops
    
    %VolumeSet 
    %
    
    properties (GetAccess=public, SetAccess=private)
    end
    
    properties (GetAccess=public, SetAccess=public)
        file_paths
        descriptions
        optional_output_names
    end
    
    properties (Dependent, Transient)
    end
    
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = VolumeSet()
            obj.file_paths = @(~) {};
            obj.descriptions = @(~) {};
            obj.optional_output_names = {};
        end
        
        function result = locate_file_paths(obj, context)
            
            if iscell(obj.file_paths)
                result = obj.file_paths;
            elseif isa(obj.file_paths, 'function_handle')
                result = obj.file_paths(context);
            else
                error('VolumeSet.locate_file_paths(): file_paths must be a cell array of paths or a function that takes a context object as argument.');
            end
        end
        
        function result = format_descriptions(obj, context)
            
            if iscell(obj.descriptions)
                result = obj.descriptions;
            elseif isa(obj.descriptions, 'function_handle')
                result = obj.descriptions(context);
            else
                error('VolumeSet.format_descriptions(): descriptions must be a cell array of char vectors or a function that takes a context object as argument.');
            end
        end
        
        function result = select(obj, selection)
            
            result = geospm.volumes.VolumeSet();

            if ~isempty(obj.file_paths)
                result.file_paths = obj.file_paths(selection);
            end
            
            if ~isempty(obj.descriptions)
                result.descriptions = obj.descriptions(selection);
            end
            
            if ~isempty(obj.optional_output_names)
                result.optional_output_names = obj.optional_output_names(selection);
            end
        end
    end
end
