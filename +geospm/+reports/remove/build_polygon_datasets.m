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

function [studies, group_widths, group_heights] = ...
    build_polygon_datasets(studies, dataset_aliases, dataset_cache, volume_generators, render_options, cell_value_fn)
    
    group_widths = [];
    group_heights = [];

    studies(1).groups = struct.empty;

    % Each study group is a cell grid of values selected by specific 
    % combination of group, row and column selector values.
    
    for study_index=1:numel(studies)
        
        study = studies(study_index);
        study_directory = study.directory;
        study_file = fullfile(study_directory, [study.identifier '_act_preprocessed.mat']);

        %[~, study_directory_name, ~] = fileparts(study_directory);

        load(study_file, 'groups', 'group_values');

        grid_env = geospm.reports.create_grid_environment(render_options.slice_name, study_directory, dataset_cache, dataset_aliases, volume_generators);
        
        for index=1:numel(groups)
    
            group = groups{index};
            group_value = group_values{index}; %#ok<NASGU>
            
            cell_datasets = geospm.reports.select_data_per_polygon(group, grid_env, cell_value_fn);
            
            [group.grid_cell_contexts, group.column_values] = geospm.reports.collapse_columns(cell_datasets, group.column_values);
            
            group_widths(end + 1) = size(group.grid_cell_contexts, 2); %#ok<AGROW>
            group_heights(end + 1) = size(group.grid_cell_contexts, 1); %#ok<AGROW>

            groups{index} = group;
        end

        study.groups = groups;
        studies(study_index) = study;
    end
end

