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

    %studies = studies(1);
    
    tmp_dir = hdng.utilities.make_timestamped_directory(base_directory);
    
    %host_name = options.host_name;
    %clear_source_refs = options.clear_source_refs;
    dataset_aliases = options.dataset_aliases;
    skip_preprocessing = options.skip_preprocessing;
    action_fn = options.action_fn;
    action_options = options.action_options;

    %skip_preprocessing = true;

    options = rmfield(options, 'host_name');
    options = rmfield(options, 'clear_source_refs');
    options = rmfield(options, 'dataset_aliases');
    options = rmfield(options, 'skip_preprocessing');
    options = rmfield(options, 'action_fn');
    options = rmfield(options, 'action_options');
    
    %options.do_debug = false;
    
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
    
    [studies, group_widths, group_heights] = ...
        build_polygon_datasets(studies, dataset_aliases, dataset_cache, volume_generators, render_options);
    
    grid_cell_contexts = gather_grid_cell_contexts(studies, group_widths, group_heights);

    row_cmds = build_row_cmds_for_cells(studies, size(grid_cell_contexts, 1), action_fn, action_options, tmp_dir, volume_generators);
    row_cmd_selector = cellfun(@(x) ~isempty(x), row_cmds, 'UniformOutput', true);

    geospm.schedules.run_parallel_cmds(tmp_dir, row_cmds(row_cmd_selector), 'do_debug', options.do_debug);
    aggregate(studies, tmp_dir, action_options);

    %{
    [status, msg] = rmdir(tmp_dir, 's');
    
    if ~status
        error(msg);
    end
    %}
    
end

function [studies, group_widths, group_heights] = ...
    build_polygon_datasets(studies, dataset_aliases, dataset_cache, volume_generators, render_options)
    
    group_widths = [];
    group_heights = [];

    studies(1).groups = struct.empty;

    % Each study group is a cell grid of values selected by specific 
    % combination of group, row and column selector values.
    
    for study_index=1:numel(studies)
        
        study = studies(study_index);
        study_directory = study.directory;
        study_file = fullfile(study_directory, [study.identifier '_preprocessed.mat']);

        %[~, study_directory_name, ~] = fileparts(study_directory);

        load(study_file, 'groups', 'group_values');
        
        for index=1:numel(groups)
    
            group = groups{index};
            group_value = group_values{index}; %#ok<NASGU>
            
            cell_datasets = geospm.reports.select_data_per_mask_polygon(group.grid_cells, group.grid_cell_values, render_options.slice_name, study_directory, dataset_cache, dataset_aliases, volume_generators);
            
            [group.grid_cell_contexts, group.column_values] = geospm.reports.collapse_columns(cell_datasets, group.column_values);
            
            group_widths(end + 1) = size(group.grid_cell_contexts, 2); %#ok<AGROW>
            group_heights(end + 1) = size(group.grid_cell_contexts, 1); %#ok<AGROW>

            groups{index} = group;
        end

        study.groups = groups;
        studies(study_index) = study;
    end
end

function grid_cell_contexts = gather_grid_cell_contexts(studies, group_widths, group_heights)

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
end

function row_cmds = build_row_cmds_for_cells(studies, expected_row_number, action_fn, action_options, tmp_dir, volume_generators)

    row_cmds = cell(expected_row_number, 1);
    
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
end

function aggregate(studies, tmp_dir, action_options)

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
end

