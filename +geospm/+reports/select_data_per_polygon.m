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

function grid_cell_values = select_data_per_polygon(group, grid_env)
    

    grid_cells = group.grid_cells;
    grid_cell_values = group.grid_cell_values;

    for index=1:numel(grid_cell_values)
        values = grid_cell_values{index};

        if isempty(values)
            continue;
        end
        
        grid_cell = grid_cells{index};
        
        polygon_datasets = geospm.reports.extract_polygon_datasets(values, grid_cell, grid_env);

        grid_cell_values{index} = polygon_datasets;
    end
end
