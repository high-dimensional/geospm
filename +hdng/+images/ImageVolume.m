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

classdef ImageVolume < handle
    %ImageVolume A descriptor of a (x, y, z/t, channels) dimensional volume.
    %   
    
    properties
        
        description
        path
        attributes
        
    end
    
    properties (Dependent, Transient)
        
        data
        alpha_channel_index
        non_alpha_indices
        
        dimensions % 4-vector ? The size of the data in the x, y, z and c dimensions
        
        x % scalar ? The size of the x (or first) dimension of the data
        y % scalar ? The size of the y (or second) dimension of the data
        z % scalar ? The size of the z (or third) dimension of the data
        c % scalar ? The size of the c/channel (or fourth) dimension of the data
        
    end
    
    properties (GetAccess=private, SetAccess=private)
        data_
        alpha_channel_index_
    end
    
    methods
        
        function obj = ImageVolume(data, description, path)
            
            obj.description = description;
            obj.path = path;
            
            obj.attributes = struct();
            
            obj.data_ = [];
            obj.alpha_channel_index_ = 0;
            
            obj.data = data;
        end
        
        function result = get.alpha_channel_index(obj)
            result = obj.alpha_channel_index_;
        end
        
        function set.alpha_channel_index(obj, value)
            obj.alpha_channel_index_ = value;
        end
        
        function result = get.non_alpha_indices(obj)
            result = 1:obj.dimensions(4);
            
            alpha = obj.alpha_channel_index;
            
            if ~isempty(alpha)
                result = [result(1:alpha - 1) result(alpha + 1:end)];
            end
        end
        
        function result = get.dimensions(obj)
            
            result = ones(4, 1);
            tmp = size(obj.data_);
            N = numel(tmp);
            result(1:N) = tmp;
        end
        
        function result = get.x(obj)
            result = size(obj.data_, 1); %#ok<*CPROP>
        end
        
        function result = get.y(obj)
            result = size(obj.data_, 2); %#ok<*CPROP>
        end
        
        function result = get.z(obj)
            result = size(obj.data_, 3); %#ok<*CPROP>
        end
        
        function result = get.c(obj)
            result = size(obj.data_, 4); %#ok<*CPROP>
        end
        
        function result = get.data(obj)
            result = obj.data_;
        end
        
        function set.data(obj, value)
            obj.data_ = value;
            obj.alpha_channel_index_ = (obj.c == 2 || obj.c == 4) * obj.c;
        end
        
        function save_as_png(obj, bit_depth, channel)
            
            if ~exist('bit_depth', 'var')
                bit_depth = 8;
            end
            
            if ~exist('channel', 'var')
                channel = [];
            end
            
            if isempty(channel)
                colour_map = [];
            else
                colour_map = hdng.colour_mapping.GenericColourMap.monochrome();
            end
            
            colour_mode = hdng.colour_mapping.ColourMap.SLICE_MODE;
            
            hdng.images.ImageVolume.batch_render_as_png({obj}, bit_depth, colour_map, colour_mode, channel);
        end
        
        function result = get_channel(obj, channel)
            result = obj.data(:,:,:,channel);
        end
        
        function [image, alpha] = separate_image_and_alpha(obj, default_alpha)
            
            if ~exist('default_alpha', 'var')
                default_alpha = 1.0;
            end
            
            [image, alpha] = hdng.images.ImageVolume.separate_image_and_alpha_data(...
                obj.data, obj.alpha_channel_index, default_alpha);
        end
    end
    
    methods (Static)
        
        function [image, alpha] = separate_image_and_alpha_data(data, alpha_channel_index, default_alpha)
            
            if ~exist('default_alpha', 'var')
                default_alpha = 1.0;
            end
            
            x = size(data, 1);
            y = size(data, 2);
            z = size(data, 3);
            
            N_channels = size(data, 4);
            
            if alpha_channel_index
                
                channels = [1:alpha_channel_index - 1 alpha_channel_index + 1:N_channels];
                
                image = data(:, :, :, channels);
                alpha = data(:, :, :, alpha_channel_index);
            else
                image = data;
                alpha = ones([x, y, z, 1]) * default_alpha;
            end
        end
        
        function [component_type, dynamic_range] = bit_depth_parameters(bit_depth)
            
            if bit_depth == 8
                component_type = 'uint8';
                dynamic_range = 255;
            else
                if bit_depth == 16
                    component_type = 'uint16';
                    dynamic_range = 65535;
                else
                    error('ImageVolume.bit_depth_parameters(): Unsupported bit depth %d', bit_depth);
                end
            end
        end
        
        function result = global_ranges_from(volumes)
            
            n_images = numel(volumes);
            
            result = zeros(n_images, 2);

            for i=1:n_images
                
                range = volumes{i}.global_range;
                result(i, :) = range;
            end
        end
       
        function result = batch_colour_map_volume(batch, colour_map, channel)
            
            if ~exist('channel', 'var')
                channel = 1;
            end
            
            N = numel(batch);
            result = cell(N, 2);

            for i=1:N
                volume = batch{i};
                [image_data, legend] = colour_map.apply({volume.get_channel(channel)});
                image_data = reshape(image_data{1}, [volume.x, volume.y, volume.z, 3]);
                result{i, 1} = image_data;
                result{i, 2} = legend;
            end
        end
        
        function result = batch_colour_map_level_per_volume(batch, colour_map, channel)
            
            if ~exist('channel', 'var')
                channel = 1;
            end
            
            N = numel(batch);
            result = cell(N, 2);
            
            for i=1:N
                
                volume = batch{i};
                
                image_data = [];
                level_legends = cell(volume.z, 1);
                
                for level=1:volume.z
                    
                    [level_result, level_legend] = colour_map.apply({volume.data(:,:,level, channel)});
                    level_result = reshape(level_result{1}, [volume.x, volume.y, 1, 3]);
                    
                    image_data = cat(3, image_data, level_result);
                    level_legends{level} = level_legend;
                end
                
                result{i, 1} = image_data;
                result{i, 2} = level_legends;
            end
        end
        
        function result = batch_colour_map_all(batch, colour_map, channel)
            
            if ~exist('channel', 'var')
                channel = 1;
            end
            
            N = numel(batch);
            result = cell(N, 2);
            
            data_batch = cell(N, 1);
            
            for i=1:N
                data_batch{i} = batch{i}.get_channel(channel);
            end
            
            [image_result, legend] = colour_map.apply(data_batch);
            
            for i=1:N
                result{i, 1} = image_result{i};
                result{i, 2} = legend;
            end
        end
        
        function result = batch_colour_map_level_across_volumes(batch, colour_map, channel) %#ok<STOUT,INUSD>
            
            
            error('ImageVolume.batch_colour_map_level_across_volumes(): Not yet implemented.');
            
        end
        
        function results = batch_colour_map(batch, bit_depth, colour_map, mode, channel)
            
            if ~exist('channel', 'var')
                channel = 1;
            end
            
            N = numel(batch);
            mapped_data = cell(N, 2);
            
            data_batch = cell(N, 1);
            
            for i=1:N
                data_batch{i} = batch{i}.get_channel(channel);
            end
            
            [image_result, legend] = colour_map.apply(data_batch, mode);
            
            for i=1:N
                mapped_data{i, 1} = image_result{i};
                mapped_data{i, 2} = legend;
            end
            
            [component_type, dynamic_range] = hdng.images.ImageVolume.bit_depth_parameters(bit_depth);
            
            N = size(mapped_data, 1);
            results = cell(N, 3);
            
            for i=1:N
                
                I = mapped_data{i, 1} * dynamic_range;
                
                if batch{i}.alpha_channel_index
                    alpha = batch{i}.get_channel(batch{i}.alpha_channel_index);
                else
                    alpha = ones([batch{i}.x, batch{i}.y, batch{i}.z]);
                end
                
                I = cast(I, component_type);
                
                results{i, 1} = I;
                results{i, 2} = alpha;
                results{i, 3} = mapped_data{i, 2};
            end
        end
        
        function results = batch_render_as_png(batch, bit_depth, colour_map, mode, channel)
            
            if ~exist('channel', 'var')
                channel = 1;
            end
            
            if ~isempty(colour_map)
                results = hdng.images.ImageVolume.batch_colour_map(batch, bit_depth, colour_map, mode, channel);
            else
                N = numel(batch);
                results = cell(N, 3);
                
                for i=1:N
                    volume = batch{i};
                    
                    if volume.alpha_channel_index
                        alpha = volume.get_channel(volume.alpha_channel_index);
                    else
                        alpha = ones([volume.x, volume.y, volume.z]);
                    end
                    
                    I = volume.data(:, :, :, volume.non_alpha_indices);
                    
                    results{i, 1} = I;
                    results{i, 2} = alpha;
                    results{i, 3} = [];
                end
            end
            
            N = size(results, 1);
            K = size(results, 2);
            
            results = [results, cell(N, 1)];
            
            for i=1:N
                
                volume = batch{i};
                
                I = results{i, 1};
                alpha = results{i, 2};
                
                n_levels = size(I,3);
                
                paths = cell(1, n_levels);
                
                for j=1:n_levels
                    
                    L = reshape(I(:, :, j, :), size(I, 1), size(I, 2), size(I, 4));
                    L_alpha = reshape(alpha(:,:,j), size(alpha, 1), size(alpha, 2));
                    
                    L = permute(L, [2, 1, 3]);
                    L_alpha = permute(L_alpha, [2, 1]);
                    
                    level_path = [volume.path '_' num2str(j, '%03d') '.png'];
                    paths{j} = level_path;
                    
                    optional = {};
                    
                    if volume.description
                        optional{end + 1} = 'Description'; %#ok<AGROW>
                        optional{end + 1} = volume.description; %#ok<AGROW>
                    end
                    
                    imwrite(flip(L), level_path, 'Alpha', flip(L_alpha), 'BitDepth', bit_depth, optional{:});
                end
                
                results{i, K} = paths;
            end
        end
        
        function results = batch_render_as_vpng(batch, bit_depth, colour_map, mode)
            
            results = hdng.images.ImageVolume.batch_colour_map(batch, bit_depth, colour_map, mode);
            
            N = size(results, 1);
            K = size(results, 2);
            
            results = [results, cell(N, 1)];
            
            for i=1:N
                
                volume = batch{i};
                
                I = results{i, 1};
                alpha = results{i, 2};
                
                L = flip(I, 3);
                L_alpha = flip(alpha, 3);
                
                L = permute(L, [2, 3, 1, 4]);
                L_alpha = permute(L_alpha, [2, 3, 1]);
                
                L = reshape(L, size(I, 2) * size(I, 3), size(I, 1), size(I, 4));
                L_alpha = reshape(L_alpha, size(I, 2) * size(I, 3), size(I, 1));
                
                optional = {};
                
                if volume.description
                    optional{end + 1} = 'Description'; %#ok<AGROW>
                    optional{end + 1} = volume.description; %#ok<AGROW>
                end

                image_path = [volume.path '(' num2str(size(I, 3)) '@' num2str(size(I, 1)) ',' num2str(size(I, 2)) ').png'];
                results{i, K + 1} = { image_path };
                imwrite(flip(L), image_path, 'Alpha', flip(L_alpha), 'BitDepth', bit_depth, optional{:});
            end
        end
        
        
        function results = batch_render_as_geotiff(batch, ...
                bit_depth, colour_map, mode, ...
                grid, crs_or_identifier, centre_pixels)
            
            if ~exist('centre_pixels', 'var')
                centre_pixels = true;
            end
            
            crs_identifier = '';
            
            if ischar(crs_or_identifier)
                crs_identifier = crs_or_identifier;
            elseif isa(crs_or_identifier, 'hdng.SpatialCRS') && ~isempty(crs_or_identifier)
                crs_identifier = crs_or_identifier.identifier;
            end
            
            for i=1:numel(batch)
                volume = batch{i};
                
                if ~isequal([volume.x, volume.y], grid.resolution(1:2))
                    error('ImageVolume.batch_render_as_geotiff(): xyz dimensions of volume in batch doesn''t match grid resolution.');
                end
            end
            
            C = [0  1  -1; ...
                 1  0  -1; ...
                 0  0   1];

            results = hdng.images.ImageVolume.batch_colour_map(batch, bit_depth, colour_map, mode);
            
            N = size(results, 1);
            K = size(results, 2);
            
            results = [results, cell(N, 1)];
            
            for i=1:N
                
                volume = batch{i};
                
                I = results{i, 1};
                alpha = results{i, 2};
                
                n_levels = size(I,3);
                
                paths = cell(1, n_levels);
                
                for j=1:n_levels
                    
                    L = reshape(I(:, :, j, :), size(I, 1), size(I, 2), size(I, 4));
                    L_alpha = reshape(alpha(:,:,j), size(alpha, 1), size(alpha, 2));
                    
                    L = permute(L, [2, 1, 3]);
                    L_alpha = permute(L_alpha, [2, 1]) * 255.0;
                    
                    file_path = [volume.path '_' num2str(j, '%03d') '.tif'];
                    
                    I_level = cat(3, L, L_alpha);
                    
                    N_samples = size(I_level, 3);

                    tags = struct();
                    tags.('Compression') = Tiff.Compression.LZW;

                    if N_samples == 4 || N_samples == 2
                        tags.('ExtraSamples') = Tiff.ExtraSamples.AssociatedAlpha;
                    end

                    if N_samples == 4 || N_samples == 3
                        tags.('Photometric') = Tiff.Photometric.RGB;
                    else
                        tags.('Photometric') = Tiff.Photometric.MinBlack;
                    end

                    extra_arguments = {...
                        %'GeoKeyDirectoryTag', info.GeoTIFFTags.GeoKeyDirectoryTag, ...
                        'TiffTags', tags};
                    
                    if ~isempty(crs_identifier)
                        extra_arguments{end + 1} = 'CoordRefSysCode'; %#ok<AGROW>
                        extra_arguments{end + 1} = crs_identifier; %#ok<AGROW>
                    end
                    
                    raster_ref = grid.compute_raster_reference_for_w(j, centre_pixels);
                    R = (raster_ref * C)';
                    
                    geospm.geotiffpatch.geotiffwrite(file_path, I_level, R, ...
                        extra_arguments{:});
                    
                    paths{j} = file_path;
                end
                
                results{i, K + 1} = paths;
            end
        end
        
        function result = raster_reference_to_esri_world_file(reference, file_path)
            
            if ~isnumeric(reference) || ~isequal(size(reference), [2, 3])
                error('ImageVolumen.raster_reference_to_esri_world_file(): reference must be 2 x 3 matrix.');
            end
            
            result = [num2str(reference(1, 1), '%f') newline ...
                      num2str(reference(2, 1), '%f') newline ...
                      num2str(reference(1, 2), '%f') newline ...
                      num2str(reference(2, 2), '%f') newline ...
                      num2str(reference(1, 3), '%f') newline ...
                      num2str(reference(2, 3), '%f') newline];
            
            if exist('file_path', 'var') && numel(file_path) ~= 0
                hdng.utilities.save_text(result, file_path);
            end
        end
        
        function files = batch_render_with_georeference(formats, ...
                    batch, bit_depth, colour_map, colour_mode, ...
                    grid, crs_or_identifier, centre_pixels)
        
            if ischar(formats)
                formats = {formats};
            end
            
            if ~exist('grid', 'var')
                grid = geospm.Grid();
            end
            
            if isempty(grid)
                grid = geospm.Grid();
            end
            
            if ~exist('crs_or_identifier', 'var')
                crs_or_identifier = hdng.SpatialCRS.empty;
            end
            
            if ischar(crs_or_identifier)
                crs_or_identifier = hdng.SpatialCRS.from_identifier(crs_or_identifier);
            end
            
            if ~exist('centre_pixels', 'var')
                centre_pixels = true;
            end
            
            files = cell(numel(batch), numel(formats));
            
            for i=1:numel(formats)
                format = formats{i};

                crs = crs_or_identifier;
                add_sidecar_files = ~isempty(crs);
                flip_y = true;
                
                %world_file_extension = '.wld';

                if strcmpi(format, 'png')
                    results = hdng.images.ImageVolume.batch_render_as_png(batch, bit_depth, colour_map, colour_mode);
                    world_file_extension = '.pgw';
                elseif strcmpi(format, 'tif') || strcmpi(format, 'tiff')
                    add_sidecar_files = false;
                    results = hdng.images.ImageVolume.batch_render_as_geotiff(batch, bit_depth, colour_map, colour_mode, grid, crs_or_identifier, centre_pixels);
                    world_file_extension = '.tgw';
                else
                    error(['ImageVolume.batch_render(): Unknown format ''' format '''.''']);
                end
                
                paths = results(:, 4);
                files(:, i) = paths;

                if add_sidecar_files

                    N = size(results, 1);

                    for v=1:N

                        volume = batch{v};

                        I = results{v, 1};
                        n_levels = size(I,3);

                        for j=1:n_levels

                            base_path = [volume.path '_' num2str(j, '%03d')];
                            file_path = [base_path world_file_extension];

                            raster_ref = grid.compute_raster_reference_for_w(j, centre_pixels, flip_y);
                            hdng.images.ImageVolume.raster_reference_to_esri_world_file(raster_ref, file_path);

                            file_path = [base_path '.prj'];
                            hdng.utilities.save_text(crs.wkt.format_as_text(), file_path);
                        end
                    end
                end
            end
        end
    end
    
end
