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
    build_render_cells(studies, preprocessing_identifier, ...
        input_attachment, render_attachment, ...
        file_paths_attachment, cell_layer_fn, ...
        selected_layer_categories, layer_options, render_options, ...
        shared_variables ...
        )

        %cell_generator_fn, cell_generator_state, ...
        %shared_variables, layer_value_paths, clear_source_refs, renderer, ...
        %selected_layer_categories, render_options)

    %layer_options:
    %   layer_value_paths
    %   clear_source_refs
    %   path_prefix

    group_widths = [];
    group_heights = [];

    if ~isfield(studies(1), 'record_grid')
        studies(1).record_grid = [];
    end

    for study_index=1:numel(studies)
        
        study = studies(study_index);
        study_directory = study.directory;
        study_file = fullfile(study_directory, [study.identifier preprocessing_identifier '_preprocessed.mat']);

        [~, study_directory_name, ~] = fileparts(study_directory);

        layer_options.path_prefix = study_directory_name;

        if isempty(study.record_grid)
            record_grid = geospm.reports.RecordGrid.load(study_file);
        else
            record_grid = study.record_grid;
        end

        context = geospm.reports.ReportContext(study_directory, shared_variables);
        context.render_layer_categories = selected_layer_categories;
        
        for index=1:numel(record_grid.groups)
    
            group = record_grid.groups{index};
            
            group.cell_attachments.(render_attachment) = ...
                context.create_cell_presentation_stacks( ...
                    group, input_attachment, ...
                    shared_variables.resource_manager, cell_layer_fn, layer_options, ...
                    render_options); 
            
            group.collapse_across_columns();
            
            group.cell_attachments.(file_paths_attachment) = ...
                get_file_paths_from_volume(...
                    group.cell_attachments.(render_attachment), ...
                    shared_variables.host_name, true);

            group_widths(end + 1) = size(group.cells, 2); %#ok<AGROW>
            group_heights(end + 1) = size(group.cells, 1); %#ok<AGROW>
        end


        study.record_grid = record_grid;
        studies(study_index) = study;
    end
end


function [file_paths, identifiers] = get_file_paths_from_volume(grid_cell_contexts, url_prefix, use_scalars)

   file_paths = cell(size(grid_cell_contexts));
   identifiers = cell(size(grid_cell_contexts));

    for index=1:numel(grid_cell_contexts)
    
        cell_context = grid_cell_contexts{index};
        
        if isempty(cell_context)
            continue
        end

        layers = cell_context.stack.selected_layers;

        for k=1:numel(layers)
            layer = layers{k};

            if ~isa(layer, 'geospm.validation.VolumeLayer')
                continue;
            end
            
            if use_scalars
                target = layer.scalars;
            else
                target = layer.image;
            end

            [url, identifier] = geospm.validation.PresentationRenderer.build_resource_url_and_identifier(url_prefix, target.source_ref, target.path); 
            url = regexprep(url, '^\w+:', '');
            file_paths{index} = url;
            identifiers{index} = identifier;
        end
    end
end

