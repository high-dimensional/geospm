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

        entity_path
        entity_cache
    end
    
    methods
        
        function obj = PrerenderedMap()

            obj = obj@hdng.maps.MappingService();
            obj.crs = hdng.SpatialCRS.from_identifier('epsg:27700');
            obj.cache_path = fullfile(mapping_services, 'epsg_27700', 'pre_rendered');
            obj.entity_path = fullfile(mapping_services, 'epsg_27700', 'entities');

            obj.entity_cache = struct();
            
            obj.cache_name_format = hdng.one_struct(...
                'format', {'%northing', '%easting'}, ...
                'parts', ...
                hdng.one_struct('easting', '%02d', 'northing', '%02d'));

            obj.cache_min_location = [0, 0];
            obj.cache_max_location = [700000, 1300000];
            %obj.cache_n_tiles = [7, 13];
            %obj.tile_size = [4000, 4000];
            obj.cache_n_tiles = [14, 26];
            obj.tile_size = [2500, 2500];
            obj.image_format = 'png';
        end
        
        function result = query(obj, crs, min_location, max_location, entity)
            
            result = struct.empty;

            if ~isfield(obj.entity_cache, entity)
    
                file_path = fullfile(obj.entity_path, [entity '.csv']);
    
                if ~exist(file_path, 'file')
                    return
                end
                
                sidecar_file_path = fullfile(obj.entity_path, [entity '.mat']);

                if ~exist(sidecar_file_path, 'file')
                    return
                end

                %import_opts = detectImportOptions(file_path, 'VariableNamingRule', 'preserve');
                %variable_names = import_opts.VariableNames';
                
                entity_struct = load(sidecar_file_path);
                entity_struct.data = struct();

                entity_cells = readcell(file_path);
    
                variable_names = entity_cells(1, :);
    
                for index=1:numel(variable_names)
                    name = variable_names{index};
                    
                    value = entity_cells{2, index};
                    
                    if isnumeric(value)
                        value = cell2mat(entity_cells(2:end, index));
                    else
                        value = entity_cells(2:end, index);
                    end
    
                    entity_struct.data.(name) = value;
                end
                
                obj.entity_cache.(entity) = entity_struct;
            else
                entity_struct = obj.entity_cache.(entity);
            end
            
            switch entity_struct.feature
                case 'points'
                    result = obj.query_points(crs, min_location, max_location, entity_struct);
                
                otherwise
                    error('PrerenderedMap.query(): Unknown entity ''%s''', entity_struct.handler);
            end
        end

        function [images, alphas] = generate(obj, crs, min_location, max_location, ...
                                  spatial_resolution, layers)
            
            images = {};
            alphas = {};

            if ~strcmp(crs.identifier, obj.crs.identifier)
                return
            end

            if ~exist('layers', 'var')
                layers = obj.layers(1);
            end
            
            for i=1:numel(layers)
                [image, alpha] = obj.extract_image(min_location, max_location, ...
                    spatial_resolution, layers{i});
                
                images{i} = image; %#ok<AGROW>
                alphas{i} = alpha; %#ok<AGROW>
            end
        end        
    end

    methods (Access=protected)

        function result = access_layers(~)
            result = {'combined', 'foreground', 'background'};
        end

        function result = query_points(obj, crs, min_location, max_location, entity_struct)
            
            result = struct.empty;
            
            if ~strcmp(crs.identifier, obj.crs.identifier)
                return
            end
            
            search_field = entity_struct.primary_search_field;
            search_dim = entity_struct.primary_search_dimension;

            [min_index, min_insert] = hdng.utilities.binary_search(entity_struct.data.(search_field), min_location(search_dim));
            min_index = min_index + min_insert;

            [max_index, max_insert] = hdng.utilities.binary_search(entity_struct.data.(search_field), max_location(search_dim));
            max_index = max_index + max_insert;
            
            if max_insert ~= 0
                max_index = max_index - 1;
            end
            
            data = entity_struct.data;
            fields = fieldnames(data);

            for index=1:numel(fields)
                field_name = fields{index};
                values = data.(field_name);
                data.(field_name) = values(min_index:max_index);
            end

            search_field = entity_struct.secondary_search_field;
            search_dim = entity_struct.secondary_search_dimension;
            
            selector = data.(search_field) >= min_location(search_dim) ...
                & data.(search_field) <= max_location(search_dim);
            
            for index=1:numel(fields)
                field_name = fields{index};
                values = data.(field_name);
                data.(field_name) = values(selector);
            end
            
            result = data;
        end

        function [image, alpha] = extract_image(obj, min_location, max_location, spatial_resolution, layer)
            
            [tile_images, tiles_span, offset, span, tile_alphas] = obj.load_tile_images(min_location, max_location, layer);
            
            combined_image = [];
            combined_alpha = [];

            for i=1:size(tile_images, 1)
                strip = tile_images{i, 1};
                alpha_strip = tile_alphas{i, 1};

                for j=2:size(tile_images, 2)
                    strip = [tile_images{i, j}; strip]; %#ok<AGROW> 
                    alpha_strip = [tile_alphas{i, j}; alpha_strip]; %#ok<AGROW> 
                end
                
                combined_image = [combined_image, strip]; %#ok<AGROW> 
                combined_alpha = [combined_alpha, alpha_strip]; %#ok<AGROW> 
            end
            
            combined_image_size = size(combined_image, 2, 1); % flip dimensions

            tile_resolution = combined_image_size ./ tiles_span;

            image_offset = [offset(1), tiles_span(2) - (offset(2) + span(2))] .* tile_resolution;
            image_span = span .* tile_resolution;
            
            aligned_image_offset = floor(image_offset) + 1;
            aligned_image_limit = ceil(image_offset + image_span);
            
            image = combined_image(aligned_image_offset(2):aligned_image_limit(2), ...
                                   aligned_image_offset(1):aligned_image_limit(1), ...
                                   :);

            image = imresize(image, [spatial_resolution(2), spatial_resolution(1)], 'bilinear');
            
            if ~isempty(combined_alpha)
                alpha = combined_alpha(aligned_image_offset(2):aligned_image_limit(2), ...
                                       aligned_image_offset(1):aligned_image_limit(1), ...
                                       :);

                alpha = imresize(alpha, [spatial_resolution(2), spatial_resolution(1)], 'bilinear');
            else
                alpha = [];
            end
        end

        function [tile_images, tiles_span, offset, span, tile_alphas] = load_tile_images(obj, min_location, max_location, layer)

            %[in_cache, cache_min, cache_max] = obj.clip_location_span_to_cache(min_location, max_location);
            
            %if ~in_cache
            %    return
            %end

            [tile_min, tile_max, tiles_span, offset, span] = obj.tile_span_from_location_span(min_location, max_location);

            tile_names = obj.tile_names_from_tile_span(tile_min, tile_max);
            tile_images = cell(size(tile_names));
            tile_alphas = cell(size(tile_names));

            for i=1:numel(tile_names)
                tile_name = tile_names{i};

                if isempty(tile_name)
                    tile_images{i} = cast(ones(obj.tile_size) * 255, 'uint8');
                    tile_alphas{i} = double.empty;
                    continue;
                end

                tile_path = fullfile(obj.cache_path, lower(layer), [tile_name '.' obj.image_format]);
                [tile_images{i}, ~, tile_alphas{i}] = imread(tile_path);
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

            range = tile_max - tile_min + 1;
            tile_names = cell(range);
            
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
                    tile_names{i, j} = filename;
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
