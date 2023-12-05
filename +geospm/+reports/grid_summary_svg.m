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

function grid_summary_svg(records, row_field, column_field, cell_selector, cell_fields, output_file, render_options, varargin)

    options = hdng.utilities.parse_struct_from_varargin(varargin{:});

    if ~isfield(options, 'host_name')
        options.host_name = 'http://localhost:9999';
    end

    if ~isfield(options, 'clear_source_refs')
        options.clear_source_refs = false;
    end

    [parent_dir, output_name, ~] = fileparts(output_file);

    tmp_dir = hdng.utilities.make_timestamped_directory(parent_dir);

    renderer = geospm.validation.SVGRenderer();

    renderer.host_name = options.host_name;
    renderer.resource_identifier_expr = '.*(?<identifier>/presentation/(map_background.png|map_foreground.png))$';
    
    clear_source_refs = options.clear_source_refs;

    options = rmfield(options, 'host_name');
    options = rmfield(options, 'clear_source_refs');

    arguments = hdng.utilities.struct_to_name_value_sequence(options);

    [groups, group_values, row_values, column_values] = ...
        geospm.reports.grid_cells_from_records(records, row_field, column_field, arguments{:});
    
    selected_layer_categories = {'underlay', 'content', 'overlay'};
    
    label_attributes = hdng.utilities.Dictionary();
    label_attributes('font-family') = 'Barlow, sans';
    label_attributes('font-weight') = '600';
    

    %slice_names = render_options.slice_names;
    %for slice_index=1:numel(slice_names)
        %render_options.slice_name = slice_names{slice_index};

        grid_rows = struct.empty;
        combined_resources = hdng.utilities.Dictionary();

        for index=1:numel(groups)
            
            group_value = group_values{index};
    
            service = hdng.resources.ResourceService();
            resources = hdng.utilities.Dictionary();
    
            group = groups{index};
    
            grid_cells = group.grid_cells(group.row_value_selector, group.column_value_selector);
            
            group_row_values = row_values(group.row_value_selector);
            group_column_values = column_values(group.column_value_selector);
    
            grid_cells = geospm.reports.match_cell_records(grid_cells, cell_selector);
            grid_cell_values = geospm.reports.select_cell_values(grid_cells, cell_fields);
            
            grid_cell_contexts = geospm.reports.create_presentation_stacks(grid_cell_values, renderer, selected_layer_categories, resources, clear_source_refs, '', render_options);
            
            if render_options.collapse_empty_cells
                tmp_grid_cell_contexts = ...
                    collapse_empty_cells(grid_cell_contexts, group_row_values, group_column_values);
                
                apply_column_wise_colour_maps(tmp_grid_cell_contexts, tmp_dir, renderer.host_name, resources, render_options);
            end

            requests = renderer.launch_resource_requests(service, resources);
            
            % Not running asynchronously, so all requests should have stopped
            if service.total_requests == service.stopped_requests
                
                for row_index=1:size(grid_cell_contexts, 1)
                    grid_row = geospm.reports.render_grid_row(grid_cell_contexts(row_index, :), group_row_values(row_index), group_column_values, renderer, label_attributes, render_options);
                    
                    render_options.origin(2) = render_options.origin(2) + render_options.cell_spacing(2) + grid_row.grid_size(2);
                    
                    grid_rows = [grid_rows; grid_row]; %#ok<AGROW>
                end
            end
    
            requests = [];
            
            if render_options.collapse_empty_cells
                
                [status, msg] = rmdir(tmp_dir, 's');
                
                if ~status
                    error(msg);
                end
                
                [status, msg] = mkdir(tmp_dir);

                if ~status
                    error(msg);
                end
                
            end

            % groups{index} = grid_cell_contexts;
    
            resources.copy(combined_resources);
        end
    
        grid_svg = geospm.reports.render_combined_grid(grid_rows, renderer, combined_resources, render_options);
        hdng.utilities.save_text(grid_svg, fullfile(parent_dir, [output_name '.svg']));
    %end
end

function result = ...
    collapse_empty_cells(grid_cell_contexts, row_values, column_values)

    result = cell(size(grid_cell_contexts));

    for index=1:size(grid_cell_contexts, 1)
        cell_selector = cellfun(@(x) ~isempty(x), grid_cell_contexts(index, :));
        result(index, 1:sum(cell_selector)) = grid_cell_contexts(index, cell_selector);
    end

    empty_cell_selector = cellfun(@(x) isempty(x), result);
    
    available_columns = ~all(empty_cell_selector, 1);
    available_rows = ~all(empty_cell_selector, 2);

    result = result(available_rows, available_columns);
    
    %{
    column_values = column_values(available_columns);
    row_values = row_values(available_rows);
    %}
end

function url = get_url_for_volume_layer(layer, context, use_scalar)

    url = '';

    if isfield(context, 'host_name')
        url = context.host_name;
    end
    
    if use_scalar
        url = join({url, layer.scalars.source_ref, layer.scalars.path}, '/');
    else
        url = join({url, layer.image.source_ref, layer.image.path}, '/');
    end

    url = url{1};
    url = replace(url, '//', '/');
end

function volume_set = create_volume_set_from_volume_layers(grid_cell_contexts, render_options)

    volume_set = geospm.volumes.VolumeSet();
    volume_set.file_paths = {};

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
            
            url = get_url_for_volume_layer(layer, render_options, true);
            url = regexprep(url, '^file:', '');
            volume_set.file_paths{end + 1} = url;
        end
    end
end

function define_unique_output_names_for_volume_set(volume_set)
    
    N = numel(volume_set.file_paths);
    unique_names = cell(N, 1);

    prefixes = cell(N, 1);
    names = cell(N, 1);

    for index=1:N
        [path, name, ~] = fileparts(volume_set.file_paths{index});
        path = regexprep(path, sprintf('%s%s+', filesep, filesep), filesep);
        parts = split(path, filesep);
        prefixes{index} = [parts; {''}];
        names{index} = name;
    end

    do_loop = true;
    found_unique_names = false;
    
    while do_loop
        
        current_set = containers.Map('KeyType', 'char', 'ValueType', 'logical');
        
        for index=1:N

            parts = prefixes{index};
            prefixes{index} = parts(1:end - 1);
            
            prefix = '';

            if ~isempty(parts)
                prefix = regexprep(lower(parts{end}), '\s+', '_');
            else
                do_loop = false;
            end

            if ~isempty(prefix)
                prefix = [prefix '_']; %#ok<AGROW>
            end
            
            key = [prefix names{index}];

            unique_names{index} = '';

            if ~isKey(current_set, key)
                current_set(key) = true;
                unique_names{index} = key;
            end
        end

        if length(current_set) == N
            found_unique_names = true;
            do_loop = false;
        end
    end

    if ~found_unique_names
        error('Couldn''t determine unique names.');
    end
    
    volume_set.optional_output_names = unique_names;
end

function assign_volume_layer_image_paths(grid_cell_contexts, image_paths, resources, context)

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
            
            identifier = regexprep(layer.image.path, '^\/|\/$', '');
            resource = resources(identifier);
            resources.remove(identifier);


            layer.image.path = image_paths{path_index};
            layer.image.source_ref = '';
            
            identifier = regexprep(layer.image.path, '^\/|\/$', '');
            resource.identifier = identifier;
            resource.url = get_url_for_volume_layer(layer, context, false);

            resources(identifier) = resource;

            path_index = path_index + 1;
        end
    end
end


function rerender_colour_maps(grid_cell_contexts, tmp_dir, render_options)
    
    renderer = geospm.volumes.ColourMapping();

    settings = geospm.volumes.RenderSettings();
    
    settings.formats = {'tif'};
    %settings.grid = grid;
    %settings.crs = hdng.SpatialCRS.empty;
    settings.centre_pixels = true;
    

    col_dir = fullfile(tmp_dir, sprintf('rerendered_images'));
    [status,msg] = mkdir(col_dir);

    if ~status
        error(msg);
    end

    volume_set = create_volume_set_from_volume_layers(grid_cell_contexts, render_options);
    
    context = geospm.volumes.RenderContext();
    context.render_settings = settings;

    context.image_volumes = volume_set;
    context.alpha_volumes = [];
    context.output_directory = col_dir;

    image_paths = renderer.render(context);
    image_paths = cellfun(@(x) x{1}, image_paths, 'UniformOutput', false);

    assign_volume_layer_image_paths(col_contexts, image_paths);

end

function apply_column_wise_colour_maps(grid_cell_contexts, tmp_dir, host_name, resources, render_options)
    
    render_options.host_name = host_name;

    if startsWith(host_name, 'file:')
        host_name = host_name(numel('file:') + 1:end);
    end

    renderer = geospm.volumes.ColourMapping();

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
        volume_set = create_volume_set_from_volume_layers(col_contexts, render_options);
        define_unique_output_names_for_volume_set(volume_set);

        context = geospm.volumes.RenderContext();
        context.render_settings = settings;

        context.image_volumes = volume_set;
        context.alpha_volumes = [];
        context.output_directory = col_dir;

        image_paths = renderer.render(context);
        image_paths = cellfun(@(x) x{1}, image_paths, 'UniformOutput', false);
        
        for index=1:numel(image_paths)
            path = image_paths{index};

            if startsWith(path, host_name)
                path = path(numel(host_name) + 1:end);
            end

            image_paths{index} = path;
        end


        assign_volume_layer_image_paths(col_contexts, image_paths, resources, render_options);
    end
end
