% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2021,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef RecordArray < hdng.experiments.ValueContent
    
    %RecordArray Holds a collection of records.
    %
    
    properties
        attachments
    end
    
    properties (Dependent, Transient)
        length
        attributes
        attribute_names
        attribute_map
        records
        unsorted_records
    end
    
    properties (GetAccess=private, SetAccess=private)
        records_
        value_indices_
        
        attributes_
    end
    
    methods
        
        function obj = RecordArray()
            obj = obj@hdng.experiments.ValueContent();
            
            obj.records_ = hdng.utilities.OrderedMap('KeyType', 'char', 'ValueType', 'any');
            obj.value_indices_ = hdng.utilities.OrderedMap('KeyType', 'char', 'ValueType', 'any');
            
            obj.attributes_ = hdng.experiments.RecordAttributeMap();
            
            obj.attachments = struct();
        end
        
        function result = get.length(obj)
            result = 0; 
            
            record_keys = keys(obj.records_);
            
            for index=1:numel(record_keys)
            
                key = record_keys{index};
                entry = obj.records_(key);
                result = result + numel(entry.records);
            end
        end
        
        function result = get.attributes(obj)
            result = obj.attributes_.attributes;
        end
        
        function result = get.attribute_names(obj)
            result = obj.attributes_.names;
        end
        
        function result = get.attribute_map(obj)
            result = obj.attributes_;
        end
        
        function result = get.records(obj)
            result = {}; 
            
            record_keys = keys(obj.records_);
            
            for index=1:numel(record_keys)
            
                key = record_keys{index};
                entry = obj.records_(key);
            
                result = [result; entry.records]; %#ok<AGROW>
            end
        end
        
        function result = get.unsorted_records(obj)
            result = {}; 
            
            record_keys = keys(obj.records_);
            
            for index=1:numel(record_keys)
            
                key = record_keys{index};
                entry = obj.records_(key);
            
                result = [result; entry.records]; %#ok<AGROW>
            end
        end
        
        function result = has_attribute(obj, name)
            
            result = obj.attributes_.has_attribute(name);
        end
        
        function result = attribute_for_name(obj, name)
            
            result = obj.attributes_.attribute_for_name(name);
        end
        
        function result = value_index_for_name(obj, name, do_create)
            
            if ~exist('do_create', 'var')
                do_create = false;
            end
            
            result = hdng.experiments.RecordValueIndex.empty;
            
            if ~isKey(obj.value_indices_, name)
                
                if do_create
                    
                    if ~isKey(obj.value_indices_, name)
                        result = hdng.experiments.RecordValueIndex(name);
                        obj.value_indices_(name) = result;
                    end
                end
                
                return
            end
            
            result = obj.value_indices_(name);
        end
        
        function include_record(obj, record)
            
            if ~isa(record, 'hdng.utilities.Dictionary')
                error('RecordArray.include_record() expects a hdng.utilities.Dictionary as record but got: %s', class(record));
            end
            
            key = obj.key_for_record(record);
            
            if ~isKey(obj.records_, key)
                entry = hdng.experiments.RecordArrayEntry(key);
                obj.records_(key) = entry;
            else
                entry = obj.records_(key);
            end
            
            if ~entry.include_record(record)
                return
            end
            
            keys = record.keys();
            
            for index=1:numel(keys)
                
                key = keys{index};
                
                if ~obj.has_attribute(key)
                    obj.define_attribute(key, true, false);
                end
                
                if ~isKey(obj.value_indices_, key)
                    value_index = hdng.experiments.RecordValueIndex(key);
                    obj.value_indices_(key) = value_index;
                else
                    value_index = obj.value_indices_(key);
                end
                
                value_index.include_record(record);
            end
            
        end
        
        function exclude_record(obj, record)
            
            if ~isa(record, 'hdng.utilities.Dictionary')
                error('RecordArray.include_record() expects a hdng.utilities.Dictionary as record but got: %s', class(record));
            end
            
            key = obj.key_for_record(record);
            
            if ~isKey(obj.records_, key)
                return
            end
            
            entry = obj.records_(key);
            
            if ~entry.exclude_record(record)
                return
            end
            
            keys = record.keys();
            
            for index=1:numel(keys)
                
                key = keys{index};
                
                if isKey(obj.value_indices_, key)
                    value_index = obj.value_indices_(key);
                    value_index.exclude_record(record);

                    if value_index.is_empty
                        remove(obj.value_indices_, key);
                    end
                    
                    attribute = obj.attribute_for_name(key);
                    
                    if ~isempty(attribute)

                        if value_index.is_empty && ~attribute.is_persistent
                            obj.attributes_.remove(key);
                        end
                    end
                end
            end
            
            
        end
        
        function result = define_attribute(obj, identifier, create_if_missing, is_persistent)
            
            if ~exist('create_if_missing', 'var')
                create_if_missing = true;
            end
            
            if ~exist('is_persistent', 'var')
                is_persistent = true;
            end
            
            result = obj.attributes_.define(identifier, create_if_missing, is_persistent);
        end
        
        function result = key_for_record(~, record)
            
            result = [];
            
            keys = sort(record.keys());
            
            for index=1:numel(keys)
                
                key = keys{index};
                value = record(key);
                
                if ~isa(value, 'hdng.experiments.Value')
                    error('RecordArray.key_for_record() expected all values in record to be of hdng.experiments.Value.');
                end
                
                result = [result, unicode2native(key, 'UTF-8'), value.digest_bytes(:)']; %#ok<AGROW>
            end
            
            result = hdng.experiments.RecordArray.compute_md5_of_bytes(result);
        end
        
        
        function [serialised_value, type_identifier] = as_serialised_value_and_type(obj)
            
            format = hdng.experiments.JSONFormat();
            value_index_for_name = @(name) obj.value_index_for_name(name, true);
            serialised_value = format.build_proxy_from_records(obj.records, obj.attributes_, obj.attachments, value_index_for_name);
            type_identifier = 'builtin.records';
        end
        
        function result = label_for_content(obj)
            
            result = sprintf('%d records with fields {', obj.length);
            
            names = obj.attribute_names;
            
            for index=1:numel(names)
                name = names{index};
                
                if index == 1
                    result = [result name]; %#ok<AGROW>
                else
                    result = [result ', ' name]; %#ok<AGROW>
                end
            end
            
            result = [result '}'];
        end
        
        function result = contains_record(obj, record)
            
            result = false;
            
            if ~isa(record, 'hdng.utilities.Dictionary')
                error('RecordArray.contains_record() expects a hdng.utilities.Dictionary as record but got: %s', class(record));
            end
            
            key = obj.key_for_record(record);
            
            if ~isKey(obj.records_, key)
                return;
            else
                entry = obj.records_(key);
            end
            
            result = entry.contains_record(record);
        end
        
        function result = select(obj, match_value_struct)
            
            result = hdng.experiments.RecordArray();
            names = fieldnames(match_value_struct);
            
            for index=1:numel(names)
                name = names{index};
                
                value_index = obj.value_index_for_name(name);

                if isempty(value_index)
                    return;
                end
            end
            
            for index=1:numel(names)
                name = names{index};
                
                if index == 1
                    
                    value_index = obj.value_index_for_name(name);
                    
                    value = match_value_struct.(name);
                    value_records = value_index.records_for_value(value);
                
                    for r_index=1:numel(value_records)
                        result.include_record(value_records{r_index});
                    end
                    
                else
                    
                    value = match_value_struct.(name);
                    result_records = result.unsorted_records;
                    
                    for r_index=1:numel(result_records)
                        record = result_records{r_index};
                        
                        if ~record.holds_key(name)
                            result.exclude_record(record);
                            continue;
                        end
                        
                        if ~(record(name) == value)
                            result.exclude_record(record);
                            continue;
                        end
                    end
                end
            end
        end
        
        function define_partitioning_attachment(obj, attribute_specifiers)
            
            result = hdng.experiments.RecordArrayPartitioning();
            
            for index=1:numel(attribute_specifiers)
                
                specifier = attribute_specifiers{index};
                
                if ~isstruct(specifier)
                    error('RecordArray.define_partitioning_attachment(): Attribute specifiers are expected to be structures.');
                end
                
                if ~isfield(specifier, 'identifier')
                    error('RecordArray.define_partitioning_attachment(): Attribute specifier is missing ''identifier'' field.');
                end
                
                if ~isfield(specifier, 'category')
                    error('RecordArray.define_partitioning_attachment(): Attribute specifier is missing ''category'' field.');
                end
                
                result.define_attribute(specifier.identifier, specifier.category);
                
                if ~isfield(specifier, 'order')
                    specifier.order = index;
                end
                
                result.update_attribute(specifier.identifier, specifier);
            end
            
            obj.attachments.partitioning = result;
        end
        
        function result = get_partitioning_attachment(obj, default)
            
            if ~exist('default', 'var')
                default = hdng.experiments.RecordArrayPartitioning.empty;
            end
            
            if ~isfield(obj.attachments, 'partitioning')
                result = default;
            else
                result = obj.attachments.partitioning;
            end
        end
        
        function result = format(obj)
            
            result = '';
            all_records = obj.records;
            
            for r_index=1:numel(all_records)
                record = all_records{r_index};
                keys = record.keys();
                
                result = [result sprintf('[%d]\n', r_index)]; %#ok<AGROW>
                
                for k_index=1:numel(keys)
                    key = keys{k_index};
                    value = record(key);
                    result = [result sprintf('    %s: %s\n', key, value.label)]; %#ok<AGROW>
                end
            end
            
        end
    end
    
    methods (Static)
        
        function result = from_serialised_value_and_type(serialised_value, type_identifier) %#ok<INUSD>
            
            result = hdng.experiments.RecordArray();
            
            format = hdng.experiments.JSONFormat();
            format.build_records_from_proxy(serialised_value, result);
            
        end
        
    end
    
    methods (Static, Access=protected)

        function hash = compute_md5_of_bytes(bytes)
            persistent md

            if isempty(md)
                md = java.security.MessageDigest.getInstance('MD5');
            end

            %bytes = uint8(string);
            %bytes = unicode2native(string, 'UTF-8');

            hash = sprintf('%2.2x', typecast(md.digest(bytes), 'uint8')');
        end
    
    end
end
