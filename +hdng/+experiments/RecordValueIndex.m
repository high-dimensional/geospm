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

classdef RecordValueIndex < handle
    
    %RecordValueIndex Indexes a collection of records by the values of a field.
    %
    
    properties
    end
    
    properties (Dependent, Transient)
        field_identifier
        is_empty
        values
    end
    
    properties (GetAccess=private, SetAccess=private)
        field_identifier_
        values_
    end
    
    methods
        
        function obj = RecordValueIndex(field_identifier)
            obj.field_identifier_ = field_identifier;
            obj.values_ = hdng.utilities.OrderedMap('KeyType', 'char', 'ValueType', 'any');
        end
        
        function result = get.field_identifier(obj)
            result = obj.field_identifier_;
        end
        
        function result = get.is_empty(obj)
            result = length(obj.values_) == 0; %#ok<ISMT>
        end
        
        function result = get.values(obj)
            
            result = {};
            value_keys = keys(obj.values_);
            
            for index=1:numel(value_keys)
                
                key = value_keys{index};
                entry = obj.values_(key);
                result = [result; entry.values]; %#ok<AGROW>
            end
        end
        
        function result = entry_for_value(obj, value)
            
            result = hdng.experiments.RecordValueIndexEntry.empty;
            key = value.digest;
            
            if ~isKey(obj.values_, key)
                return;
            end
            
            result = obj.values_(key);
        end
        
        function result = records_for_value(obj, value)
            
            result = {};
            key = value.digest;
            
            if ~isKey(obj.values_, key)
                return;
            end
            
            entry = obj.values_(key);
            result = entry.records_for_value(value);
        end
        
        function include_record(obj, record)
            
            if ~isa(record, 'hdng.utilities.Dictionary')
                error('RecordValueIndex.include_record() expects a hdng.utilities.Dictionary as record but got: %s', class(record));
            end
            
            if ~record.holds_key(obj.field_identifier_)
                return
            end
            
            value = record(obj.field_identifier_);
            
            entry = obj.include_entry_for_value(value);
            
            if ~entry.include_value_in_record(value, record)
                return
            end
        end
        
        function entry = include_entry_for_value(obj, value)
            
            key = value.digest;
            
            if ~isKey(obj.values_, key)
                entry = hdng.experiments.RecordValueIndexEntry(key);
                obj.values_(key) = entry;
            else
                entry = obj.values_(key);
            end
        end
        
        function exclude_record(obj, record)
            
            if ~isa(record, 'hdng.utilities.Dictionary')
                error('RecordValueIndex.include_record() expects a hdng.utilities.Dictionary as record but got: %s', class(record));
            end
            
            if ~record.holds_key(obj.field_identifier_)
                return
            end
            
            value = record(obj.field_identifier_);
            entry = obj.entry_for_value(value);
            
            if isempty(entry) || ~entry.exclude_value_in_record(value, record)
                return
            end
            
            if entry.N_values == 0
                remove(obj.values_, entry.key);
            end
        end
        
    end
    
    methods (Static, Access=protected)
    end
end
