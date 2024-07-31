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

classdef Value < hdng.experiments.ValueDirective
    
    %Value Encapsulates a value, its label and its serialisation.
    %
    
    properties
    end
    
    properties (Dependent, Transient)
        digest_bytes
        is_null
    end
    
    properties (GetAccess=public, SetAccess=public)
        content
    end
    
    properties (GetAccess=public, SetAccess=private)
        type_identifier
        serialised
        digest
        label
    end
    
    methods
        
        function obj = Value(type_identifier, serialised, digest, label)
            obj = obj@hdng.experiments.ValueDirective();
            obj.type_identifier = type_identifier;
            obj.serialised = serialised;
            obj.digest = digest;
            obj.label = label;
            obj.content = [];
        end
        
        function result = get.digest_bytes(obj)
            result = cast(sscanf(obj.digest, '%2lx'), 'uint8');
        end
        
        function result = get.is_null(obj)
            result = strcmp(obj.type_identifier, 'builtin.null');
        end
        
        function result = eq(obj, other)
            
            result = false;
            
            if ~isa(other, 'hdng.experiments.Value')
                return
            end
            
            if obj.digest ~= other.digest
                return
            end
            
            if ~strcmp(obj.type_identifier, other.type_identifier)
                return
            end
            
            if strcmp(obj.type_identifier, 'builtin.list')
                result = isequaln(obj.content, other.content);
                return
            end
            
            if strcmp(obj.type_identifier, 'builtin.struct')
                result = isequaln(obj.content, other.content);
                return
            end
            
            if strcmp(obj.type_identifier, 'builtin.dict')
                
                if obj.content.length ~= other.content.length
                    return
                end
                
                keys = obj.content.keys();
                
                for index=1:numel(keys)
                    
                    key = keys{index};
                    
                    if ~other.content.holds_key(key)
                        return
                    end
                    
                    if ~(isequaln(obj.content(key), other.content(key)))
                        return
                    end
                end
                
                result = true;
                return
            end
            
            if strcmp(obj.type_identifier, 'builtin.missing')
                result = strcmp(obj.label, other.label);
                return
            end
            
            result = isequaln(obj.content, other.content);
        end
        
        function result = as_dictionary(obj)
            
            result = hdng.utilities.Dictionary();
            result('content_digest') = obj.digest;
            result('content_type') = obj.type_identifier;
            result('content') = obj.serialised;
            result('label') = obj.label;
        end
        
        function result = as_map(obj)
            
            result = containers.Map('KeyType', 'char', 'ValueType', 'any');
            result('content_digest') = obj.digest;
            result('content_type') = obj.type_identifier;
            result('content') = obj.serialised;
            result('label') = obj.label;
        end

        function result = unpack(obj, with)

            if ~exist('with', 'var') || isempty(with)
                with = hdng.experiments.Builtins();
            end
            
            result = with.from_serialised_value_and_type(obj.serialised, obj.type_identifier);
        end
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)

        function value = from(content, label, serialised, content_type)
            
            if ~exist('label', 'var')
                label = hdng.experiments.label_for_content(content);
            end
            
            if ~exist('serialised', 'var')
                [digest, serialised, type_identifier] = hdng.experiments.compute_digest(content);
            else
                [digest, serialised, type_identifier] = hdng.experiments.compute_digest(content, serialised, content_type);
            end
            
            value = hdng.experiments.Value(type_identifier, serialised, digest, label);
            value.content = content;
        end

        function value = empty_with_label(label)
            
            [digest, serialised, type_identifier] = hdng.experiments.compute_digest([], [], 'builtin.null');
            
            value = hdng.experiments.Value(type_identifier, serialised, digest, label);
        end
        
        function result = load_from_proxy(argument)
            

            if ~isKey(argument, 'content')
                error('hdng.experiments.Value.load(): Missing ''content'' key.');
            end
            
            serialised_value = argument('content');
            
            if ~isKey(argument, 'content_type')
                error('hdng.experiments.Value.load(): Missing ''content_type'' key.');
            end
            
            type_identifier = argument('content_type');
            
            if isKey(argument, 'label')
                label = argument('label');
            else
                label = '';
            end
            
            if isKey(argument, 'content_digest')
                content_digest = argument('content_digest');
            else
                content_digest = [];
            end
            
            persistent content_type_map;
            
            if isempty(content_type_map)
                
                content_type_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
                
                builtins = hdng.experiments.Builtins();
                
                for index=1:numel(builtins.supported_types)
                    supported_type = builtins.supported_types{index};
                    content_type_map(supported_type) = builtins;
                end
            end
            
            if ~isKey(content_type_map, type_identifier)
                error('hdng.experiments.Value.load_from_proxy(): Unsupported type ''%s''.', type_identifier);
            end
            
            loader = content_type_map(type_identifier);
            [content, serialised_value] = loader(serialised_value, type_identifier);
            
            if isempty(content_digest)
                content_digest = hdng.experiments.compute_digest(content, serialised_value, type_identifier);
            end
            
            result = hdng.experiments.Value(type_identifier, serialised_value, content_digest, label);
            result.content = content;
        end
    end
    
end
