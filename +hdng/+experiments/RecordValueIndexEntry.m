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

classdef RecordValueIndexEntry < handle
    
    %RecordValueIndexEntry Holds a collection of records that share the same key.
    %
    
    properties
        key
    end
    
    properties (Dependent, Transient)
        N_values
        values
    end
    
    properties (GetAccess=private, SetAccess=private)
        groups_by_value
    end
    
    methods
        
        function obj = RecordValueIndexEntry(key)
            obj.key = key;
            obj.groups_by_value = {};
        end
        
        function result = attachments_for_value(obj, value)
            
            result = hdng.utilities.Dictionary.empty;
            
            for index=1:numel(obj.groups_by_value)
                
                entry = obj.groups_by_value{index};
                
                if ~(value == entry.value)
                    continue
                end
                
                result = entry.attachments;
                return
            end
        end
        
        function result = get.N_values(obj)
            result = numel(obj.groups_by_value);
        end
        
        function result = get.values(obj)
            
            result = cell(numel(obj.groups_by_value), 1);
            
            for index=1:numel(obj.groups_by_value)
                
                entry = obj.groups_by_value{index};
                result{index} = entry.value;
            end
        end
        
        function result = records_for_value(obj, value)
            
            result = {};
            
            for index=1:numel(obj.groups_by_value)
                
                entry = obj.groups_by_value{index};
                
                if ~(value == entry.value)
                    continue
                end
                
                result = entry.records;
                return
            end
        end
        
        function did_add = include_value_in_record(obj, value, record)
            
            group = obj.include_group_for_value(value);
            did_add = group.include_record(record);
        end
        
        function group = include_group_for_value(obj, value)
            
            for index=1:numel(obj.groups_by_value)
                
                group = obj.groups_by_value{index};
                
                if ~(value == group.value)
                    continue
                end
                return
            end
            
            group = hdng.experiments.RecordValueGroup(value);
            obj.groups_by_value = [obj.groups_by_value, {group}];
        end
        
        
        function did_remove = exclude_value_in_record(obj, value, record)
            
            did_remove = false;
            
            for index=1:numel(obj.groups_by_value)
                
                entry = obj.groups_by_value{index};
                
                if ~(value == entry.value)
                    continue
                end
                
                did_remove = entry.exclude_record(record);
                
                if did_remove
                    
                    if numel(entry.records) == 0
                        obj.groups_by_value(index) = [];
                        
                        if isempty(obj.groups_by_value)
                            obj.groups_by_value = {};
                        end
                    end
                end
                
                return
            end
        end
    end
end
