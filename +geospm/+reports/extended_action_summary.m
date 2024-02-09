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

function extended_action_summary(base_directory, output_name, render_options, grid_options, varargin)
    
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

    if ~isfield(options, 'skip_preprocessing')
        options.skip_preprocessing = false;
    end

    if ~isfield(options, 'action_fn')
        options.action_fn = [];
    end

    if ~isfield(options, 'action_options')
        options.action_options = struct();
    end
    
    
    studies = scan_regional_directories(base_directory, options.suffix);

    studies = studies(1);
    
    tmp_dir = hdng.utilities.make_timestamped_directory(base_directory);
    
    host_name = options.host_name;
    clear_source_refs = options.clear_source_refs;
    dataset_aliases = options.dataset_aliases;
    skip_preprocessing = options.skip_preprocessing;
    action_fn = options.action_fn;
    action_options = options.action_options;

    skip_preprocessing = true;

    options = rmfield(options, 'host_name');
    options = rmfield(options, 'clear_source_refs');
    options = rmfield(options, 'dataset_aliases');
    options = rmfield(options, 'skip_preprocessing');
    options = rmfield(options, 'action_fn');
    options = rmfield(options, 'action_options');
    
    options.do_debug = true;
    
    if ~skip_preprocessing

        arguments = hdng.utilities.struct_to_name_value_sequence(options);
        
        cmds = cell(size(studies));
        
        for index=1:numel(studies)
            
            study = studies(index);

            cmds{index} = geospm.schedules.create_cmd(...
                @geospm.reports.preprocess_study_records, ...
                study.identifier, study.directory, ...
                {study.directory, study.identifier, grid_options}, ...
                struct());
        end
        
        geospm.schedules.run_parallel_cmds(tmp_dir, cmds, arguments{:});
    end

    dataset_cache = hdng.utilities.Dictionary();

    volume_generators = hdng.utilities.Dictionary();

    group_widths = [];
    group_heights = [];

    studies(1).groups = struct.empty;
    
    for study_index=1:numel(studies)
        
        study = studies(study_index);
        study_directory = study.directory;
        study_file = fullfile(study_directory, [study.identifier '_preprocessed.mat']);

        %[~, study_directory_name, ~] = fileparts(study_directory);

        load(study_file, 'groups', 'group_values');
        
        for index=1:numel(groups)
    
            group = groups{index};
            % group_value = group_values{index};
            
            cell_datasets = select_data_per_mask_polygon(group.grid_cells, group.grid_cell_values, render_options.slice_name, study_directory, dataset_cache, dataset_aliases, volume_generators);
        
            [group.grid_cell_contexts, group.column_values] = collapse_columns(cell_datasets, group.column_values);
            
            group_widths(end + 1) = size(group.grid_cell_contexts, 2); %#ok<AGROW>
            group_heights(end + 1) = size(group.grid_cell_contexts, 1); %#ok<AGROW>

            groups{index} = group;
        end

        study.groups = groups;
        studies(study_index) = study;
    end
    
    grid_cell_contexts = cell([sum(group_heights), max(group_widths)]);
    
    group_index = 1;
    pos = 1;

    for study_index=1:numel(studies)
        
        study = studies(study_index);
        
        for index=1:numel(study.groups)
            group = study.groups{index};

            grid_cell_contexts(pos:pos + group_heights(group_index) - 1, 1:group_widths(group_index)) = group.grid_cell_contexts;
            
            pos = pos + group_heights(group_index);
            group_index = group_index + 1;
        end
    end
    
    row_cmds = cell(size(grid_cell_contexts, 1), 1);
    
    grid_row_index = 1;

    for study_index=1:numel(studies)
            
        study = studies(study_index);
        
        for index=1:numel(study.groups)
            group = study.groups{index};
    
            for row_index=1:size(group.grid_cell_contexts, 1)
                
                cmd_options = hdng.one_struct(...
                    'study_index', index, ...
                    'study_directory', study.directory, ...
                    'volume_generators', volume_generators, ...
                    'grid_row_index', grid_row_index, ...
                    'row_datasets', group.grid_cell_contexts(row_index, :), ...
                    'row_value', group.row_values{row_index}, ...
                    'column_values', group.column_values(row_index, :), ...
                    'tmp_dir', tmp_dir);
                
                row_dir = fullfile(tmp_dir, sprintf('%d', grid_row_index));
                
                [status, msg] = mkdir(row_dir);

                if ~status
                    error(msg);
                end

                row_cmds{grid_row_index} = geospm.schedules.create_cmd(...
                    action_fn, ...
                    study.identifier, row_dir, ...
                    {tmp_dir, study.identifier, cmd_options, action_options}, ...
                    struct());
                
                grid_row_index = grid_row_index + 1;
            end
        end
    end
    
    row_cmd_selector = cellfun(@(x) ~isempty(x), row_cmds, 'UniformOutput', true);

    geospm.schedules.run_parallel_cmds(tmp_dir, row_cmds(row_cmd_selector), 'do_debug', options.do_debug);
    
    grid_row_index = 1;
    
    all_study_betas = [];
    all_study_beta_data = [];

    for study_index=1:numel(studies)
            
        study = studies(study_index);
        
        for index=1:numel(study.groups)
            group = study.groups{index};
    
            for row_index=1:size(group.grid_cell_contexts, 1)
                
                row_dir = fullfile(tmp_dir, sprintf('%d', grid_row_index));
                rmdir(row_dir, 's');

                grid_row_index = grid_row_index + 1;
            end
        end

        all_results = '';
        all_betas = [];
        all_beta_data = [];

        for response_index=1:numel(action_options.response_names)

            response_name = action_options.response_names{response_index};
    
            for variant_index=1:numel(action_options.variant_names)
        
                variant_name = action_options.variant_names{variant_index};
                    
                interaction_name = sprintf('%s_x_%s', variant_name, response_name);
    
                file_directory = fullfile(tmp_dir, study.identifier, interaction_name);
    
                results_file = fullfile(file_directory, 'dataset_all_results.txt');
                results = hdng.utilities.load_text(results_file);
                all_results = [all_results, newline, newline, results]; %#ok<AGROW>

                betas_file = fullfile(file_directory, 'betas.csv');
                betas = readcell(betas_file);
                
                betas = [cell(size(betas, 1), 1), betas]; %#ok<AGROW>
                
                for row_index=1:size(betas, 1)
                    betas{row_index, 1} = interaction_name;
                end
                
                betas{1, 1} = 'interaction';

                if ~isempty(all_betas)
                    betas = betas(2:end, :);
                end
                
                all_betas = [all_betas; betas]; %#ok<AGROW>


                beta_data_file = fullfile(file_directory, 'beta_data.csv');
                beta_data = readcell(beta_data_file);

                beta_data = [cell(size(beta_data, 1), 1), beta_data]; %#ok<AGROW>
                
                for row_index=1:size(beta_data, 1)
                    beta_data{row_index, 1} = interaction_name;
                end
                
                beta_data{1, 1} = 'interaction';

                if ~isempty(all_beta_data)
                    beta_data = beta_data(2:end, :);
                end
                
                all_beta_data = [all_beta_data; beta_data]; %#ok<AGROW>
            end
        end
        
        results_file = fullfile(tmp_dir, study.identifier, 'all_results.txt');
        hdng.utilities.save_text(all_results, results_file);


        betas_file = fullfile(tmp_dir, study.identifier, 'all_betas.csv');
        writecell(all_betas, betas_file);

        all_betas = [cell(size(all_betas, 1), 1), all_betas]; %#ok<AGROW>
        
        for row_index=1:size(all_betas, 1)
            region = split(study.identifier, '_');
            all_betas{row_index, 1} = region{1};
        end
        
         all_betas{1, 1} = 'study';

        if ~isempty(all_study_betas)
            all_betas = all_betas(2:end, :);
        end

        all_study_betas = [all_study_betas; all_betas]; %#ok<AGROW>
        
        %#######

        beta_data_file = fullfile(tmp_dir, study.identifier, 'all_beta_data.csv');
        writecell(all_beta_data, beta_data_file);

        
        all_beta_data = [cell(size(all_beta_data, 1), 1), all_beta_data]; %#ok<AGROW>
        
        for row_index=1:size(all_beta_data, 1)
            region = split(study.identifier, '_');
            all_beta_data{row_index, 1} = region{1};
        end
        
         all_beta_data{1, 1} = 'study';

        if ~isempty(all_study_beta_data)
            all_beta_data = all_beta_data(2:end, :);
        end

        all_study_beta_data = [all_study_beta_data; all_beta_data]; %#ok<AGROW>
    end
    
    betas_file = fullfile(tmp_dir, 'all_study_betas.csv');
    writecell(all_study_betas, betas_file);

    betas_file = fullfile(tmp_dir, 'all_study_beta_data.csv');
    writecell(all_study_beta_data, betas_file);
    
    %{
    [status, msg] = rmdir(tmp_dir, 's');
    
    if ~status
        error(msg);
    end
    %}
    
end

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

function grid_cell_values = select_data_per_mask_polygon(grid_cells, grid_cell_values, slice_name, base_directory, dataset_cache, dataset_aliases, volume_generators)
    
    for index=1:numel(grid_cell_values)
        values = grid_cell_values{index};

        if isempty(values)
            continue;
        end
        
        % This is hard-coded for now!
        mask = values{1}.content;
        mask_traces = values{2}.content;
        
        context = geospm.volumes.RenderContext();

        mask_volume_set = geospm.volumes.VolumeSet();
        mask_volume_set.file_paths = {fullfile(base_directory, mask.scalars.path)};

        context.image_volumes = mask_volume_set;

        mask_volume = context.load_image_volumes();
        mask_volume = mask_volume{1};

        slice_map = hdng.experiments.SliceMap(mask.slice_names);
        slice_index = slice_map.index_for_name(slice_name, 0);
        
        if slice_index == 0
            slice_index = numel(mask_traces.shape_paths);
        end
        
        slice_path = fullfile(base_directory, mask_traces.shape_paths{slice_index});
        
        id = 'map:shapefile:missingDBF';

        warning('off', id);
        
        try
            
            slice_geometry = hdng.geometry.FeatureGeometry.load(slice_path);

        catch ME
            warning('on', id);
            rethrow(ME);
        end
            
        warning('on', id);

        mask_slice = mask_volume.data(:, :, slice_index);

        polygons = slice_geometry.collection;

        grid_cell = grid_cells{index};
        
        %{
        if isempty(grid_cell) || isempty(polygons)
            grid_cell_values{index} = [];
            continue
        end
        %}

        record = grid_cell.unsorted_records{1};


        spm_output_path = record('result.spm_output_directory').content.path;
        [session_directory, ~, ~] = fileparts(spm_output_path);
        spm_input_path = fullfile(base_directory, session_directory, 'spm_input');

        
        if ~volume_generators.holds_key(spm_input_path)
            
            specifier = struct();
            
            specifier.smoothing_levels = record('configuration.smoothing_levels').content;
            specifier.smoothing_levels = cell2mat(specifier.smoothing_levels);
            specifier.smoothing_levels_p_value = record('configuration.smoothing_levels_p_value').content;
            specifier.smoothing_method = record('configuration.smoothing_method').content;

            volume_generators(spm_input_path) = specifier;
        end
        
        spatial_data_specifier = record('configuration.spatial_data_specifier');
        spatial_data_specifier = spatial_data_specifier.content;

        min_location = cell2mat(spatial_data_specifier.min_location.content);
        max_location = cell2mat(spatial_data_specifier.max_location.content);
        cell_size = (max_location - min_location) ./ size(mask_slice)';

        dataset_path = spatial_data_specifier.file_path.content;
        
        dataset = load_dataset(dataset_path, dataset_cache, dataset_aliases);
        
        if ~isempty(polygons)
            
            ctx = hdng.rasters.RasterContext([size(mask_slice) 1]);

            selection = query_dataset_per_polygon(dataset, polygons);
            
            polygon_datasets = [];

            for p=1:polygons.N_elements
                
                polygon_dataset = dataset;
                polygon_dataset.data = polygon_dataset.data(selection(p, :), :);
                polygon_dataset.polygon = polygons.nth_element(p);
                polygon_dataset.min_location = min_location;
                polygon_dataset.max_location = max_location;
                polygon_dataset.cell_size = cell_size;
                polygon_dataset.slice_index = slice_index;
                polygon_dataset.record = record;

                coordinates = [polygon_dataset.polygon.vertices.x';
                               polygon_dataset.polygon.vertices.y'];

                coordinates = (coordinates - min_location) ./ cell_size + 1;
                
                vertices = hdng.geometry.Vertices.define(coordinates');
                polygon = polygon_dataset.polygon.substitute_vertices(vertices);
                
                ctx.set_fill(0);
                ctx.fill_rect(0, 0, ctx.width, ctx.height);
        
                selector = zeros([1, numel(polygon.N_points)], 'logical');
                
                for r=1:polygon.N_rings
                    ring = polygon.nth_ring(r, true);
                    selector(r) = ring.vertices.is_clockwise_xy(1, ring.N_points);
                end
        
                rings = find(selector);
                ctx.set_fill(1);
                
                for r=1:numel(rings)
                    ring = polygon.nth_ring(rings(r), true);
                    coords = cast(ring.vertices.coordinates, 'double') - 1;
                    ctx.fill_polygon(coords(:, 1), coords(:, 2));
                end
        
                holes = find(~selector);
                ctx.set_fill(0);
        
                for h=1:numel(holes)
                    ring = polygon.nth_ring(holes(h), true);
                    coords = cast(ring.vertices.coordinates, 'double') - 1;
                    ctx.fill_polygon(coords(:, 1), coords(:, 2));
                end
                
                polygon_dataset.polygon_mask = cast(ctx.canvas, 'logical');

                polygon_datasets = [polygon_datasets; polygon_dataset]; %#ok<AGROW>
            end
        else

            polygon_datasets = dataset;
            polygon_datasets.data = double([0, size(dataset.data, 2)]);
        end

        grid_cell_values{index} = polygon_datasets;
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

function result = query_dataset_per_polygon(dataset, polygons)
    
    result = zeros(polygons.N_elements, size(dataset.data, 1), 'logical');

    x = dataset.data(:, dataset.identifiers.easting);
    y = dataset.data(:, dataset.identifiers.northing);

    
    for index=1:polygons.N_elements
        polygon = polygons.nth_element(index);
        polygon = polygon.collect_nan_delimited_ring_vertices();

        result(index, :) = inpolygon(x, y, polygon(:, 1), polygon(:, 2))';
    end
end

