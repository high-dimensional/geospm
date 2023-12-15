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

function action_summary(records, row_field, column_field, cell_selector, cell_fields, output_file, render_options, varargin)

    options = hdng.utilities.parse_struct_from_varargin(varargin{:});

    if ~isfield(options, 'host_name')
        options.host_name = 'http://localhost:9999';
    end

    if ~isfield(options, 'clear_source_refs')
        options.clear_source_refs = false;
    end

    if ~isfield(options, 'dataset_aliases')
        options.dataset_aliases = hdng.utilities.Dictionary();
    end

    dataset_aliases = options.dataset_aliases;

    [parent_dir, output_name, ~] = fileparts(output_file);
    
    options = rmfield(options, 'host_name');
    options = rmfield(options, 'clear_source_refs');
    options = rmfield(options, 'dataset_aliases');

    arguments = hdng.utilities.struct_to_name_value_sequence(options);

    [groups, group_values, row_values, column_values] = ...
        geospm.reports.grid_cells_from_records(records, row_field, column_field, arguments{:});
    
    dataset_cache = hdng.utilities.Dictionary();

    for index=1:numel(groups)

        group_value = group_values{index};

        group = groups{index};

        grid_cells = group.grid_cells(group.row_value_selector, group.column_value_selector);
        
        group_row_values = row_values(group.row_value_selector);
        group_column_values = column_values(group.column_value_selector);

        grid_cells = geospm.reports.match_cell_records(grid_cells, cell_selector);
        grid_cell_values = geospm.reports.select_cell_values(grid_cells, cell_fields);
        
        summaries = unpack_summaries(grid_cells, grid_cell_values, render_options.slice_name, parent_dir, dataset_cache, dataset_aliases);
        
        group_id = lower(group_value.label);
        group_id = regexprep(group_id, '\s+', '_');

        file_name = fullfile(parent_dir, [output_name sprintf('_%s_%s', group_id) '.csv']);
        save_summaries_grid(file_name, summaries, group_row_values, group_column_values, render_options);
    end
end


function grid_cell_values = unpack_summaries(grid_cells, grid_cell_values, slice_name, base_directory, dataset_cache, dataset_aliases)
    
    for index=1:numel(grid_cell_values)
        values = grid_cell_values{index};

        if isempty(values)
            continue;
        end
        
        % This is hard-coded for now!
        mask = values{1}.content;
        mask_traces = values{2}.content;

        slice_map = hdng.experiments.SliceMap(mask.slice_names);
        slice_index = slice_map.index_for_name(slice_name, 0);
        
        if slice_index == 0
            slice_index = numel(mask_traces.shape_paths);
        end
        
        slice_path = fullfile(base_directory, mask_traces.shape_paths{slice_index});
        slice_geometry = hdng.geometry.FeatureGeometry.load(slice_path);
        polygons = slice_geometry.collection;

        grid_cell = grid_cells{index};
        record = grid_cell.unsorted_records{index};
        spatial_data_specifier = record('configuration.spatial_data_specifier');
        spatial_data_specifier = spatial_data_specifier.content;
        dataset_path = spatial_data_specifier.file_path.content;
        
        dataset = load_dataset(dataset_path, dataset_cache, dataset_aliases);

    end
end

function result = load_dataset(file_path, cache, aliases)
    
    if ~cache.holds_key(file_path)
        
        if aliases.holds_key(file_path)
            actual_file_path = aliases(file_path);
        end

        data_opts = detectImportOptions(actual_file_path, 'VariableNamingRule', 'preserve');
        data_variable_names = data_opts.VariableNames';
    
        data_values = readmatrix(actual_file_path, data_opts);
        %data_values = data_values(:, selector);
        %data_variable_names = data_variable_names(selector);
        
        data_descriptor = create_descriptor();
        data_descriptor.data = data_values;
        data_descriptor.variable_names = data_variable_names;
    
        for index=1:numel(data_variable_names)
            data_descriptor.identifiers.(data_variable_names{index}) = index;
        end
        
        cache(file_path) = data_descriptor;
    end

    result = cache(file_path);
end


function result = create_descriptor()

    result = struct();
    result.data = [];
    result.variable_names = {};
    result.field_names = {};
    result.identifiers = struct();
end


