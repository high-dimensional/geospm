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

classdef Partition < hdng.diagrams.Generator
    %Partition Summary.
    %   Detailed description 
    
    properties
        fields
        match_values
        placeholders
        sort_orders
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Partition(varargin)

            obj = obj@hdng.diagrams.Generator();

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'fields')
                options.fields = {};
            end

            if ~isfield(options, 'match_values')
                options.match_values = struct();
            end

            if ~isfield(options, 'placeholders')
                options.placeholders = hdng.utilities.RecordTable;
            end

            if ~isfield(options, 'sort_orders')
                options.sort_orders = struct();
            end
            
            obj.fields = options.fields;
            obj.match_values = options.match_values;
            obj.placeholders = options.placeholders;

            obj.sort_orders = options.sort_orders;
        end

        function children = apply(obj, scope, child_data_level)
            
            queue = {{scope.records, scope.attributes}};

            for f_index=1:numel(obj.fields)
                
                field = obj.fields{f_index};
                field_match_values = hdng.utilities.struct_get_value_at_path(obj.match_values, field, {});
                
                sort_order = [];
                
                if isfield(obj.sort_orders, field)
                    sort_order = obj.sort_orders.(field);
                end

                next_queue = {};

                while ~isempty(queue)
                    
                    state = queue{1}; queue = queue(2:end);
                    records = state{1};
                    attributes = state{2};

                    [matched_records, matched_values] = records.group_rows_by_field(field, field_match_values);
                    
                    if ~isempty(sort_order)
                        sorted_indices = sort_order.apply(matched_values);
                        
                        remove_indices = sorted_indices == 0;
                        sorted_indices = sorted_indices(~remove_indices);

                        matched_values = matched_values(sorted_indices);
                        matched_records = matched_records(sorted_indices);
                    end
                    
                    nested_attributes = attributes;

                    for p_index=1:numel(matched_records)
                        nested_records = matched_records{p_index};
                        nested_records = nested_records.remove_field(field);
                        
                        nested_attributes.(field) = matched_values{p_index};

                        next_queue{end + 1} = {nested_records, nested_attributes}; %#ok<AGROW>
                    end
                end

                queue = next_queue;
            end
            

            children = cell(numel(queue), 1);

            matches = hdng.utilities.RecordTable;

            for index=1:numel(queue)
                
                state = queue{index};
                records = state{1};
                attributes = state{2};
                
                matches = matches + hdng.utilities.RecordTable(attributes, 1);

                scope = hdng.diagrams.DataScope(child_data_level, attributes, records);
                children{index} = scope;
            end

            missing_placeholders = [];
            
            for index=1:obj.placeholders.length
                
                placeholder = obj.placeholders.row(index);
                
                result = matches.match_record(placeholder);
            
                if ~any(result)
                    missing_placeholders(end + 1) = index; %#ok<AGROW>
                end
            end

            missing_placeholders = obj.placeholders.select_matching_rows([], missing_placeholders);

            if missing_placeholders.length > 0

                for f_index=1:numel(scope.records.fieldnames)
                    
                    field = scope.records.fieldnames{f_index};
    
                    if any(strcmp(field, obj.fields))
                        continue
                    end
    
                    field_values = scope.records.fields.(field);
                    constant_values = repmat(field_values(1), scope.records.length, 1);
    
                    is_constant = isequal(field_values(:), constant_values(:));
    
                    if ~is_constant
                        continue
                    end
    
                    missing_placeholders.add_field(field, constant_values(1));
                end
            end
            
            for index=1:missing_placeholders.length
                
                placeholder = missing_placeholders.row(index);

                scope = hdng.diagrams.DataScope(child_data_level, placeholder, hdng.utilities.RecordTable);
                scope.is_placeholder = true;
                children{end + 1} = scope; %#ok<AGROW>
            end

        end
    end
end
