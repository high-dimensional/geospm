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

classdef RecordArrayPartitioning < hdng.experiments.ValueContent
    %RecordArrayPartitoning Summary.
    %   Detailed description 
    
    properties (Constant)
        
        VIEW_MODE_DEFAULT = 'default'
        VIEW_MODE_SELECT = 'select'
        
        CATEGORY_PARTITIONING = 'partitioning'
        CATEGORY_CONTENT = 'content'
    end
    
    
    properties (Dependent, Transient)
        partitioning_attributes
        content_attributes
        partitioning_identifiers
        content_identifiers
    end
    
    properties (GetAccess=private, SetAccess=private)
        attributes_
    end
    
    methods
        
        function obj = RecordArrayPartitioning()
            
            obj = obj@hdng.experiments.ValueContent();
            
            obj.attributes_ = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end
        
        function result = get.partitioning_attributes(obj)
            result = obj.get_attributes(obj.CATEGORY_PARTITIONING);
        end
        
        function result = get.content_attributes(obj)
            result = obj.get_attributes(obj.CATEGORY_CONTENT);
        end
        
        function result = get.partitioning_identifiers(obj)
            attributes = obj.partitioning_attributes;
            result = cell(numel(attributes), 1);
            
            for index=1:numel(attributes)
                result{index} = attributes{index}.identifier;
            end
        end
        
        function result = get.content_identifiers(obj)
            attributes = obj.content_attributes;
            result = cell(numel(attributes), 1);
            
            for index=1:numel(attributes)
                result{index} = attributes{index}.identifier;
            end
        end
        
        function result = label_for_content(~)
        	result = 'Record Array Partitioning';
        end
        
        function result = define_attribute(obj, identifier, category)
            
            if ~isKey(obj.attributes_, identifier)
                result = obj.create_attribute(identifier, category);
                result.order = obj.attributes_.length;
                obj.attributes_(identifier) = result;
            else
                result = obj.attributes_(identifier);
            end
        end
        
        function result = clear_attribute(obj, identifier)
            
            if isKey(obj.attributes_, identifier)
                remove(obj.attributes_, identifier);
                result = true;
            else
                result = false;
            end
        end
        
        function attribute = update_attribute(obj, identifier, varargin)
            
            if ~isKey(obj.attributes_, identifier)
                error('RecordArrayPartitioning.update_attribute(): No attribute with identifier ''%s'' is defined.', attribute.identifier);
            end
            
            attribute = obj.attributes_(identifier);
            
            if nargin == 3 && isstruct(varargin{1})
                update = varargin{1};
            else
                update = hdng.utilities.parse_struct_from_varargin(varargin{:});
            end
            
            keys = fieldnames(update);
            
            for index=1:numel(keys)
                key = keys{index};
                
                if strcmp(key, 'identifier')
                    if ~strcmp(attribute.identifier, update.identifier)
                        warning('RecordArrayPartitioning.update_attribute(): The identifier field cannot be updated.');
                    end
                    continue
                end
                
                if strcmp(key, 'category')
                    if ~strcmp(attribute.category, update.category)
                        warning('RecordArrayPartitioning.update_attribute(): The category field cannot be updated.');
                    end
                    
                    continue
                end
                
                attribute.(key) = update.(key);
            end
            
            obj.attributes_(identifier) = attribute;
        end
        
        function [serialised_value, type_identifier] = as_serialised_value_and_type(obj)
            
            serialised_value = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            serialised_value('attributes') = obj.attributes_;
            type_identifier = 'builtin.partitioning';
        end
        
    end
    
    methods (Static)
        
        function result = from_serialised_value_and_type(serialised_value, type_identifier) %#ok<INUSD>
            
            if ~isa(serialised_value, 'containers.Map')
                error('hdng.experiments.RecordArrayPartitioning.from_serialised_value_and_type(): Expected serialised value to be a containers.Map instance.');
            end
            
            result = hdng.experiments.RecordArrayPartitioning();
            
            if ~isKey(serialised_value, 'attributes')
                error('hdng.experiments.RecordArrayPartitioning.from_serialised_value_and_type(): Expected ''attributes'' field.');
            end
            
            attributes = serialised_value('attributes');
            
            if ~isa(attributes, 'containers.Map')
                error('hdng.experiments.RecordArrayPartitioning.from_serialised_value_and_type(): Expected ''attributes'' field to be a containers.Map instance.');
            end
            
            keys = attributes.keys();
            
            for index=1:numel(keys)
                key = keys{index};
                attribute_map = attributes(key);
                
                if ~isa(attribute_map, 'containers.Map')
                    error('hdng.experiments.RecordArrayPartitioning.from_serialised_value_and_type(): Expected attribute definition to be a containers.Map instance.');
                end
                
                if ~isKey(attribute_map, 'identifier')
                    error('hdng.experiments.RecordArrayPartitioning.from_serialised_value_and_type(): Expected attribute definition to have a ''identifier'' field.');
                end
                
                if ~isKey(attribute_map, 'category')
                    error('hdng.experiments.RecordArrayPartitioning.from_serialised_value_and_type(): Expected attribute definition to have a ''category'' field.');
                end
                
                attribute = result.define_attribute(attribute_map('identifier'), attribute_map('category'));
                
                attribute_keys = attribute_map.keys();
                
                for i=1:numel(attribute_keys)
                    attribute_key = attribute_keys{i};
                    
                    if strcmp(attribute_key, 'identifier') || strcmp(attribute_key, 'category')
                        continue
                    end
                    
                    attribute.(attribute_key) = attribute_map(attribute_key);
                end
                
                result.update_attribute(attribute.identifier, attribute);
            end
            
            %warning('hdng.experiments.RecordArrayPartitioning.from_serialised_value_and_type() Not yet implemented');
        end
    end
    
    methods (Access=protected)
        
        function result = get_attributes(obj, category)
            
            if ~exist('category', 'var')
                category = [];
            end
            
            result = {};
            keys = obj.attributes_.keys();
            
            for index=1:numel(keys)
                identifier = keys{index};
                attribute = obj.attributes_(identifier);
                
                if isempty(category) || strcmp(attribute.category, category)
                    result{end + 1} = attribute; %#ok<AGROW>
                end
            end
        end
        
        function result = create_attribute(~, identifier, category)
            result = struct();
            result.identifier = identifier;
            result.category = category;
            result.view_mode = 'default';
            result.order = 0;
        end
        
    end
    
end
