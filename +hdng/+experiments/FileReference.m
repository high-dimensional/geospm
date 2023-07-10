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

classdef FileReference < hdng.experiments.ValueContent
    %FileReference Summary.
    %   Detailed description 
    
    properties
        path
        source_ref
    end
    
    methods
        
        function obj = FileReference(path, source_ref)
            obj = obj@hdng.experiments.ValueContent();
            
            if ~exist('path', 'var')
                path = '';
            end

            if ~exist('source_ref', 'var')
                source_ref = '';
            end
            
            obj.path = path;
            obj.source_ref = source_ref;
        end
        
        function result = resolve_path_relative_to(obj, base_path)
            
            if ~startsWith(obj.path, filesep)
                result = fullfile(base_path, obj.path);
            else
                result = obj.path;
            end
        end

        function [serialised_value, type_identifier] = as_serialised_value_and_type(obj)
            serialised_value = containers.Map('KeyType', 'char', 'ValueType', 'any');
            serialised_value('path') = obj.path;
            serialised_value('source_ref') = obj.source_ref;
            type_identifier = 'builtin.file';
        end
        
        function result = label_for_content(obj)
        	result = obj.path;
        end
    end
    
    
    methods (Static)
        
        function result = from_serialised_value_and_type(serialised_value, type_identifier) %#ok<INUSD>
            
            if ~isa(serialised_value, 'containers.Map')
                error('hdng.experiments.FileReference.from_serialised_value_and_type(): Expected serialised value to be a containers.Map instance.');
            end
            
            if ~isKey(serialised_value, 'path')
                error('hdng.experiments.FileReference.from_serialised_value_and_type(): Expected ''path'' field.');
            end
            
            if ~isKey(serialised_value, 'source_ref')
                error('hdng.experiments.FileReference.from_serialised_value_and_type(): Expected ''source_ref'' field.');
            end
            
            path = serialised_value('path');
            
            if ~ischar(path)
                error('hdng.experiments.FileReference.from_serialised_value_and_type(): Expected ''path'' field to be of type char.');
            end
            
            source_ref = serialised_value('source_ref');
            
            if ~ischar(source_ref)
                error('hdng.experiments.FileReference.from_serialised_value_and_type(): Expected ''source_ref'' field to be of type char.');
            end
            
            result = hdng.experiments.FileReference(path, source_ref);
        end
    end
end
