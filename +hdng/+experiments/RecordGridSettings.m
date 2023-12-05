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

classdef RecordGridSettings < hdng.experiments.ValueContent
    %RecordGridSettings Summary.
    %   Detailed description 
    
    properties (Constant)
    end
    
    properties
        
        description

        unnest_attribute
        unnest_include_attributes

        row_attribute
        column_attribute
        group_attributes

        row_values
        column_values

        cell_selector_values
        cell_attributes
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = RecordGridSettings()
            
            obj = obj@hdng.experiments.ValueContent();
            
            obj.description = '';

            obj.unnest_attribute = '';
            obj.unnest_include_attributes = {};

            obj.row_attribute = '';
            obj.column_attribute = '';
            obj.group_attributes = {};
    
            obj.row_values = {};
            obj.column_values = {};
            
            obj.cell_selector_values = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.cell_attributes = {};
        end
        
        function result = label_for_content(~)
        	result = 'Record Grid Settings';
        end

        function [serialised_value, type_identifier] = as_serialised_value_and_type(obj)
            
            serialised_value = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            serialised_value('description') = obj.description;
            
            if ~isempty(obj.unnest_attribute)
                serialised_value('unnest_attribute') = obj.unnest_attribute;
            end

            if ~isempty(obj.unnest_include_attributes)
                serialised_value('unnest_include_attributes') = obj.unnest_include_attributes;
            end

            if ~isempty(obj.row_attribute)
                serialised_value('row_attribute') = obj.row_attribute;
            end

            if ~isempty(obj.column_attribute)
                serialised_value('column_attribute') = obj.column_attribute;
            end

            if ~isempty(obj.group_attributes)
                serialised_value('group_attributes') = obj.group_attributes;
            end

            if ~isempty(obj.row_values)
                
                row_values_proxy = obj.row_values;

                for index=1:numel(obj.row_values)
                    row_values_proxy{index} = obj.row_values{index}.as_map();
                end

                serialised_value('row_values') = row_values_proxy;
            end
            
            if ~isempty(obj.column_values)
                
                column_values_proxy = obj.column_values;

                for index=1:numel(obj.column_values)
                    column_values_proxy{index} = obj.column_values{index}.as_map();
                end

                serialised_value('column_values') = column_values_proxy;
            end
            
            if ~isempty(obj.cell_selector_values)
                
                value = containers.Map('KeyType', 'char', 'ValueType', 'any');
                keys = obj.cell_selector_values.keys();
                
                for index=1:numel(keys)
                    key = keys{index};
                    value(key) = obj.cell_selector_values(key).as_map();
                end
                
                serialised_value('cell_selector_values') = value;
            end

            if ~isempty(obj.cell_attributes)
                serialised_value('cell_attributes') = obj.cell_attributes;
            end
            

            type_identifier = 'builtin.record_grid_settings';
        end
        
    end
    
    methods (Static)
        
        function result = from_serialised_value_and_type(serialised_value, type_identifier, result) %#ok<INUSD>
            
            if ~exist('result', 'var') || isempty(result)
                result = hdng.experiments.RecordGridSettings();
            end

            if ~isa(serialised_value, 'containers.Map')
                error('hdng.experiments.GridView.from_serialised_value_and_type(): Expected serialised value to be a containers.Map instance.');
            end
            
            if ~isKey(serialised_value, 'description')
                error('hdng.experiments.GridView.from_serialised_value_and_type(): Expected ''description'' field.');
            end
            
            result.description = serialised_value('description');
            
            if isKey(serialised_value, 'unnest_attribute')
                
                unnest_attribute = serialised_value('unnest_attribute');
                result.unnest_attribute = unnest_attribute;
            end
            
            if isKey(serialised_value, 'unnest_include_attributes')
                
                unnest_include_attributes = serialised_value('unnest_include_attributes');
                result.unnest_include_attributes = unnest_include_attributes;
            end
            
            
            if isKey(serialised_value, 'row_attribute')
                
                row_attribute = serialised_value('row_attribute');
                result.row_attribute = row_attribute;
            end
            
            if isKey(serialised_value, 'column_attribute')
                
                column_attribute = serialised_value('column_attribute');
                result.column_attribute = column_attribute;
            end
            
            if isKey(serialised_value, 'group_attributes')
                
                group_attributes = serialised_value('group_attributes');
                result.group_attributes = group_attributes;
            end
            
            if isKey(serialised_value, 'row_values')
                
                row_values = serialised_value('row_values');
                
                for index=1:numel(row_values)
                    row_values{index} = hdng.experiments.Value.load_from_proxy(row_values{index});
                end

                result.row_values = row_values;
            end
            
            if isKey(serialised_value, 'column_values')
                
                column_values = serialised_value('column_values');
                
                for index=1:numel(column_values)
                    column_values{index} = hdng.experiments.Value.load_from_proxy(column_values{index});
                end

                result.column_values = column_values;
            end
            
            if isKey(serialised_value, 'cell_selector_values')
                
                cell_selector_values = serialised_value('cell_selector_values');
                keys = cell_selector_values.keys();

                for index=1:numel(keys)
                    key = keys{index};
                    result.cell_selector_values(key) = hdng.experiments.Value.load_from_proxy(cell_selector_values(key));
                end
            end
            
            if isKey(serialised_value, 'cell_attributes')
                
                cell_attributes = serialised_value('cell_attributes');
                result.group_attributes = cell_attributes;
            end
        end
    end
    
    methods (Access=protected)
    end
    
end
