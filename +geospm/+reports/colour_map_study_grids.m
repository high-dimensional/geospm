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

function [legends, directories] = colour_map_study_grids(studies, group_heights, group_widths, ...
            specifier, render_attachment, file_paths_attachment, tmp_dir, ...
            shared_variables)
    
    if ~isfield(specifier, 'colour_map')
        specifier.colour_map = hdng.colour_mapping.GenericColourMap.twilight_27([], true);
    end

    directories = {};

    batch_fn = str2func(['batch_' , specifier.batch]);
    
    [combined_cells, grid_column_values, study_spans] = geospm.reports.combine_study_groups(...
        studies, group_heights, group_widths, {render_attachment, file_paths_attachment});
    
    render_cells = combined_cells.(render_attachment);
    file_path_cells = combined_cells.(file_paths_attachment);
    
    if specifier.combine_studies
        [batches, directories] = batch_fn(specifier, render_cells, file_path_cells, grid_column_values, tmp_dir);
        study_legends = geospm.reports.apply_colour_map(specifier.colour_map, batches, shared_variables);
        
        legends = cell(numel(studies), 1);

        for index=1:numel(studies)
            legends{index} = study_legends;
        end

    else
        
        start_row = 1;

        legends = cell(numel(studies), 1);
        
        for index=1:numel(studies)
            study = studies(index);
            study_span = study_spans(index);
    
            study_render_cells = render_cells(start_row:start_row + study_span - 1, :);
            study_file_path_cells = file_path_cells(start_row:start_row + study_span - 1, :);
            study_column_values = grid_column_values(start_row:start_row + study_span - 1, :);
    
                        
            study_dir = fullfile(tmp_dir, study.identifier);
            [status,msg] = mkdir(study_dir);
    
            if ~status
                error(msg);
            end
    
            batches = batch_fn(specifier, study_render_cells, study_file_path_cells, study_column_values, study_dir);
            legends{index} = geospm.reports.apply_colour_map(specifier.colour_map, batches, shared_variables);
            
            start_row = start_row + study_span;

            directories{end + 1} = study_dir; %#ok<AGROW>
        end
    end
end


function [result, directories] = batch_all(specifier, grid_cell_contexts, grid_volume_file_paths, grid_column_values, tmp_dir)

    all_dir = fullfile(tmp_dir, 'all_images');
    [status,msg] = mkdir(all_dir);

    if ~status
        error(msg);
    end

    directories{end + 1} = all_dir;

    volume_set = geospm.volumes.VolumeSet();
    volume_set.file_paths = grid_volume_file_paths(:);
    volume_set.optional_output_names = geospm.reports.derive_unique_output_names(volume_set.file_paths);

    volume_set.addprop('output_directory');
    volume_set.output_directory = all_dir;
    
    volume_set.addprop('cell_contexts');
    volume_set.cell_contexts = grid_cell_contexts(:);
    
    result = {volume_set};
end

function [result, directories] = batch_per_column(specifier, grid_cell_contexts, grid_volume_file_paths, grid_column_values, tmp_dir)

    result = cell(size(grid_cell_contexts, 2), 1);
    directories = {};

    for col_index=1:size(grid_cell_contexts, 2)

        col_dir = fullfile(tmp_dir, sprintf('column_%d_images', col_index));
        [status,msg] = mkdir(col_dir);

        if ~status
            error(msg);
        end

        directories{end + 1} = col_dir; %#ok<AGROW>

        volume_set = geospm.volumes.VolumeSet();
        volume_set.file_paths = grid_volume_file_paths(:, col_index);
        volume_set.optional_output_names = geospm.reports.derive_unique_output_names(volume_set.file_paths);

        volume_set.addprop('output_directory');
        volume_set.output_directory = col_dir;
        
        volume_set.addprop('cell_contexts');
        volume_set.cell_contexts = grid_cell_contexts(:, col_index);
        
        result{col_index} = volume_set;
    end
end



function [result, directories] = batch_bipartite(specifier, grid_cell_contexts, grid_volume_file_paths, grid_column_values, tmp_dir)

    %selector = zeros(size(grid_cell_contexts), 'logical');
    
    selector = cellfun(@(x) any(strcmp(x.label, specifier.selected_column_values)), grid_column_values);
    selectors = {selector, ~selector};
    result = {[], []};
    directories = {};
    
    for index=1:numel(result)

        selector = selectors{index};

        batch_dir = fullfile(tmp_dir, sprintf('batch_%d_images', index));
        [status,msg] = mkdir(batch_dir);

        if ~status
            error(msg);
        end

        directories{end + 1} = batch_dir; %#ok<AGROW>

        volume_set = geospm.volumes.VolumeSet();
        volume_set.file_paths = grid_volume_file_paths(selector(:));
        volume_set.optional_output_names = geospm.reports.derive_unique_output_names(volume_set.file_paths);

        volume_set.addprop('output_directory');
        volume_set.output_directory = batch_dir;
        
        volume_set.addprop('cell_contexts');
        volume_set.cell_contexts = grid_cell_contexts(selector(:));
        
        result{index} = volume_set;
    end
end
