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

function preprocess_study_records(directory, identifier, grid_options)
    
    records_path = fullfile(directory, 'records.json.gz');
    records = hdng.experiments.load_records(records_path);
    
    arguments = hdng.utilities.struct_to_name_value_sequence(grid_options);

    [groups, group_values, row_values, column_values] = ...
        geospm.reports.grid_cells_from_records(records, ...
            grid_options.row_field, grid_options.column_field, arguments{:});
    
    for index=1:numel(groups)
        
        group = groups{index};

        group.grid_cells = group.grid_cells(group.row_value_selector, group.column_value_selector);
        
        group.row_values = row_values(group.row_value_selector);
        group.column_values = column_values(group.column_value_selector);
        
        grid_cell_values = geospm.reports.match_cell_records(group.grid_cells, grid_options.cell_selector);
        group.grid_cell_values = geospm.reports.select_cell_values(grid_cell_values, grid_options.cell_fields);

        groups{index} = group;
    end

    filename = fullfile(directory, [identifier '_preprocessed.mat']);
    save(filename, 'groups', 'group_values', 'row_values', 'column_values');
end

