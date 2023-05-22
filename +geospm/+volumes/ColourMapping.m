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

classdef ColourMapping < geospm.volumes.Renderer
    
    %ColourMapping 
    %
    
    properties (GetAccess=public, SetAccess=private)
    end
    
    properties (GetAccess=public, SetAccess=public)
        colour_map
        colour_map_mode
    end
    
    properties (Dependent, Transient)
    end
    
    
    properties (GetAccess=private, SetAccess=private)
        
    end
    
    methods
        
        function obj = ColourMapping()
            obj = obj@geospm.volumes.Renderer();
            
            obj.colour_map = hdng.colour_mapping.GenericColourMap.twilight_27();
            obj.colour_map_mode = hdng.colour_mapping.ColourMap.LAYER_MODE;
            %obj.colour_map_mode = hdng.colour_mapping.ColourMap.BATCH_MODE;
        end
        
        function [files, metadata_per_file] = render(obj, context)
            
            image_volumes = context.load_image_volumes();
            alpha_volumes = context.load_alpha_volumes();
            
            no_alpha = isempty(alpha_volumes);
            
            if numel(alpha_volumes) == 1
                tmp = cell(numel(image_volumes), 1);
                tmp(:) = alpha_volumes(1);
                alpha_volumes = tmp;
            elseif ~no_alpha && numel(alpha_volumes) ~= numel(image_volumes)
                error('Number of alpha volume paths must be 0, 1, or match the number of image volumes.');
            end
            
            [dirstatus, dirmsg] = mkdir(context.output_directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            render_settings = context.render_settings;
            
            if ~no_alpha
                
                for i=1:numel(image_volumes)
                    
                    image_volume = image_volumes{i};
                    alpha_volume = alpha_volumes{i};
                    
                    % image_channels = image_volume.c;
                    
                    if image_volume.c ~= 1 && image_volume.c ~= 3
                        warning('geospm.volumes.ColourMapping.render(): Image volume is expected to contain 1 or 3 channels.');
                        continue;
                    end
                    
                    if alpha_volume.c ~= 1
                        warning('geospm.volumes.ColourMapping.render(): Alpha volume is expected to contain 1 channel.');
                        continue;
                    end
                    
                    image_volume.data = cat(4, image_volume.data, alpha_volume.data);
                    image_volume.alpha_channel_index = image_volume.c;
                end
            end
            
            if isempty(render_settings.crs)
                
                results = hdng.images.ImageVolume.batch_render_as_vpng( ...
                    image_volumes, 8, ...
                    obj.colour_map, obj.colour_map_mode);
                
                files = results(:, 4);
                metadata_per_file = cell(size(files, 1), 1);
                
                for index=1:size(files, 1)
                    image_volume = image_volumes{index};
                    metadata_per_file{index} = {struct('slices', image_volume.z)};
                end
            else
                files = hdng.images.ImageVolume.batch_render_with_georeference( ...
                    render_settings.formats, image_volumes, 8, ...
                    obj.colour_map, obj.colour_map_mode, ...
                    render_settings.grid, render_settings.crs, ...
                    render_settings.centre_pixels);
                
                metadata_per_file = cell(size(files, 1), numel(render_settings.formats));
                
                for index=1:size(files, 1)
                    metadata_per_file{index} = cell(1, numel(render_settings.formats));
                end
            end
        end
    end
end
