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

classdef JSONFormat < handle
    
    %JSONFormat Encapsulates a method of generating stages in a study.
    %
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = JSONFormat()
        end
        
        function decode(obj, bytes, options, records)

            if ~exist('records', 'var') || isempty(records)
                records = hdng.utilities.RecordArray();
            end
            
            if ~isfield(options, 'compression')
                options.compression = false;
            end
            if ~isfield(options, 'base64')
                options.base64 = false;
            end
            
            if options.compression
                
                if options.base64
                    text = native2unicode(bytes, 'UTF-8');
                    bytes = matlab.net.base64decode(text);
                end
                
                text = hdng.utilities.decompress_text(bytes);
            else
                text = native2unicode(bytes, 'UTF-8');
            end
            
            proxy = hdng.utilities.decode_json(text);
            obj.build_records_from_proxy(proxy, records);
        end
        
        function bytes = encode(obj, records, record_attributes, attachments, value_index_for_name, options)
            
            if ~exist('options', 'var') || isempty(options)
                options = struct();
            end
            
            if ~isfield(options, 'compression')
                options.compression = false;
            end
            if ~isfield(options, 'base64')
                options.base64 = false;
            end
            
            proxy = obj.build_proxy_from_records(records, record_attributes, attachments, value_index_for_name);
            text = hdng.utilities.encode_json(proxy);
            
            if options.compression
                bytes = hdng.utilities.compress_text(text);

                if options.base64
                    text = matlab.net.base64encode(bytes);
                    bytes = unicode2native(text, 'UTF-8');
                end
            else
                bytes = unicode2native(text, 'UTF-8');
            end
        end
        
        function descriptor = build_proxy_from_records(obj, record_list, metadata_map, attachments, value_index_for_name)
            
            if ~exist('metadata_map', 'var') || isempty(metadata_map)
                metadata_map = hdng.experiments.RecordAttributeMap();
            end
            
            if ~exist('attachments', 'var')
                attachments = struct();
            end
            
            attachment_names = fieldnames(attachments);
            
            for index=1:numel(attachment_names)
                name = attachment_names{index};
                attachment = attachments.(name);
                attachment = hdng.experiments.Value.from(attachment);
                attachments.(name) = attachment.as_map();
            end
            
            records = hdng.experiments.RecordArray();
            
            for index=1:numel(record_list)
                record = record_list{index};
                records.include_record(record);
            end
            
            if ~exist('value_index_for_name', 'var') || isempty(value_index_for_name)
                value_index_for_name = @(name) records.value_index_for_name(name, true);
            end
            
            descriptor = containers.Map('KeyType', 'char', 'ValueType', 'any');
            descriptor('version')= 1;
            descriptor('record_count') = records.length;
            descriptor('attachments') = attachments;
            
            record_attributes = records.attributes;
            
            attributes = cell(numel(record_attributes), 1);
            attribute_values = cell(numel(record_attributes), 1);
            
            for index=1:numel(record_attributes)
                
                attribute = record_attributes{index};

                json_attribute = containers.Map('KeyType', 'char', 'ValueType', 'any');
                json_attribute('identifier') = attribute.identifier;
                json_attribute('interactive') = struct();
                
                metadata = metadata_map.attribute_for_name(attribute.identifier);
                
                if ~isempty(metadata)
                    
                    if isfield(metadata.attachments, 'interactive')
                        json_attribute('interactive') = metadata.attachments.interactive;
                    end

                    if ischar(metadata.description) && numel(metadata.description) > 0
                        json_attribute('label') = metadata.description;
                    end

                    if isa(metadata.description, 'hdng.experiments.Description')
                        json_attribute('label') = metadata.description.label;
                    end
                end
                
                attributes{index} = json_attribute;

                values = obj.proxy_encode_attribute_values(records, attribute.identifier, value_index_for_name);
                attribute_values{index} = values;
            end
            
            descriptor('attributes') = attributes;
            descriptor('attribute_values') = attribute_values;
        end
        
        function result = proxy_encode_attribute_values(obj, array, identifier, value_index_for_name)
            
            indirect = obj.proxy_index_attribute_values(array, identifier, value_index_for_name);
            direct = obj.proxy_gather_attribute_values(array, identifier);
            
            indirect_size = numel(hdng.utilities.encode_json(indirect));
            direct_size = indirect_size * 2; %numel(hdng.utilities.encode_json(direct));
            
            if direct_size < indirect_size
                result = direct;
            else
                result = indirect;
            end
        end
        
        function result = proxy_gather_attribute_values(~, array, identifier)
            
            records = array.records;
            result = cell(numel(records), 1);
            
            %missing_value = hdng.experiments.Value.empty_with_label('not defined');
            
            for index=1:numel(records)
                
                record = records{index};
                value = record(identifier);
                
                if isa(value, 'hdng.utilities.DictionaryError')
                    result{index} = missing;
                    continue;
                end
                
                result{index} = value.as_map();
            end
        end
        
        function result = proxy_index_attribute_values(obj, array, identifier, value_index_for_name) %#ok<INUSL>
            
            value_index = value_index_for_name(identifier);
            values = value_index.values;
            
            serialised_values = cell(numel(values) + 1, 1);
            serialised_values{1} = missing;
            
            for index=1:numel(values)
                
                value = values{index};
                
                serialised_values{index + 1} = value.as_map();
                entry = value_index.entry_for_value(value);
                attachments = entry.attachments_for_value(value);
                attachments('json_index') = index; %#ok<NASGU>
            end
            
            records = array.records;
            indices = zeros(numel(records), 1, 'int64');
            
            for index=1:numel(records)
                
                record = records{index};
                value = record(identifier);
                
                if isa(value, 'hdng.utilities.DictionaryError')
                    indices(index) = 0;
                    continue;
                end
                
                entry = value_index.entry_for_value(value);
                attachments = entry.attachments_for_value(value);
                indices(index) = attachments('json_index');
            end
            
            result = containers.Map('KeyType', 'char', 'ValueType', 'any');
            result('values') = serialised_values;
            result('indices') = num2cell(indices);
        end


        function build_records_from_proxy(obj, proxy, records)
            
            if ~isa(proxy, 'containers.Map')
                error('JSONFormat.build_records_from_proxy(): Proxy must be a containers.Map instance.');
            end

            if ~isKey(proxy, 'version')
                error('JSONFormat.build_records_from_proxy(): Missing ''version'' field.');
            end

            version = proxy('version');
            
            if version ~= 1
                error('JSONFormat.build_records_from_proxy(): Unsupported version: %d', version);
            end
            
            if ~isKey(proxy, 'record_count')
                error('JSONFormat.build_records_from_proxy(): Missing ''record_count'' field.');
            end

            record_count = cast(proxy('record_count'), 'int64');
            
            if ~isinteger(record_count)
                error('JSONFormat.build_records_from_proxy(): Expected ''record_count'' field to be of type integer.');
            end
            
            if ~isKey(proxy, 'attributes')
                error('JSONFormat.build_records_from_proxy(): Missing ''attributes'' field.');
            end
            
            attributes = proxy('attributes');
            
            if ~iscell(attributes)
                error('JSONFormat.build_records_from_proxy(): Expected ''attributes'' to be a cell array.');
            end
            
            identifiers = cell(numel(attributes), 1);

            for index=1:numel(attributes)
                
                attribute = attributes{index};
                
                if ~isa(attribute, 'containers.Map')
                    error('JSONFormat.build_records_from_proxy(): Expected attribute to be a containers.Map instance.');
                end
                
                if ~isKey(attribute, 'identifier')
                    error('JSONFormat.build_records_from_proxy(): Missing ''record_count'' field.');
                end

                identifier = attribute('identifier');
                identifiers{index} = identifier;
            end
            
            if ~isKey(proxy, 'attribute_values')
                error('JSONFormat.build_records_from_proxy(): Missing ''attribute_values'' field.');
            end
            
            attribute_values = proxy('attribute_values');

            if ~iscell(attribute_values)
                error('JSONFormat.build_records_from_proxy(): Expected attribute_values to be a cell array.');
            end
            
            for index=1:numel(attribute_values)
                
                values = attribute_values{index};
                value_index = records.value_index_for_name(identifiers{index}, true);
                
                values = obj.proxy_decode_attribute_values(values, value_index);
                attribute_values{index} = values;
            end
            
            for index=1:record_count
                
                record = hdng.utilities.Dictionary();
                
                for attribute_index=1:numel(attribute_values)
                    values = attribute_values{attribute_index};
                    
                    if ~isa(values{index}, 'missing')
                        record(identifiers{attribute_index}) = values{index};
                    end
                end
                
                records.include_record(record);
            end
            
            for index=1:numel(records.attributes)
                
                attribute = records.attributes{index};
                metadata = attributes{index};
                
                description = hdng.experiments.Description();
                
                if isKey(metadata, 'description')
                    if ischar(metadata('description'))
                        description.long_text = metadata('description');
                    end
                end
                
                if isKey(metadata, 'label')
                    if ischar(metadata('label'))
                        description.label = metadata('label');
                    end
                end
                
                attribute.description = description;
                
                if isKey(metadata, 'interactive')
                    if islogical(metadata('interactive'))
                        attribute.attachments.interactive = metadata('interactive');
                    end
                end
            end
            
            if isKey(proxy, 'attachments')
                attachments = proxy('attachments');

                if ~isa(attachments, 'containers.Map')
                    error('JSONFormat.build_records_from_proxy(): Expected ''attachments'' field to be of type containers.Map.');
                end

                keys = attachments.keys();

                for index=1:numel(keys)
                    key = keys{index};
                    value = attachments(key);
                    value = hdng.experiments.Value.load_from_proxy(value);
                    records.attachments.(key) = value.content;
                end
            else
                warning('JSONFormat.build_records_from_proxy(): Missing ''attachments'' field.');
            end
        end

        
        function result = proxy_decode_attribute_values(~, proxy, value_index)
            
            if isa(proxy, 'containers.Map')

                if ~isKey(proxy, 'values')
                    error('JSONFormat.proxy_decode_attribute_values(): Missing ''values'' field.');
                end

                values = proxy('values');

                if ~iscell(values)
                    error('JSONFormat.proxy_decode_attribute_values(): Expected ''values'' to be a cell array.');
                end
                
                for index=1:numel(values)
                    
                    if ~isa(values{index}, 'missing')
                        value = hdng.experiments.Value.load_from_proxy(values{index});
                    else
                        continue;
                    end
                    
                    values{index} = value;
                    
                    entry = value_index.include_entry_for_value(value);
                    entry.include_group_for_value(value);
                    
                    indexed_value = value_index.values{end};
                    
                    if value ~= indexed_value
                        error('JSONFormat.proxy_decode_attribute_values(): Unexpected indexing order.');
                    end
                end

                if ~isKey(proxy, 'indices')
                    error('JSONFormat.proxy_decode_attribute_values(): Missing ''indices'' field.');
                end

                indices = proxy('indices');

                if ~iscell(indices)
                    error('JSONFormat.proxy_decode_attribute_values(): Expected ''indices'' to be a cell array.');
                end
                
                result = cell(numel(indices), 1);
                
                for index=1:numel(indices)
                    index_of_value = cast(indices{index}, 'int64') + 1;
                    result{index} = values{index_of_value};
                end
                
                return;
            end

            if iscell(proxy)
                
                result = cell(numel(proxy), 1);
                
                for index=1:numel(proxy)
                    result{index} = hdng.experiments.Value.load_from_proxy(proxy{index});
                    value_index.include_entry_for_value(result{index});
                end
                
                return;
            end
            
            error('JSONFormat.proxy_decode_attribute_values(): Expected proxy to be a containers.Map instance or a cell array.');
        end
        
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
