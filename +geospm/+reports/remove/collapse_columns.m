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

function [result_cell_contexts, result_column_values] = ...
            collapse_columns(grid_cell_contexts, column_values)

    result_cell_contexts = cell(size(grid_cell_contexts));
    result_column_values = cell(size(grid_cell_contexts));

    for index=1:size(grid_cell_contexts, 1)
        cell_selector = cellfun(@(x) ~isempty(x), grid_cell_contexts(index, :));
        C = sum(cell_selector);
        
        result_cell_contexts(index, 1:C) = grid_cell_contexts(index, cell_selector);
        result_column_values(index, 1:C) = column_values(cell_selector);
    end

    empty_cell_selector = cellfun(@(x) isempty(x), result_cell_contexts);
    
    available_columns = ~all(empty_cell_selector, 1);

    result_cell_contexts = result_cell_contexts(:, available_columns);
    result_column_values = result_column_values(:, available_columns);
end
