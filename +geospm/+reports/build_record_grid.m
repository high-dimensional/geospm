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

function build_record_grid(directory, identifier, ...
    row_field, column_field, grid_options)
    
    grid_arguments = hdng.utilities.struct_to_name_value_sequence(grid_options);

    records_path = fullfile(directory, 'records.json.gz');

    grid = geospm.reports.RecordGrid.from_records_at(records_path, row_field, column_field, grid_arguments{:});
    
    for index=1:numel(grid.groups)
        
        group = grid.groups{index};
        
        cell_records = group.match_cell_records(grid_options.cell_selector);

        selected_values = select_values_from_cell_records(cell_records, grid_options.cell_fields);

        group.cell_attachments.preprocessed_values = selected_values;
    end
    
    filename = fullfile(directory, [identifier '_preprocessed.mat']);

    grid.save(filename);
end

function result = select_values_from_cell_records(cells, field_paths)
    
    result = cell(size(cells));

    for index=1:numel(cells)

        cell_records = cells{index};

        if isempty(cell_records)
            continue;
        end
        
        cell_values = struct();
        
        for record_index=1:cell_records.length

            record = cell_records.records{record_index};

            for field_index=1:numel(field_paths)

                field_path = field_paths{field_index};
                cell_values = hdng.utilities.struct_set_value_at_path(cell_values, field_path, record(field_path));
            end
        end
        
        result{index} = cell_values;
    end
end

