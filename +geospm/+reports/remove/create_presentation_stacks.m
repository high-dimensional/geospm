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

function grid_cell_values = create_presentation_stacks(grid_cell_values, ...
    renderer, selected_layer_categories, resources, clear_source_refs, ...
    path_prefix, render_options)
    

    for index=1:numel(grid_cell_values)
        values = grid_cell_values{index};

        if isempty(values)
            continue;
        end
        
        layers = unpack_values(values);

        layers = convert_values_to_layers(layers, clear_source_refs, path_prefix);
        
        stack = geospm.validation.PresentationStack(layers, selected_layer_categories, render_options.magnification);
        
        context = renderer.create_context_for(stack, [], render_options);
        context.resources = resources;

        renderer.gather_layer_resources(stack.selected_layers, context, resources);

        grid_cell_values{index} = context;
    end
end

function result = unpack_values(values)
    
    result = {};

    for index=1:numel(values)
        
        value = values{index};

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
