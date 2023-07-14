% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2019,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef PrerenderedMap < hdng.maps.MappingService
    %MAPPINGSERVICE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        crs
        cache_path
        cache_name_format
        cache_min_location
        cache_max_location
        cache_n_tiles
        tile_size
        image_format
    end
    
    methods
        
        function obj = PrerenderedMap()

            obj = obj@hdng.maps.MappingService();
            obj.crs = hdng.SpatialCRS.from_identifier('epsg:27700');
            obj.cache_path = fullfile('mapping_services', 'pre-rendered', 'epsg_27700');
            
            obj.cache_name_format = hdng.one_struct(...
                'format', {'%northing', '%easting'}, ...
                'parts', ...
                hdng.one_struct('easting', '%02d', 'northing', '%02d'));

            obj.cache_min_location = [0, 0];
            obj.cache_max_location = [700000, 1300000];
            obj.cache_n_tiles = [7, 13];
            obj.tile_size = [4000, 4000];
            obj.image_format = 'png';
        end
        
        function layer_images = generate(obj, crs, min_location, max_location, ...
                                  spatial_resolution, layers)
            
            layer_images = {};

            if ~strcmp(crs.identifier, obj.crs.identifier)
                return
            end

            if ~exist('layers', 'var')
                layers = obj.layers(1);
            end
            
            for i=1:numel(layers)
                image = obj.extract_image(min_location, max_location, ...
                    spatial_resolution, layers{i});
                
                layer_images{i} = image; %#ok<AGROW> 
            end
        end        
    end

    methods (Access=protected)

        function result = access_layers(~)
            result = {'combined', 'foreground', 'background'};
        end

        
        function image = extract_image(obj, min_location, max_location, spatial_resolution, layer)
            
            [tile_images, tiles_span, offset, span] = obj.load_tile_images(min_location, max_location, layer);
            
            combined_image = [];

            for i=1:size(tile_images, 1)
                strip = tile_images{i, 1};

                for j=2:size(tile_images, 2)
                    strip = [strip, tile_images{i, j}]; %#ok<AGROW> 
                end

                combined_image = [combined_image; strip]; %#ok<AGROW> 
            end
            
            combined_image_size = size(combined_image, 2, 1);

            tile_resolution = combined_image_size ./ tiles_span;

            image_offset = [offset(1), tiles_span(2) - offset(2) - span(2)] .* tile_resolution;
            image_span = span .* tile_resolution;
            
            aligned_image_offset = floor(image_offset) + 1;
            aligned_image_limit = ceil(image_offset + image_span);
            
            image = combined_image(aligned_image_offset(2):aligned_image_limit(2), ...
                                   aligned_image_offset(1):aligned_image_limit(1));

            image = imresize(image, spatial_resolution, 'bilinear');
        end

        function [tile_images, tiles_span, offset, span] = load_tile_images(obj, min_location, max_location, layer)

            %[in_cache, cache_min, cache_max] = obj.clip_location_span_to_cache(min_location, max_location);
            
            %if ~in_cache
            %    return
            %end

            [tile_min, tile_max, tiles_span, offset, span] = obj.tile_span_from_location_span(min_location, max_location);

            tile_names = obj.tile_names_from_tile_span(tile_min, tile_max);
            tile_names = flip(tile_names);
            tile_images = cell(size(tile_names));

            for i=1:numel(tile_names)
                tile_name = tile_names{i};

                if isempty(tile_name)
                    tile_images{i} = cast(ones(obj.tile_size) * 255, 'uint8');
                    continue;
                end

                tile_path = fullfile(obj.cache_path, lower(layer), [tile_name '.' obj.image_format]);
                tile_images{i} = imread(tile_path);
            end
        end

        function [in_cache, clipped_min, clipped_max] = clip_location_span_to_cache(obj, min_location, max_location)

            clipped_min = max(obj.cache_min_location, min_location);
            clipped_max = min(obj.cache_max_location, max_location);
            
            in_cache = all(clipped_min <= clipped_max);
        end

        function [tile_min, tile_max, tiles_span, offset, span] = tile_span_from_location_span(obj, location_min, location_max)
            
            tile_span = (obj.cache_max_location - obj.cache_min_location) ./ obj.cache_n_tiles;

            relative_cache_min = location_min - obj.cache_min_location;
            relative_cache_max = location_max - obj.cache_min_location;

            tile_min = floor(relative_cache_min ./ tile_span);
            tile_max = floor(relative_cache_max ./ tile_span);

            tile_min_location = tile_min .* tile_span;
            tile_max_location = (tile_max + 1) .* tile_span;
            
            tiles_span = tile_max_location - tile_min_location;
            offset = relative_cache_min - tile_min_location;
            span = relative_cache_max - relative_cache_min;
        end
        
        function tile_names = tile_names_from_tile_span(obj, tile_min, tile_max)

            tile_names = cell(flip(tile_max - tile_min + 1));
            
            range = tile_max - tile_min + 1;

            for i=1:range(1)
                h = tile_min(1) + i - 1;

                for j=1:range(2)
                    v = tile_min(2) + j - 1;

                    if h < 0 || v < 0 || h >= obj.cache_n_tiles(1) || v >= obj.cache_n_tiles(2)
                        tile_names{j, i} = '';
                        continue;
                    end

                    values = hdng.one_struct('easting', h, 'northing', v);
                    filename = obj.format_tile_name(values);
                    tile_names{j, i} = filename;
                end
            end
        end

        function result = format_tile_name(obj, values)
            value_names = fieldnames(values);

            for i=1:numel(value_names)
                value_name = value_names{i};
                value_format = obj.cache_name_format.parts.(value_name);
                values.(value_name) = sprintf(value_format, values.(value_name));
            end

            result = '';

            for i=1:numel(obj.cache_name_format.format)
                part = obj.cache_name_format.format{i};

                if ischar(part) && ~isempty(part) && part(1) == '%'
                    result = [result values.(part(2:end))]; %#ok<AGROW> 
                else
                    result = [result, part]; %#ok<AGROW> 
                end
            end
        end
    end
    
end
