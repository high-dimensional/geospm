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

function polygon_datasets = extract_polygon_datasets(values, grid_cell, grid_env)

    slice_name = grid_env.slice_name;
    base_directory = grid_env.base_directory;
    dataset_cache = grid_env.dataset_cache;
    dataset_aliases = grid_env.dataset_aliases;
    volume_generators = grid_env.volume_generators;
    
    % This is hard-coded for now!
    mask = values{1}.content;
    mask_traces = values{2}.content;
    
    mask_volume = render_mask_volume(mask, base_directory);
    
    [polygons, slice_index] = load_polygons_for_slice_name(mask_traces, slice_name, base_directory);

    mask_slice = mask_volume.data(:, :, slice_index);
    
    record = grid_cell.unsorted_records{1};
    
    [spm_input_path, ~] = spm_paths_from_record(record, base_directory);
    
    update_volume_generators(volume_generators, spm_input_path, record);

    spatial_data_specifier = record('configuration.spatial_data_specifier').unpack();

    min_location = cell2mat(spatial_data_specifier.min_location);
    max_location = cell2mat(spatial_data_specifier.max_location);
    cell_size = (max_location(1:2) - min_location(1:2)) ./ size(mask_slice)';

    dataset_path = spatial_data_specifier.file_path;
    dataset = load_dataset(dataset_path, dataset_cache, dataset_aliases);
    
    polygon_datasets = generate_polygon_datasets(polygons, dataset, min_location, max_location, cell_size, size(mask_slice), slice_index, record);
end


function update_volume_generators(volume_generators, key, record)

    if ~volume_generators.holds_key(key)
        
        specifier = struct();
        
        specifier.smoothing_levels = record('configuration.smoothing_levels').unpack();
        specifier.smoothing_levels = cell2mat(specifier.smoothing_levels);
        specifier.smoothing_levels_p_value = record('configuration.smoothing_levels_p_value').unpack();
        specifier.smoothing_method = record('configuration.smoothing_method').unpack();
        
        volume_generators(key) = specifier;
    end
end

function [spm_input_path, spm_output_path] = spm_paths_from_record(record, base_directory)
    spm_output_path = record('result.spm_output_directory').content.path;
    [session_directory, ~, ~] = fileparts(spm_output_path);
    spm_input_path = fullfile(base_directory, session_directory, 'spm_input');
end

function [polygons, slice_index] = load_polygons_for_slice_name(mask_traces, slice_name, base_directory)
    
    slice_map = hdng.experiments.SliceMap(mask_traces.slice_names);
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

    polygons = slice_geometry.collection;
end


function mask_volume = render_mask_volume(mask, base_directory)

    context = geospm.volumes.RenderContext();

    mask_volume_set = geospm.volumes.VolumeSet();
    mask_volume_set.file_paths = {fullfile(base_directory, mask.scalars.path)};

    context.image_volumes = mask_volume_set;

    mask_volume = context.load_image_volumes();
    mask_volume = mask_volume{1};
end

function polygon_datasets = generate_polygon_datasets(polygons, dataset, min_location, max_location, cell_size, render_size, slice_index, record)

    polygon_datasets = [];

    if ~isempty(polygons)
        
        ctx = hdng.rasters.RasterContext([render_size 1]);
                
        x = dataset.data(:, dataset.identifiers.easting);
        y = dataset.data(:, dataset.identifiers.northing);

        for p=1:polygons.N_elements
            
            polygon_dataset = dataset;

            polygon = polygons.nth_element(p);
            polygon_vertices = polygon.collect_nan_delimited_ring_vertices();
    
            selection = inpolygon(x, y, polygon_vertices(:, 1), polygon_vertices(:, 2))';

            polygon_dataset.data = polygon_dataset.data(selection, :); %selection(p, :), :);
            polygon_dataset.polygon = polygon;
            polygon_dataset.min_location = min_location(1:2);
            polygon_dataset.max_location = max_location(1:2);
            polygon_dataset.cell_size = cell_size;
            polygon_dataset.slice_index = slice_index;
            polygon_dataset.record = record;

            coordinates = [polygon_dataset.polygon.vertices.x';
                           polygon_dataset.polygon.vertices.y'];

            coordinates = (coordinates - min_location(1:2)) ./ cell_size + 1;
            
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
end


function result = load_dataset(file_path, cache, aliases)
    
    if ~cache.holds_key(file_path)
        
        [file_directory, file_name, file_ext] = fileparts(file_path);

        actual_file_path = file_path;

        if aliases.holds_key(file_path)
            actual_file_path = aliases(file_path);
        elseif aliases.holds_key(file_directory)
            actual_file_path = fullfile(aliases(file_directory), [file_name, file_ext]);
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
