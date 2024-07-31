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

function grid_cell_values = select_data_per_polygon(group, grid_env, cell_value_fn)
    

    grid_cells = group.grid_cells;
    grid_cell_values = group.grid_cell_values;
    column_values = group.column_values;
    row_values = group.row_values;

    fn_state = [];
    
    for row_index=1:size(grid_cell_values, 1)

        for col_index=1:size(grid_cell_values, 2)
            
            grid_cell = grid_cells{row_index, col_index};
            
            if isempty(grid_cell)
                continue;
            end
            
            [values, fn_state] = cell_value_fn(grid_cell_values, row_index, col_index, row_values, column_values, fn_state);

            if isempty(values)
                continue;
            end
            
            polygon_datasets = geospm.reports.extract_polygon_datasets(values, grid_cell, grid_env);

            grid_cell_values{row_index, col_index} = polygon_datasets;
        end
    end
end
