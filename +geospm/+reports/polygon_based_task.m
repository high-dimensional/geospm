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

function studies = polygon_based_task(base_directory, output_name, render_options, grid_options, varargin)
    
    options = hdng.utilities.parse_struct_from_varargin(varargin{:});

    if ~isfield(options, 'do_debug')
        options.do_debug = false;
    end

    if ~isfield(options, 'host_name')
        options.host_name = 'http://localhost:9999';
    end

    if ~isfield(options, 'clear_source_refs')
        options.clear_source_refs = false;
    end

    if ~isfield(options, 'dataset_aliases')
        options.dataset_aliases = hdng.utilities.Dictionary();
    end

    if ~isfield(options, 'force_preprocessing')
        options.force_preprocessing = false;
    end

    if ~isfield(options, 'action_fn')
        options.action_fn = [];
    end

    if ~isfield(options, 'action_options')
        options.action_options = struct();
    end

    if ~isfield(options, 'cell_mask_volume_fn')
        options.cell_mask_volume_fn = @get_cell_values;
    end
    
    preprocessed_attachment = 'preprocessed_values';
    dataset_attachment = 'polygon_datasets';
    
    studies = geospm.reports.scan_regional_directories(base_directory, options.suffix);

    studies = studies(1);
    
    tmp_dir = hdng.utilities.make_timestamped_directory(base_directory);
    
    %host_name = options.host_name;
    %clear_source_refs = options.clear_source_refs;
    
    preprocessing_identifier = '_poly';

    geospm.reports.build_record_grids_for_studies(studies, ...
        preprocessing_identifier, ...
        grid_options.row_field, grid_options.column_field, grid_options, ...
        'do_debug', options.do_debug, ...
        'force_preprocessing',options.force_preprocessing, ...
        'output_dir', tmp_dir);
    
    shared_variables = geospm.reports.SharedVariables([], options.dataset_aliases);
    
    [studies, group_widths, group_heights] = ...
        geospm.reports.build_polygon_datasets(studies, ...
        preprocessing_identifier, ...
        preprocessed_attachment, dataset_attachment, ...
        shared_variables, ...
        options.cell_mask_volume_fn, render_options.slice_name);
    
    datasets_per_cell = gather_cell_attachments(studies, dataset_attachment, group_widths, group_heights);
    
    action_fn = options.action_fn;
    action_options = options.action_options;

    row_cmds = build_row_cmds_for_cells(studies, dataset_attachment, size(datasets_per_cell, 1), action_fn, action_options, tmp_dir, shared_variables);
    row_cmd_selector = cellfun(@(x) ~isempty(x), row_cmds, 'UniformOutput', true);

    geospm.schedules.run_parallel_cmds(tmp_dir, row_cmds(row_cmd_selector), 'do_debug', options.do_debug);

    aggregate(studies, dataset_attachment, tmp_dir, action_options);

    %{
    [status, msg] = rmdir(tmp_dir, 's');
    
    if ~status
        error(msg);
    end
    %}
    
end

function result = gather_cell_attachments(studies, cell_attachment, group_widths, group_heights)

    result = cell([sum(group_heights), max(group_widths)]);
    
    group_index = 1;
    pos = 1;

    for study_index=1:numel(studies)
        
        study = studies(study_index);
        
        for index=1:numel(study.record_grid.groups)
            group = study.record_grid.groups{index};

            result(pos:pos + group_heights(group_index) - 1, 1:group_widths(group_index)) = group.cell_attachments.(cell_attachment);
            
            pos = pos + group_heights(group_index);
            group_index = group_index + 1;
        end
    end
end

function row_cmds = build_row_cmds_for_cells(studies, dataset_attachment, expected_row_number, action_fn, action_options, tmp_dir, shared_variables)

    row_cmds = cell(expected_row_number, 1);
    
    grid_row_index = 1;

    for study_index=1:numel(studies)
            
        study = studies(study_index);
        
        for index=1:numel(study.record_grid.groups)

            group = study.record_grid.groups{index};
            dataset_cells = group.cell_attachments.(dataset_attachment);
    
            for row_index=1:size(dataset_cells, 1)
                
                cmd_options = hdng.one_struct(...
                    'study_index', index, ...
                    'study_directory', study.directory, ...
                    'shared_variables', shared_variables, ...
                    'row_index', grid_row_index, ...
                    'row_datasets', dataset_cells(row_index, :), ...
                    'row_values', group.row_value_per_cell(row_index, :), ...
                    'column_values', group.column_value_per_cell(row_index, :), ...
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

function aggregate(studies, cell_attachment, tmp_dir, action_options)

    grid_row_index = 1;
    
    all_study_betas = [];
    all_study_beta_data = [];

    for study_index=1:numel(studies)
            
        study = studies(study_index);
        groups = study.record_grid.groups;
        
        for index=1:numel(groups)
            group = groups{index};
    
            for row_index=1:size(group.cell_attachments.(cell_attachment), 1)
                
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


function [values, state] = get_cell_values(cell_values, row_index, col_index, row_values, column_values, state)
    values = cell_values{row_index, col_index};
end


