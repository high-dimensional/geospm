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

classdef ReportGroup < handle
    
    %ReportGroup
    %

    properties (GetAccess=public, SetAccess=private)
        
        number
        value
    end

    properties (GetAccess=public, SetAccess=public)
        
        row_value_per_cell
        column_value_per_cell

        cells
        cell_attachments
        attachments
    end

    properties (Dependent, Transient)

        N_rows
        N_columns
    
    end
    
    methods

        function result = get.N_rows(obj)
            result = size(obj.cells, 1);
        end

        function result = get.N_columns(obj)
            result = size(obj.cells, 2);
        end
        
        function obj = ReportGroup(number, value, row_value_per_cell, column_value_per_cell)
            
            if ~isequal(size(row_value_per_cell), size(column_value_per_cell))
                error('The dimensions of row_value_per_cell and column_value_per_cell must match.');
            end

            obj.number = number;
            obj.value = value;
            
            obj.row_value_per_cell = row_value_per_cell;
            obj.column_value_per_cell = column_value_per_cell;

            obj.cells = cell(size(obj.row_value_per_cell, 1), size(obj.column_value_per_cell, 2));
            
            obj.cell_attachments = struct();
            obj.attachments = struct();
            
        end

        function expand(obj, dimension, at, slice_count)

            %slice_count = numel(varargin);
            %value_slice = cat(dimension, varargin{:});
            
            obj.column_value_per_cell = hdng.utilities.insert_slice(obj.column_value_per_cell, dimension, at, [], slice_count);
            obj.row_value_per_cell = hdng.utilities.insert_slice(obj.row_value_per_cell, dimension, at, [], slice_count);
            
            obj.cells = hdng.utilities.insert_slice(obj.cells, dimension, at, [], slice_count);
            
            names = fieldnames(obj.cell_attachments);

            for index=1:numel(names)
                name = names{index};
                
                obj.cell_attachments.(name) = ...
                    hdng.utilities.insert_slice(obj.cell_attachments.(name), dimension, at, [], slice_count);
            end
        end

        function order_columns(obj, column_order)
            
            %{
            row_value_per_cell
            column_value_per_cell
    
            cells
            cell_attachments
            attachments
            %}

            cell_attachment_names = fieldnames(obj.cell_attachments);
            n_cell_attachments = numel(cell_attachment_names);

            order_limit = numel(column_order);

            for index=1:obj.N_rows
                column_values = obj.column_value_per_cell(index, :);
                column_labels = cellfun(@(x) x.label, column_values, 'UniformOutput', false);

                row_order = zeros(numel(column_labels), 1);

                for c_index=1:numel(column_labels)
                    column_value = column_labels{c_index};
                    sort_index = find(strcmp(column_value, column_order), 1);

                    if ~isempty(sort_index)
                        row_order(c_index) = sort_index;
                    end
                end

                selector = row_order == 0;
                zero_count = sum(selector);

                row_order(selector) = order_limit + 1:order_limit + zero_count;
                [~, sort_order] = sort(row_order);
                
                %{
                column_labels_before = join(column_labels, ' | ');
                column_labels_before = column_labels_before{1};

                column_labels_after = join(column_labels(sort_order), ' | ');
                column_labels_after = column_labels_after{1};

                fprintf('%s\n', column_labels_before);
                fprintf('%s\n', column_labels_after);
                %}
                
                obj.column_value_per_cell(index, :) = column_values(sort_order);
                obj.cells(index, :) = obj.cells(index, sort_order);

                for a_index=1:n_cell_attachments
                    attachment = cell_attachment_names{a_index};
                    attachment_cells = obj.cell_attachments.(attachment);
                    attachment_cells(index, :) = attachment_cells(index, sort_order);
                    obj.cell_attachments.(attachment) = attachment_cells;
                end

            end
        end

        function collapse_across_columns(obj)

            names = fieldnames(obj.cell_attachments);

            blank = cell(size(obj.cells));
        
            tmp_cells = blank;
            tmp_column_value_per_cell = blank;
            tmp_row_value_per_cell = blank;

            tmp_cell_attachments = struct();

            for f=1:numel(names)
                name = names{f};
                tmp_cell_attachments.(name) = blank;
            end

            for index=1:obj.N_rows

                cell_selector = cellfun(@(x) ~isempty(x), obj.cells(index, :));
                C = sum(cell_selector);
                
                tmp_cells(index, 1:C) = obj.cells(index, cell_selector);
                tmp_column_value_per_cell(index, 1:C) = obj.column_value_per_cell(index, cell_selector);
                tmp_row_value_per_cell(index, 1:C) = obj.row_value_per_cell(index, cell_selector);

                for f=1:numel(names)
                    name = names{f};
                    tmp_cell_attachments.(name)(index, 1:C) = ...
                        obj.cell_attachments.(name)(index, cell_selector);
                end
            end
        
            empty_cell_selector = cellfun(@(x) isempty(x), tmp_cells);
            
            available_columns = ~all(empty_cell_selector, 1);
            
            obj.cells = tmp_cells(:, available_columns);
            obj.column_value_per_cell = tmp_column_value_per_cell(:, available_columns);
            obj.row_value_per_cell = tmp_row_value_per_cell(:, available_columns);

            for f=1:numel(names)
                name = names{f};
                tmp_cell_attachments.(name) = ...
                    tmp_cell_attachments.(name)(:, available_columns);
            end

            obj.cell_attachments = tmp_cell_attachments;
        end

        function select_columns(obj, column_selector)
            
            obj.cells = obj.cells(:, column_selector);
            obj.column_value_per_cell = obj.column_value_per_cell(:, column_selector);
            obj.row_value_per_cell = obj.row_value_per_cell(:, column_selector);

            names = fieldnames(obj.cell_attachments);

            for f=1:numel(names)
                name = names{f};

                obj.cell_attachments.(name) = obj.cell_attachments.(name)(:, column_selector);
            end
        end

        function select_rows(obj, row_selector)
            
            obj.cells = obj.cells(row_selector, :);
            obj.column_value_per_cell = obj.column_value_per_cell(row_selector, :);
            obj.row_value_per_cell = obj.row_value_per_cell(row_selector, :);

            names = fieldnames(obj.cell_attachments);

            for f=1:numel(names)
                name = names{f};

                obj.cell_attachments.(name) = obj.cell_attachments.(name)(row_selector, :);
            end
        end

        function result = match_cell_records(obj, cell_selector)
            
            result = cell(size(obj.cells));

            for index=1:numel(obj.cells)

                cell_records = obj.cells{index};
                
                if isempty(cell_records)
                    continue;
                end
                
                cell_records = cell_records.select(cell_selector);
        
                result{index} = cell_records;
            end
        end
    end

    methods (Static, Access=protected)
    
        function result = initialise_struct_array(allocation_size)
        
            result = struct('unused', num2cell(zeros(allocation_size)));
            result = rmfield(result, 'unused');
        end
    
    end
end
