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

classdef RecordGrid < handle
    
    %RecordGrid
    %

    properties (GetAccess=public, SetAccess=public)
        
        groups

        group_values
        row_values
        column_values
    end

    properties (Dependent, Transient)
    end
    
    methods

        function obj = RecordGrid(groups, group_values, ...
                row_values, column_values)
            
            obj.groups = groups;

            obj.group_values = group_values;
            obj.row_values = row_values;
            obj.column_values = column_values;
        end

        function save(obj, filename)

            record_grid = obj;
            save(filename, 'record_grid');
        end

    end

    methods (Static)

        function result = load(filename)
        
            load(filename, 'record_grid');
            result = record_grid;
        end
    
        function result = from_records_at(records_path, row_field, column_field, varargin)

            records = hdng.experiments.load_records(records_path);

            result = geospm.reports.RecordGrid.from_records(records, row_field, column_field, varargin{:});
        end

        function result = from_records(records, row_field, column_field, varargin)

        % Arrange an array of records into a grid based on the values of a 
        % designated row and column field.
        %
        % (Optional) Name – Value arguments:
        % group_field – An optional field name to arrange the grid into
        %               distinct groups of rows. Defaults to '', which produces
        %               a single group.
        %
        % unnest_field – An optional field name for a record array to be unnested
        %                and individually joined with the parent record.
        %
        % column_order – A cell array specifying the order of column names.
        %
        % exclude_column_labels –
        %
        % prune_empty_rows –
        %
        % prune_empty_columns – 
        % 
        % result – A cell array of groups.
        
        
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'group_field')
                options.group_field = '';
            end
            
            if ~isfield(options, 'unnest_field')
                options.unnest_field = '';
            end
        
            if ~isfield(options, 'column_order')
                options.column_order = {};
            end
        
            if ~isfield(options, 'exclude_column_labels')
                options.exclude_column_labels = {};
            end

            if ~isfield(options, 'prune_empty_rows')
                options.prune_empty_rows = true;
            end

            if ~isfield(options, 'prune_empty_columns')
                options.prune_empty_columns = true;
            end
        
            exclude_column_labels = hdng.utilities.Dictionary();
        
            if ~isempty(options.exclude_column_labels)
                for index=1:numel(options.exclude_column_labels)
                    label = options.exclude_column_labels{index};
                    exclude_column_labels(label) = true;
                end
            end
            
            if ~isempty(options.unnest_field)
                unnested_records = hdng.experiments.unnest_records(records, ...
                    options.unnest_field, {}, {}, [options.unnest_field '.']);
            else
                unnested_records = records;
            end
            
            if ~isempty(options.group_field)
                group_values = unnested_records.value_index_for_name(options.group_field, true).values;
            else
                group_values = {hdng.experiments.Value.from('All')};
            end
            
            group_indices = hdng.utilities.Dictionary();
        
            for index=1:numel(group_values)
                value = group_values{index};
                group_indices(value.label) = index;
            end
            
            row_values = unnested_records.value_index_for_name(row_field, true).values;
            column_values = unnested_records.value_index_for_name(column_field, true).values;
        
            row_indices = hdng.utilities.Dictionary();
        
            for index=1:numel(row_values)
                value = row_values{index};
                row_indices(value.label) = index;
            end
            
            [~, column_order] = sort(cellfun(@(x) x.label, column_values, 'UniformOutput', false));
            column_values = column_values(column_order);
        
            column_order = hdng.utilities.Dictionary();
            
            for index=1:numel(options.column_order)
                value = options.column_order{index};
                column_order(value) = index;
            end
        
            column_positions = zeros(size(column_values));
            
            for index=1:numel(column_values)
                value = column_values{index};
                position = column_order.length + index;
                
                if column_order.holds_key(value.label)
                    position = column_order(value.label);
                end
                
                column_positions(index) = position;
            end
            
            [~, column_order] = sort(column_positions);
            column_values = column_values(column_order);
        
            column_indices = hdng.utilities.Dictionary();
        
            for index=1:numel(column_values)
                value = column_values{index};
                column_indices(value.label) = index;
            end
        
            groups = cell(numel(group_values), 1);
            
            % For every record, determine the value of its group, row and column
            % and their corresponding indices, then add the record to the
            % cell at those indices.

            row_value_selectors = zeros(numel(group_values), numel(row_values), 'logical');
            column_value_selectors = zeros(numel(group_values), numel(column_values), 'logical');
        
        
            for record_index=1:numel(unnested_records.records)
        
                record = unnested_records.records{record_index};
        
                if ~isempty(options.group_field)
                    group_value = record(options.group_field);
                else
                    group_value = group_values{1};
                end
                
                group_index = group_indices(group_value.label);
        
                group = groups{group_index};
        
                if isempty(group)
                    group = geospm.reports.Group(group_index, group_value, row_values, column_values);
                    groups{group_index} = group;
                end
                
                row_value = record(row_field);
                column_value = record(column_field);
                
                if exclude_column_labels.holds_key(column_value.label)
                    continue;
                end
        
                row_index = row_indices(row_value.label);
                column_index = column_indices(column_value.label);
                
                row_value_selectors(group_index, row_index) = 1;
                column_value_selectors(group_index, column_index) = 1;
        
                cell_records = group.cells{row_index, column_index};
                
                if isempty(cell_records)
                    cell_records = hdng.experiments.RecordArray();
                end
        
                cell_records.include_record(record);
        
                group.cells{row_index, column_index} = cell_records;
            end
            
            [column_values, column_order] = geospm.reports.RecordGrid.sort_group_columns_by_weight(groups, column_values);

            column_value_selectors = column_value_selectors(:, column_order);

            if options.prune_empty_rows
                
                for index=1:numel(groups)

                    group = groups{index};
                    group.select_rows(row_value_selectors(index, :));
                end
                    
            end
            
            if options.prune_empty_columns

                for index=1:numel(groups)

                    group = groups{index};
                    group.select_columns(column_value_selectors(index, :));
                end
            end

            result = geospm.reports.RecordGrid(groups, group_values, ...
                row_values, column_values);
        end
    end

    methods (Static, Access=protected)
        
        function [column_values, column_order] = sort_group_columns_by_weight(groups, column_values)
        
            column_weights = zeros(size(column_values));
        
            for index=1:numel(groups)
        
                group = groups{index};
                
                cell_selector = cellfun(@(x) ~isempty(x), group.cells);
                column_weights = column_weights + sum(cell_selector, 1)';
            end
            
            [~, column_order] = sort(column_weights, 'descend');
            column_values = column_values(column_order);
            
            for index=1:numel(groups)
                group = groups{index};
        
                group.select_columns(column_order);
                
                groups{index} = group;
            end
        end
    
    end
end
