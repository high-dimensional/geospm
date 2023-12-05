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

function [grid_cells] = select_cell_values(grid_cells, field_names)

    for index=1:numel(grid_cells)

        cell_records = grid_cells{index};

        if isempty(cell_records)
            continue;
        end
        
        cell_values = cell(cell_records.length, numel(field_names));
        
        for record_index=1:cell_records.length
            record = cell_records.records{record_index};

            for field_index=1:numel(field_names)
                field_name = field_names{field_index};
                cell_values{record_index, field_index} = record(field_name);
            end
        end
        
        grid_cells{index} = cell_values;
    end
end
