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
    end
    
    properties (Dependent, Transient)
    end
    
    
    properties (GetAccess=private, SetAccess=private)
        
    end
    
    methods
        
        function obj = Tracing()
            obj = obj@geospm.volumes.Renderer();
        end
        
        function files = render(obj, context) %#ok<INUSL>
            
            image_volumes = context.load_image_volumes();
            
            [dirstatus, dirmsg] = mkdir(context.output_directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            render_settings = context.render_settings;
            pixel_offset = render_settings.grid.cell_size .* (0.5 * render_settings.centre_pixels);
            
            files = cell(numel(image_volumes), 1);
            
            for i=1:numel(image_volumes)

                image_volume = image_volumes{i};

                if image_volume.c ~= 1
                    warning('geospm.volumes.Tracing.render(): Image volume is expected to contain only 1 channel.');
                    continue;
                end
                
                slices = geospm.volumes.trace_slices(image_volume.data);
                
                N_slices = size(slices, 1);
                
                paths = cell(1, N_slices);
                
                for j=1:N_slices
                    
                    [directory, basename, ~] = fileparts(image_volume.path);
                    
                    file_path = fullfile(directory, [basename '_' num2str(j, '%04d') '.shp']);
                    paths{j} = file_path;
                    
                    polygons = slices{j, 1};
                    
                    if ~isempty(render_settings.grid) && polygons.N_elements ~= 0
                        
                        coords = polygons.vertices.coordinates;
                        
                        [coords(:, 1), coords(:, 2), ~] = render_settings.grid.grid_to_space(coords(:, 1), coords(:, 2), ones(polygons.vertices.N_vertices, 1) * j);
                        coords(:, 1:2) = cast(coords(:, 1:2), 'double') - pixel_offset(1:2);
                        
                        vertices = hdng.geometry.Vertices.define(coords(:, 1:2));
                        polygons = polygons.substitute_vertices(vertices);
                    end

                    geometry = hdng.geometry.FeatureGeometry.define(polygons, render_settings.crs);
                    geometry.save(file_path);
                end
                
                files{i} = paths;
            end
        end
        
    end
end
