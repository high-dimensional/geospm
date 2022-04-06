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

classdef Builtins < hdng.experiments.ValueLoader
    
    %
    %
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=public, SetAccess=public)
    end
    
    properties (GetAccess=public, SetAccess=private)
    end
    
    properties (GetAccess=private, SetAccess=private)
        supported_types_
    end
    
    methods
        
        function obj = Builtins()
            obj = obj@hdng.experiments.ValueLoader();
            obj.supported_types_ = {
                'builtin.float', ...
                'builtin.float.symbolic', ...
                'builtin.int', ...
                'builtin.bool', ...
                'builtin.list', ...
                'builtin.dict', ...
                'builtin.struct', ...
                'builtin.null', ...
                'builtin.missing', ...
                'builtin.str', ...
                'builtin.url', ...
                'builtin.model_samples', ...
                'builtin.records', ...
                'builtin.partitioning', ...
                'builtin.file', ...
                'builtin.image_file', ...
                'builtin.volume' ...
            };
        end
        
        function [content, serialised_value] = from_serialised_value_and_type(~, serialised_value, type_identifier)
            
            if strcmp(type_identifier, 'builtin.float')
                content = serialised_value;
                return;
            end
            
            if strcmp(type_identifier, 'builtin.float.symbolic')
                
                if ~ischar(serialised_value)
                    error('hdng.experiments.Builtins.from_serialised_value_and_type(): Expected a char value for ''builtin.float.symbolic''.');
                end
                
                if strcmp(serialised_value, 'Infinity')
                    content = Inf;
                    return;
                end
                
                if strcmp(serialised_value, '-Infinity')
                    content = -Inf;
                    return;
                end
                
                if strcmp(serialised_value, 'NaN')
                    content = NaN;
                    return;
                end
                
                error('hdng.experiments.Builtins.from_serialised_value_and_type(): Unknown constant ''%s'' for ''builtin.float.symbolic''.', serialised_value);
            end
            
            if strcmp(type_identifier, 'builtin.int')
                content = cast(serialised_value, 'int64');
                serialised_value = content;
                return;
            end
            
            if strcmp(type_identifier, 'builtin.bool')
                content = cast(serialised_value, 'logical');
                serialised_value = content;
                return;
            end
            
            if strcmp(type_identifier, 'builtin.list')
                
                content = cell(numel(serialised_value), 1);
                
                for index=1:numel(serialised_value)
                    element = serialised_value{index};
                    value = hdng.experiments.decode_json_proxy(element);
                    content{index} = value.content;
                end
                
                return;
            end
            
            if strcmp(type_identifier, 'builtin.dict')
                
                content = hdng.utilities.Dictionary();
                
                keys = serialised_value.keys();
                
                for index=1:numel(keys)
                    key = keys{index};
                    value = serialised_value(key);
                    content(key) = hdng.experiments.decode_json_proxy(value);
                end
                
                return;
            end
            
            if strcmp(type_identifier, 'builtin.struct')
                
                content = struct();
                
                keys = serialised_value.keys();
                
                for index=1:numel(keys)
                    key = keys{index};
                    value = serialised_value(key);
                    content.(key) = hdng.experiments.decode_json_proxy(value);
                end
                
                return;
            end
            
            if strcmp(type_identifier, 'builtin.records')
                content = hdng.experiments.RecordArray.from_serialised_value_and_type(serialised_value, type_identifier);
                return;
            end
            
            if strcmp(type_identifier, 'builtin.partitioning')
                content = hdng.experiments.RecordArrayPartitioning.from_serialised_value_and_type(serialised_value, type_identifier);
                return;
            end
            
            if strcmp(type_identifier, 'builtin.file')
                content = hdng.experiments.FileReference.from_serialised_value_and_type(serialised_value, type_identifier);
                return;
            end
            
            
            if strcmp(type_identifier, 'builtin.image_file')
                content = hdng.experiments.ImageReference.from_serialised_value_and_type(serialised_value, type_identifier);
                return;
            end
            
            if strcmp(type_identifier, 'builtin.volume')
                content = hdng.experiments.VolumeReference.from_serialised_value_and_type(serialised_value, type_identifier);
                return;
            end
            
            if strcmp(type_identifier, 'builtin.null')
                content = [];
                return;
            end
            
            if strcmp(type_identifier, 'builtin.model_samples')
                content = geospm.validation.ModelSamples.from_serialised_value_and_type(serialised_value, type_identifier);
                return;
            end
            
            if strcmp(type_identifier, 'builtin.str')
                content = serialised_value;
                return;
            end
            
            if strcmp(type_identifier, 'builtin.url')
                content = serialised_value;
                return;
            end
            
            if strcmp(type_identifier, 'builtin.missing')
                content = [];
                return;
            end
            
            error('hdng.experiments.Builtins.from_serialised_value_and_type(): Unknown type: ''%s''.', type_identifier);
        end
    end
    
    methods (Access=protected)
        
        function result = access_supported_types(obj)
            result = obj.supported_types_;
        end
    end
    
    methods (Static, Access=public)
    end
    
end
