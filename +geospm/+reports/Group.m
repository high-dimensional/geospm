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

classdef Group < handle
    
    %Group
    %

    properties (GetAccess=public, SetAccess=public)
        
        number
        value

        row_values
        column_values
        
        cells
        cell_attachments

        attachments

        %row_value_selector
        %column_value_selector
    end

    properties (Dependent, Transient)

        N_rows
        N_columns
    
    end
    
    methods

        function result = get.N_rows(obj)
            result = numel(obj.row_values);
        end

        function result = get.N_columns(obj)
            result = numel(obj.column_values);
        end
        
        function obj = Group(number, value, row_values, column_values)
            
            obj.number = number;
            obj.value = value;
            
            obj.row_values = row_values;
            obj.column_values = column_values;

            obj.cells = cell(numel(row_values), numel(column_values));

            obj.cell_attachments = struct();
            obj.attachments = struct();
            
        end

        function collapse_across_columns(obj)

            names = fieldnames(obj.cell_attachments);

            blank = cell(size(obj.cells));
        
            tmp_cells = blank;
            tmp_column_values = blank;

            tmp_cell_attachments = struct();

            for f=1:numel(names)
                name = names{f};
                tmp_cell_attachments.(name) = blank; %obj.initialise_struct_array(size(blank));
            end

            for index=1:obj.N_rows

                cell_selector = cellfun(@(x) ~isempty(x), obj.cells(index, :));
                C = sum(cell_selector);
                
                tmp_cells(index, 1:C) = obj.cells(index, cell_selector);
                tmp_column_values(index, 1:C) = obj.column_values(cell_selector);

                for f=1:numel(names)
                    name = names{f};
                    tmp_cell_attachments.(name)(index, 1:C) = ...
                        obj.cell_attachments.(name)(index, cell_selector);
                end
            end
        
            empty_cell_selector = cellfun(@(x) isempty(x), tmp_cells);
            
            available_columns = ~all(empty_cell_selector, 1);
            
            obj.cells = tmp_cells(:, available_columns);
            obj.column_values = tmp_column_values(:, available_columns);

            for f=1:numel(names)
                name = names{f};
                tmp_cell_attachments.(name) = ...
                    tmp_cell_attachments.(name)(:, available_columns);
            end

            obj.cell_attachments = tmp_cell_attachments;
        end

        function select_columns(obj, column_selector)
            
            obj.cells = obj.cells(:, column_selector);
            obj.column_values = obj.column_values(column_selector);

            names = fieldnames(obj.cell_attachments);

            for f=1:numel(names)
                name = names{f};

                obj.cell_attachments.(name) = obj.cell_attachments.(name)(:, column_selector);
            end
        end

        function select_rows(obj, row_selector)
            
            obj.cells = obj.cells(row_selector, :);
            obj.row_values = obj.row_values(row_selector);

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
