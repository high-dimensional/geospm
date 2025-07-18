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


function group = ...
            collapse_group_columns(group)

    result_cell_contexts = cell(size(group.grid_cell_contexts));
    result_cell_values = cell(size(group.grid_cell_contexts));
    result_cells = cell(size(group.grid_cell_contexts));
    result_column_values = cell(size(group.grid_cell_contexts));

    for index=1:size(group.grid_cell_contexts, 1)
        cell_selector = cellfun(@(x) ~isempty(x), group.grid_cell_contexts(index, :));
        C = sum(cell_selector);
        
        result_cell_contexts(index, 1:C) = group.grid_cell_contexts(index, cell_selector);
        result_cell_values(index, 1:C) = group.grid_cell_values(index, cell_selector);
        result_cells(index, 1:C) = group.grid_cells(index, cell_selector);
        result_column_values(index, 1:C) = group.column_values(cell_selector);
    end

    empty_cell_selector = cellfun(@(x) isempty(x), result_cell_contexts);
    
    available_columns = ~all(empty_cell_selector, 1);

    group.grid_cell_contexts = result_cell_contexts(:, available_columns);
    group.grid_cell_values = result_cell_values(:, available_columns);
    group.grid_cells = result_cells(:, available_columns);
    group.column_values = result_column_values(:, available_columns);
end

