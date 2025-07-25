% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2020,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef ReportContext < handle
    
    %ReportContext
    %

    properties (GetAccess=public, SetAccess=public)
        
        base_directory      % the base directory

        shared_variables    % shared variables

        render_layer_categories
    end
    
    methods
        
        function obj = ReportContext(base_directory, shared_variables)
            

            if ~exist('shared_variables', 'var')
                shared_variables = geospm.reports.SharedVariables();
            end

            
            obj.base_directory = base_directory;
            obj.shared_variables = shared_variables;
            obj.render_layer_categories = {};
        end
        
        function [spm_input_path, spm_output_path] = spm_paths_from_record(obj, record)
            spm_output_path = record('result.spm_output_directory').content.path;
            [session_directory, ~, ~] = fileparts(spm_output_path);
            spm_input_path = fullfile(obj.base_directory, session_directory, 'spm_input');
            spm_output_path = fullfile(obj.base_directory, spm_output_path);
        end
        
        function mask_volume = render_mask_volume(obj, mask)
            %render_mask_volume
            %
            % mask – VolumeReference of mask to be rendered

            context = geospm.volumes.RenderContext();
        
            mask_volume_set = geospm.volumes.VolumeSet();
            mask_volume_set.file_paths = {fullfile(obj.base_directory, mask.scalars.path)};
        
            context.image_volumes = mask_volume_set;
        
            mask_volume = context.load_image_volumes();
            mask_volume = mask_volume{1};
        end
        
        function [polygons, slice_index] = load_polygons_for_slice_name(obj, mask_traces, slice_name)
            %load_polygons_for_slice_name
            % mask_traces – SliceShapes

            slice_map = hdng.experiments.SliceMap(mask_traces.slice_names);
            slice_index = slice_map.index_for_name(slice_name, 0);
            
            if slice_index == 0
                slice_index = numel(mask_traces.shape_paths);
            end
            
            slice_path = fullfile(obj.base_directory, mask_traces.shape_paths{slice_index});
            
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
        
        function results = create_cell_render_contexts(obj, ...
                group, cell_attachment, cell_layer_fn, layer_paths, ...
                renderer, clear_source_refs, path_prefix, ...
                render_options)

            results = cell(size(group.cells));
            cell_layers = cell(size(group.cells));

            cell_values = group.cell_attachments.(cell_attachment);
        
            % Unpack all layers from their cell values
            
            for row_index=1:group.N_rows
                
                for col_index=1:group.N_columns

                    records = group.cells{row_index, col_index};
                    
                    if isempty(records)
                        continue;
                    end
                    
                    selected_layers = cell_values{row_index, col_index};

                    cell_layers{row_index, col_index} = ...
                        geospm.reports.ReportContext.unpack_layers(selected_layers, layer_paths, clear_source_refs, path_prefix);
                    

                end
            end

            % Select layers for each cell

            fn_state = [];
            
            for row_index=1:group.N_rows
                
                for col_index=1:group.N_columns

                    records = group.cells{row_index, col_index};
                    
                    if isempty(records)
                        continue;
                    end
                    
                    [selected_layers, fn_state] = cell_layer_fn(...
                        cell_layers, ...
                        row_index, col_index, group, fn_state);
        
                    if isempty(selected_layers)
                        continue;
                    end

                    % We are selecting the first available record,
                    % because we assume all records in a cell hail from
                    % the same dataset.

                    record = records.unsorted_records{1};
                    
                    [spm_input_path, ~] = obj.spm_paths_from_record(record);
                    obj.shared_variables.update_volume_generators(spm_input_path, record);
                    
                    stack = geospm.validation.PresentationStack(selected_layers, ...
                        obj.render_layer_categories, render_options.magnification);
                    
                    context = renderer.create_context_for(stack, [], render_options);
                    context.resources = obj.shared_variables.resources;
            
                    renderer.gather_all_layer_resources(stack.selected_layers, context, obj.shared_variables.resources);
            
                    results{row_index, col_index} = context;
                end
            end
        end


        function results = create_cell_datasets(obj, ...
                group, cell_attachment, ...
                cell_mask_volume_fn, slice_name, easting, northing)

            % Extract subsets of the data for each cell in the group,
            % using all the polygons derived from a slice of 
            % the cell mask volume and the given coordinate data columns.
        
            results = cell(size(group.cells));
            
            cell_values = group.cell_attachments.(cell_attachment);

            fn_state = [];
        
            % Step through each grid cell
            
            for row_index=1:group.N_rows
                
                for col_index=1:group.N_columns
                    
                    records = group.cells{row_index, col_index};
                    
                    if isempty(records)
                        continue;
                    end
                    
                    [values, fn_state] = cell_mask_volume_fn(...
                        cell_values, ...
                        row_index, col_index, group, fn_state);
        
                    if isempty(values)
                        continue;
                    end
                    
                    %mask = values{1}.content;
                    %mask_traces = values{2}.content;

                    [polygons, slice_index] = obj.load_polygons_for_slice_name(...
                        values.result.terms.mask_traces.content, slice_name);
                    
                    % We need the mask to derive the size of the grid cells in 
                    % geographic coordinates.
                
                    mask_volume = obj.render_mask_volume(values.result.terms.mask.content);
                    mask_slice = mask_volume.data(:, :, slice_index);
                    
                    raster_size = size(mask_slice);
                    
                    % We are selecting the first available record,
                    % because we assume all records in a cell hail from
                    % the same dataset.

                    record = records.unsorted_records{1};
                    
                    [spm_input_path, ~] = obj.spm_paths_from_record(record);
                    obj.shared_variables.update_volume_generators(spm_input_path, record);
                    
                    data_specifier = record('configuration.spatial_data_specifier').unpack();
                    
                    min_location = cell2mat(data_specifier.min_location);
                    max_location = cell2mat(data_specifier.max_location);
                
                    cell_size = (max_location(1:2) - min_location(1:2)) ./ size(mask_slice)';
                
                    dataset_path = data_specifier.file_path;

                    dataset = geospm.reports.ReportDataset.load(dataset_path, ...
                        obj.shared_variables.dataset_cache, ...
                        obj.shared_variables.dataset_aliases);
                    
                    polygon_datasets = dataset.select_polygons(polygons, ...
                        slice_index, record, raster_size, cell_size, ...
                        min_location, max_location, easting, northing);
                    
                    results{row_index, col_index} = polygon_datasets;
                end
            end
        end
        
    end

    methods (Static)

        function layers = unpack_layers(values, layer_paths, clear_source_refs, path_prefix)
            values = geospm.reports.ReportContext.unpack_layer_values(values, layer_paths);
            layers = geospm.reports.ReportContext.convert_values_to_layers(values, clear_source_refs, path_prefix);
        end

        function result = unpack_layer_values(values, layer_paths)
            
            result = {};
        
            for index=1:numel(layer_paths)
                layer_value_path = layer_paths{index};
        
                value = hdng.utilities.struct_get_value_at_path(values, layer_value_path, []);
        
                if iscell(value.content)
                    result = [result; value.content(:)]; %#ok<AGROW>
                else
                    result{end + 1} = value.content; %#ok<AGROW>
                end
            end
        
        end
        
        function layers = convert_values_to_layers(values, clear_source_refs, path_prefix)
            
            layers = cell(size(values));
        
            for index=1:numel(values)
                value = values{index};
                
                if isa(value, 'hdng.experiments.VolumeReference')
                    layer = geospm.validation.VolumeLayer();
                    layer.image = value.image;
                    layer.scalars = value.scalars;
                    layer.slice_names = value.slice_names;
                    layer.category = 'content';
                    layer.blend_mode = 'multiply';
        
                    if clear_source_refs
                        layer.image.source_ref = '';
                        layer.scalars.source_ref = '';
                    end
        
                    layer.image.path = fullfile(path_prefix, layer.image.path);
                    layer.scalars.path = fullfile(path_prefix, layer.scalars.path);
        
                elseif isa(value, 'hdng.experiments.SliceShapes')
                    layer = geospm.validation.SliceShapesLayer();
                    layer.origin = value.origin;
                    layer.span = value.span;
                    layer.resolution = value.resolution;
                    layer.shape_paths = value.shape_paths;
                    layer.slice_names = value.slice_names;
                    layer.source_ref = value.source_ref;
                    layer.category = 'content';
                    layer.blend_mode = 'normal';
        
                    if clear_source_refs
                        layer.source_ref = '';
                    end
        
                    for p=1:numel(layer.shape_paths)
                        layer.shape_paths{p} = fullfile(path_prefix, layer.shape_paths{p});
                    end
        
                elseif isa(value, 'geospm.validation.ImageLayer')
                    layer = copy(value);
                    layer.image = copy(layer.image);
                    
                    if clear_source_refs
                        layer.image.source_ref = '';
                    end
                    
                    layer.image.path = fullfile(path_prefix, layer.image.path);
        
                elseif isa(value, 'geospm.validation.PresentationLayer')
                    layer = copy(value);
                else
                    layer = [];
                end
        
                layers{index} = layer;
            end
        end

        function result = create_volume_generator(...
                volume_directory, ...
                resolution, ...
                precision, ...
                smoothing_scale, ...
                smoothing_method, ...
                smoothing_levels, ...
                smoothing_levels_p_value)
            
            [dirstatus, dirmsg] = mkdir(volume_directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            %We need to make sure the SyntheticVolumeGenerator base class 
            %is on the Matlab path, so an SPM interface instance needs 
            %to exist:
            
            geospm.spm.SPMJobList.access_spm_interface();
            
            %smoothing_levels are specified in data units
            %smoothing_scale = grid_data.grid.cell_size(1:2);
            
            if smoothing_scale(1) ~= smoothing_scale(2)
                warning('Grid axes are scaled differently: Taking the maximim value as smoothing scale.');
            end
            
            smoothing_levels = smoothing_levels ./ max(smoothing_scale);
            
            result = geospm.spm.SpatialIndexRenderer( ...
                    volume_directory, ...
                    'window_resolution', resolution, ...
                    'precision', precision, ...
                    'smoothing_method', smoothing_method, ...
                    'smoothing_levels', smoothing_levels, ...
                    'smoothing_levels_p_value', smoothing_levels_p_value, ...
                    'smoothing_levels_as_z_dimension', true, ...
                    'write_volumes', false, ...
                    'overwrite_existing_volumes', false ...
                    );
        end

        
    end
end
