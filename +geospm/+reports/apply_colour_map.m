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

function legends = apply_colour_map(colour_map, batches, shared_variables)
    
    legends = cell(numel(batches), 1);
    host_name = shared_variables.host_name;
    resources = shared_variables.resources;
    resource_manager = shared_variables.resource_manager;

    if startsWith(host_name, 'file:')
        host_name = host_name(numel('file:') + 1:end);
    end
    
    renderer = geospm.volumes.ColourMapping();
    renderer.colour_map = colour_map;
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
        legends{batch_index} = slice_legends;
        
        for index=1:numel(slice_legends)
            legend = slice_legends{index};
            %legend.render_and_save_as(300, fullfile(volume_set.output_directory, sprintf('legend_z%04d.png', index)), 'Effects');
            legend_file_name = fullfile(volume_set.output_directory, sprintf('legend_z%04d.svg', index));
            legend_svg = legend.as_svg(300, 20);
            hdng.utilities.save_text(legend_svg, legend_file_name);
        end
        
        update_resource_paths(volume_set.cell_contexts, image_paths, resources, resource_manager, shared_variables.host_name);
    end
end



function update_resource_paths(grid_cell_contexts, image_paths, resources, resource_manager, url_prefix)

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
            
            [~, identifier] = resource_manager.build_resource_url_and_identifier(url_prefix, layer.image.source_ref, layer.image.path); 
            
            %identifier = image_identifiers{path_index};
            resource = resources(identifier);
            
            if isa(resource, 'hdng.utilities.DictionaryError')
                error('Implementation error: Incorrect resource identifier');
            end
            
            resources.remove(identifier);

            layer.image.path = image_paths{path_index};
            layer.image.source_ref = '';
            
            [url, identifier] = resource_manager.build_resource_url_and_identifier(url_prefix, layer.image.source_ref, layer.image.path); 
            
            resource.identifier = identifier;
            resource.url = url;

            resources(resource.identifier) = resource;

            path_index = path_index + 1;
        end
    end
end
