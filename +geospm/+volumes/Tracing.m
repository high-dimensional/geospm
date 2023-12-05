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

classdef Tracing < geospm.volumes.Renderer
    
    %Tracing 
    %
    
    properties (GetAccess=public, SetAccess=private)
    end
    
    properties (GetAccess=public, SetAccess=public)
        cell_sample_counts
        cell_labels
        cell_label_list
        summaries
    end
    
    properties (Dependent, Transient)
    end
    
    
    properties (GetAccess=private, SetAccess=private)
        
    end
    
    methods
        
        function obj = Tracing()
            obj = obj@geospm.volumes.Renderer();

            obj.cell_sample_counts = [];

            obj.cell_labels = [];
            obj.cell_label_list = {};
            obj.summaries = {};
        end
        
        function files = render(obj, context)
            
            image_volumes = context.load_image_volumes();

            if isprop(context.image_volumes, 'contrasts') && isprop(context.image_volumes, 'contrast_descriptions')
                contrast_volumes = context.load_volumes(context.image_volumes.contrasts);
                contrast_descriptions = context.image_volumes.contrast_descriptions;
            else
                contrast_volumes = {};
                contrast_descriptions = {};
            end

            [dirstatus, dirmsg] = mkdir(context.output_directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            render_settings = context.render_settings;
            pixel_offset = render_settings.grid.cell_size .* (0.5 * render_settings.centre_pixels);
            
            files = cell(numel(image_volumes), 1);
            
            obj.summaries = cell(1 + numel(image_volumes), 1);
            obj.summaries{1, 1} = 'Contrast';

            for i=1:numel(image_volumes)
                
                image_volume = image_volumes{i};

                if image_volume.c ~= 1
                    warning('geospm.volumes.Tracing.render(): Image volume is expected to contain only 1 channel.');
                    continue;
                end

                if ~isempty(contrast_volumes)
                    contrast_volume = contrast_volumes{i};
                    contrast_description = contrast_descriptions{i};
                else
                    contrast_volume = [];
                    contrast_description = '';
                end
                
                if ~isempty(contrast_description)
                    image_label = [contrast_description newline];
                elseif ~isempty(context.image_volumes.descriptions) && ~isempty(context.image_volumes.descriptions{i})
                    image_label = [context.image_volumes.descriptions{i} newline];
                else
                    [~, file_name, file_ext] = fileparts(context.image_volumes.file_paths{i});
                    image_label = [file_name file_ext newline];
                end
                
                slices = geospm.volumes.trace_slices(image_volume.data);
                
                N_slices = size(slices, 1);
                
                paths = cell(1, N_slices);
                
                for j=1:N_slices
                    
                    [directory, basename, ~] = fileparts(image_volume.path);
                    
                    file_path = fullfile(directory, [basename '_' num2str(j, '%04d') '.shp']);
                    paths{j} = file_path;
                    
                    polygons = slices{j, 1};
                    geo_polygons = polygons;
                    
                    if ~isempty(render_settings.grid) && polygons.N_elements ~= 0
                        
                        coords = polygons.vertices.coordinates;
                        
                        [coords(:, 1), coords(:, 2), ~] = render_settings.grid.grid_to_space(coords(:, 1), coords(:, 2), ones(polygons.vertices.N_vertices, 1) * j);
                        coords(:, 1:2) = cast(coords(:, 1:2), 'double') - pixel_offset(1:2);
                        
                        vertices = hdng.geometry.Vertices.define(coords(:, 1:2));
                        geo_polygons = polygons.substitute_vertices(vertices);
                    end

                    geometry = hdng.geometry.FeatureGeometry.define(geo_polygons, render_settings.crs);
                    geometry.save(file_path);

                    if ~isempty(obj.cell_sample_counts)
                        %file_path = fullfile(directory, [basename '_' num2str(j, '%04d') '_summary.txt']);
                        
                        if ~isempty(contrast_volume)
                            contrast_slice = contrast_volume.data(:, :, j);
                        else
                            contrast_slice = [];
                        end
                        
                        [~, summary] = geospm.volumes.summarise_polygons(...
                            obj.cell_sample_counts, ...
                            obj.cell_labels, ...
                            obj.cell_label_list, ...
                            contrast_slice, ...
                            [image_volume.x, image_volume.y], ...
                            polygons);
                        
                        obj.summaries{1 + i, 1} = image_label;
                        obj.summaries{1 + i, 1 + j} = summary;
                    end
                end
                
                files{i} = paths;
            end

            %{
            for i=2:size(summaries, 2)
                
                summaries{1, i} = sprintf('Slice %d', i - 1);

                summary = join(summaries(2:end, [1, i]), newline, 2);
                summary = join(summary, newline);
                summary = summary{1};
                
                file_path = fullfile(context.output_directory, ['summary_z' num2str(i - 1, '%04d') '.txt']);
                hdng.utilities.save_text(summary, file_path);
            end
            %}

            file_path = fullfile(context.output_directory, 'summary.csv');
            writecell(obj.summaries, file_path);
        end
    end
end
