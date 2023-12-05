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

function verbal_summary(records, row_field, column_field, cell_selector, cell_fields, output_file, render_options, varargin)

    options = hdng.utilities.parse_struct_from_varargin(varargin{:});

    if ~isfield(options, 'host_name')
        options.host_name = 'http://localhost:9999';
    end

    if ~isfield(options, 'clear_source_refs')
        options.clear_source_refs = false;
    end

    [parent_dir, output_name, ~] = fileparts(output_file);
    
    options = rmfield(options, 'host_name');
    options = rmfield(options, 'clear_source_refs');

    arguments = hdng.utilities.struct_to_name_value_sequence(options);

    [groups, group_values, row_values, column_values] = ...
        geospm.reports.grid_cells_from_records(records, row_field, column_field, arguments{:});
    
    for index=1:numel(groups)

        group_value = group_values{index};

        group = groups{index};

        grid_cells = group.grid_cells(group.row_value_selector, group.column_value_selector);
        
        group_row_values = row_values(group.row_value_selector);
        group_column_values = column_values(group.column_value_selector);

        grid_cells = geospm.reports.match_cell_records(grid_cells, cell_selector);
        grid_cell_values = geospm.reports.select_cell_values(grid_cells, cell_fields);
        
        summaries = unpack_summaries(grid_cell_values, render_options.slice_name);
        
        group_id = lower(group_value.label);
        group_id = regexprep(group_id, '\s+', '_');

        file_name = fullfile(parent_dir, [output_name sprintf('_%s_%s', group_id) '.csv']);
        save_summaries_grid(file_name, summaries, group_row_values, group_column_values, render_options);
    end
end

function grid_cell_values = unpack_summaries(grid_cell_values, slice_name)
    
    for index=1:numel(grid_cell_values)
        values = grid_cell_values{index};

        if isempty(values)
            continue;
        end
        
        % This is hard-coded for now!
        contrast = values{1}.content;
        slice_map = hdng.experiments.SliceMap(contrast.slice_names);
        slice_index = slice_map.index_for_name(slice_name, 0);

        if slice_index == 0
            grid_cell_values{index} = '';
        else
            summaries = values{2}.content;
            grid_cell_values{index} = summaries{slice_index};
        end
    end
end

function result = save_summaries_grid(file_path, summaries, row_values, column_values, render_options)
    
    result = '';
    
    if render_options.collapse_empty_cells

        collapsed_summaries = [];

        for index=1:size(summaries, 1)
            summary_row = summaries(index, :);
            
            empty_cell_selector = cellfun(@(x) isempty(x), summary_row);

            summary_row = [ {''}, summary_row(~empty_cell_selector)];
            
            row_column_values = cellfun(@(x) x.label, column_values(~empty_cell_selector), 'UniformOutput', false);
            
            row_column_values = [{row_values{index}.label}, row_column_values(:)'];
            
            if index > 1 && size(collapsed_summaries, 2) < numel(row_column_values)
                collapsed_summaries{index - 1, numel(row_column_values)} = ''; %#ok<AGROW>
            elseif size(collapsed_summaries, 2) > numel(row_column_values)
                row_column_values{size(collapsed_summaries, 2)} = '';
                summary_row{size(collapsed_summaries, 2)} = '';
            end
            
            collapsed_summaries = [collapsed_summaries;
                                   row_column_values(:)';
                                   summary_row(:)']; %#ok<AGROW>
        end
        
        summaries = collapsed_summaries;
    else

        row_values = cellfun(@(x) x.label, row_values, 'UniformOutput', false);
        column_values = cellfun(@(x) x.label, column_values, 'UniformOutput', false);
        
        row_values = [{render_options.slice_name}; row_values(:)];
        summaries = [row_values, [column_values(:)'; summaries]];
    end

    writecell(summaries, file_path, 'QuoteStrings', true);
end


function result = save_summaries_grid_v1(file_path, summaries, row_values, column_values, render_options)
    
    result = '';
    
    if render_options.collapse_empty_cells
        empty_cell_selector = cellfun(@(x) isempty(x), summaries);
        
        available_columns = ~all(empty_cell_selector, 1);
        available_rows = ~all(empty_cell_selector, 2);

        summaries = summaries(available_rows, available_columns);
    
        column_values = column_values(available_columns);
        row_values = row_values(available_rows);
    end

    row_values = cellfun(@(x) x.label, row_values, 'UniformOutput', false);
    column_values = cellfun(@(x) x.label, column_values, 'UniformOutput', false);
    
    row_values = [{render_options.slice_name}; row_values(:)];
    summaries = [row_values, [column_values(:)'; summaries]];
    
    writecell(summaries, file_path, 'QuoteStrings', true);
end
