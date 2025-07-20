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

function grid_summary_svg_2(base_directory, output_name, render_options, grid_options, varargin)
    
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

    if ~isfield(options, 'dataset_aliases')
        options.dataset_aliases = hdng.utilities.Dictionary();
    end

    if ~isfield(options, 'force_preprocessing')
        options.force_preprocessing = false;
    end

    if ~isfield(options, 'cell_layer_fn')
        options.cell_layer_fn = @get_cell_values;
    end
    
    if ~isfield(options, 'layer_value_paths')
        options.layer_value_paths = {...
            'configuration.image_layers', ...
            'result.terms.contrast', ...
            'result.terms.mask_traces', ...
        };
    end

    if ~isfield(options, 'adjust_colour_mapping')
        options.adjust_colour_mapping = false;
    end

    if ~isfield(options, 'colour_mapping')
        options.colour_mapping = hdng.one_struct('batch', 'per_column');
        options.colour_mapping.selected_column_values = {...
        };
    end
    
    studies = geospm.reports.scan_regional_directories(base_directory, options.suffix);
    
    tmp_dir = hdng.utilities.make_timestamped_directory(base_directory);

    renderer = geospm.validation.SVGRenderer();
    renderer.host_name = options.host_name;
    renderer.resource_identifier_expr = sprintf('.*(?<identifier>%spresentation%s(map_background.png|map_foreground.png))$', filesep);

    selected_layer_categories = {'underlay', 'content', 'overlay'};
    
    label_attributes = hdng.utilities.Dictionary();
    label_attributes('font-family') = 'Barlow, sans';
    label_attributes('font-weight') = '600';
    
    preprocessing_identifier = '_poly';

    geospm.reports.build_record_grids_for_studies(studies, ...
        preprocessing_identifier, ...
        grid_options.row_field, grid_options.column_field, grid_options, ...
        'do_debug', options.do_debug, ...
        'force_preprocessing', options.force_preprocessing, ...
        'output_dir', tmp_dir);

    shared_variables = geospm.reports.SharedVariables([], options.dataset_aliases);

    context_attachment = 'render_contexts';
    file_paths_attachment = 'grid_volume_file_paths';

    [studies, group_widths, group_heights] = ...
        geospm.reports.build_render_contexts(studies, preprocessing_identifier, ...
        'preprocessed_values', context_attachment, options.cell_layer_fn, file_paths_attachment, ...
        shared_variables, options.layer_value_paths, options.clear_source_refs, renderer, ...
        selected_layer_categories, render_options);

    [combined_cells, grid_column_values] = combine_study_groups(studies, group_heights, group_widths, {context_attachment, file_paths_attachment});

    grid_cell_contexts = combined_cells.(context_attachment);
    grid_volume_file_paths = combined_cells.(file_paths_attachment);

    if options.adjust_colour_mapping
        apply_column_wise_colour_maps( ...
            grid_cell_contexts, ...
            grid_volume_file_paths, ...
            tmp_dir, host_name, resources, render_options);
    end
    
    if ~isempty(options.colour_mapping)
        batch_fn = str2func(['batch_' options.colour_mapping.batch]);
        batches = batch_fn(grid_cell_contexts, grid_volume_file_paths, grid_column_values, tmp_dir, options.colour_mapping);
        apply_colour_maps(batches, renderer.host_name, shared_variables.resources, render_options);
    end


    grid_rows = struct.empty;
    grid_row_index = 1;

    service = hdng.resources.ResourceService();
    requests = renderer.launch_resource_requests(service, shared_variables.resources); %#ok<NASGU>
    
    % Not running asynchronously, so all requests should have stopped
    if service.total_requests == service.stopped_requests
        
        for study_index=1:numel(studies)
                
            study = studies(study_index);
            groups = study.record_grid.groups;
            
            for index=1:numel(groups)
                group = groups{index};
                group_cell_contexts = group.cell_attachments.(context_attachment);

                for row_index=1:size(group_cell_contexts, 1)
        
                    grid_row = geospm.reports.render_grid_row(group_cell_contexts(row_index, :), group.row_values(row_index), group.column_values(row_index, :), renderer, label_attributes, render_options);
                    
                    render_options.origin(2) = render_options.origin(2) + render_options.cell_spacing(2) + grid_row.grid_size(2);
                    
                    grid_rows = [grid_rows; grid_row]; %#ok<AGROW>
                    grid_row_index = grid_row_index + 1;
                end
            end
        end

    end

    requests = []; %#ok<NASGU>
    
    [status, msg] = rmdir(tmp_dir, 's');
    
    if ~status
        error(msg);
    end
    
    grid_svg = geospm.reports.render_combined_grid(grid_rows, renderer, shared_variables.resources, render_options);
    hdng.utilities.save_text(grid_svg, fullfile(tmp_dir, [output_name '.svg']));

end

function [combination, column_values] = combine_study_groups(studies, group_heights, group_widths, attachments)

    combination_size = [sum(group_heights), max(group_widths)];

    column_values = cell(combination_size);

    combination = struct();

    for k=1:numel(attachments)
        attachment = attachments{k};
        combination.(attachment) = cell(combination_size);
    end
    
    group_index = 1;
    pos = 1;

    for study_index=1:numel(studies)
        
        study = studies(study_index);
        groups = study.record_grid.groups;
        
        for index=1:numel(groups)
            group = groups{index};

            column_values(pos:pos + group_heights(group_index) - 1, 1:group_widths(group_index)) = group.column_values;

            for k=1:numel(attachments)
                attachment = attachments{k};

                combination.(attachment)(pos:pos + group_heights(group_index) - 1, 1:group_widths(group_index)) = ...
                    group.cell_attachments.(attachment);
            end

            pos = pos + group_heights(group_index);
            group_index = group_index + 1;
        end
    end
end

function update_resource_paths(grid_cell_contexts, image_paths, resources, url_prefix)

    path_index = 1;

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
            
            [~, identifier] = geospm.validation.PresentationRenderer.build_resource_url_and_identifier(url_prefix, layer.image.source_ref, layer.image.path); 
            
            %identifier = image_identifiers{path_index};
            resource = resources(identifier);
            
            if isa(resource, 'hdng.utilities.DictionaryError')
                error('Implementation error: Incorrect resource identifier');
            end
            
            resources.remove(identifier);

            layer.image.path = image_paths{path_index};
            layer.image.source_ref = '';
            
            [url, identifier] = geospm.validation.PresentationRenderer.build_resource_url_and_identifier(url_prefix, layer.image.source_ref, layer.image.path); 
            
            resource.identifier = identifier;
            resource.url = url;

            resources(resource.identifier) = resource;

            path_index = path_index + 1;
        end
    end
end

function apply_column_wise_colour_maps(grid_cell_contexts, grid_volume_file_paths, tmp_dir, host_name, resources, render_options)
    
    render_options.host_name = host_name;

    if startsWith(host_name, 'file:')
        host_name = host_name(numel('file:') + 1:end);
    end

    if ~isfield(render_options, 'colour_map')
        render_options.colour_map = hdng.colour_mapping.GenericColourMap.twilight_27();
        render_options.colour_map.colour_map_mode = hdng.colour_mapping.ColourMap.LAYER_MODE;
    end

    renderer = geospm.volumes.ColourMapping();
    renderer.colour_map = render_options.colour_map;

    settings = geospm.volumes.RenderSettings();
    
    settings.formats = {'tif'};
    %settings.grid = grid;
    %settings.crs = hdng.SpatialCRS.empty;
    settings.centre_pixels = true;
    
    for col_index=1:size(grid_cell_contexts, 2)

        col_dir = fullfile(tmp_dir, sprintf('column_%d_images', col_index));
        [status,msg] = mkdir(col_dir);

        if ~status
            error(msg);
        end

        col_contexts = grid_cell_contexts(:, col_index);
        
        volume_set = geospm.volumes.VolumeSet();
        volume_set.file_paths = grid_volume_file_paths(:, col_index);
        volume_set.optional_output_names = geospm.reports.derive_unique_output_names(volume_set.file_paths);

        context = geospm.volumes.RenderContext();
        context.render_settings = settings;

        context.image_volumes = volume_set;
        context.alpha_volumes = [];
        context.output_directory = col_dir;

        [image_paths, metadata] = renderer.render(context);
        image_paths = cellfun(@(x) x{1}, image_paths, 'UniformOutput', false);
        
        for index=1:numel(image_paths)
            path = image_paths{index};

            if startsWith(path, host_name)
                path = path(numel(host_name) + 1:end);
            end

            image_paths{index} = path;
        end

        slice_legends = metadata{1}.slice_legends;

        for index=1:numel(slice_legends)
            legend = slice_legends{index};
            %legend.render_and_save_as(300, fullfile(col_dir, sprintf('legend_z%04d.png', index)), 'Effects');
            legend_file_name = fullfile(col_dir, sprintf('legend_z%04d.svg', index));
            legend_svg = legend.as_svg(300, 20);
            hdng.utilities.save_text(legend_svg, legend_file_name);
        end
        
        update_resource_paths(col_contexts, image_paths, resources, render_options.host_name);
    end
end


function result = batch_per_column(grid_cell_contexts, grid_volume_file_paths, grid_column_values, tmp_dir, options)

    result = cell(size(grid_cell_contexts, 2), 1);

    for col_index=1:size(grid_cell_contexts, 2)

        col_dir = fullfile(tmp_dir, sprintf('column_%d_images', col_index));
        [status,msg] = mkdir(col_dir);

        if ~status
            error(msg);
        end

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



function result = batch_bipartite(grid_cell_contexts, grid_volume_file_paths, grid_column_values, tmp_dir, options)

    %selector = zeros(size(grid_cell_contexts), 'logical');
    
    selector = cellfun(@(x) any(strcmp(x.label, options.selected_column_values)), grid_column_values);
    selectors = {selector, ~selector};
    result = {[], []};
    
    for index=1:numel(result)

        selector = selectors{index};

        batch_dir = fullfile(tmp_dir, sprintf('batch_%d_images', index));
        [status,msg] = mkdir(batch_dir);

        if ~status
            error(msg);
        end

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



function apply_colour_maps(batches, host_name, resources, render_options)
    
    render_options.host_name = host_name;

    if startsWith(host_name, 'file:')
        host_name = host_name(numel('file:') + 1:end);
    end

    if ~isfield(render_options, 'colour_map')
        render_options.colour_map = hdng.colour_mapping.GenericColourMap.twilight_27();
    end

    renderer = geospm.volumes.ColourMapping();
    renderer.colour_map = render_options.colour_map;
    renderer.colour_map_mode = hdng.colour_mapping.ColourMap.LAYER_MODE;

    settings = geospm.volumes.RenderSettings();
    
    settings.formats = {'tif'};
    %settings.grid = grid;
    %settings.crs = hdng.SpatialCRS.empty;
    settings.centre_pixels = true;
    
    %for col_index=1:size(grid_cell_contexts, 2)
    for batch_index=1:numel(batches)
        
        volume_set = batches{batch_index};

        context = geospm.volumes.RenderContext();
        context.render_settings = settings;

        context.image_volumes = volume_set;
        context.alpha_volumes = [];
        context.output_directory = volume_set.output_directory;

        [image_paths, metadata] = renderer.render(context);
        image_paths = cellfun(@(x) x{1}, image_paths, 'UniformOutput', false);
        
        for index=1:numel(image_paths)
            path = image_paths{index};

            if startsWith(path, host_name)
                path = path(numel(host_name) + 1:end);
            end

            image_paths{index} = path;
        end

        slice_legends = metadata{1}.slice_legends;

        for index=1:numel(slice_legends)
            legend = slice_legends{index};
            %legend.render_and_save_as(300, fullfile(volume_set.output_directory, sprintf('legend_z%04d.png', index)), 'Effects');
            legend_file_name = fullfile(volume_set.output_directory, sprintf('legend_z%04d.svg', index));
            legend_svg = legend.as_svg(300, 20);
            hdng.utilities.save_text(legend_svg, legend_file_name);
        end
        
        update_resource_paths(volume_set.cell_contexts, image_paths, resources, render_options.host_name);
    end
end
