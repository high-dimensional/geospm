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

 classdef SPMRenderImages < geospm.stages.SpatialAnalysisStage
    %SPMRenderImages Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        image_formats
        centre_pixels
        gather_volumes_only
        
        render_component_contrasts
        render_maskless_maps
        render_residuals
        
        render_intercept_separately
        
        volume_renderer
        monochrome_renderer
        mask_renderer
        ignore_crs
    end
    
    methods
        
        function obj = SPMRenderImages(analysis)
            
            obj = obj@geospm.stages.SpatialAnalysisStage(analysis);

            obj.volume_renderer = geospm.volumes.ColourMapping();
            
            obj.monochrome_renderer = geospm.volumes.ColourMapping();
            obj.monochrome_renderer.colour_map = hdng.colour_mapping.GenericColourMap.monochrome();
            
            obj.mask_renderer = geospm.volumes.ColourMapping();
            obj.mask_renderer.colour_map = hdng.colour_mapping.GenericColourMap.monochrome(0, 1);
            
            obj.ignore_crs = false;
            obj.image_formats = {'tif'};
            obj.centre_pixels = true;
            obj.gather_volumes_only = false;
            obj.render_component_contrasts = false;
            obj.render_maskless_maps = true;
            obj.render_residuals = true;
            obj.render_intercept_separately = false;
            
            obj.define_requirement('directory');
            obj.define_requirement('spm_output_directory');
            
            obj.define_requirement('thresholds');
            obj.define_requirement('threshold_contrasts');
            obj.define_requirement('threshold_directories');
            
            obj.define_requirement('sample_density', ...
                struct(), 'is_optional', true, 'default_value', []);
            
            obj.define_requirement('volume_mask', ...
                struct(), 'is_optional', true, 'default_value', []);
            
            obj.define_requirement('grid_data', ...
                struct(), 'is_optional', true, 'default_value', []);
            
            obj.define_product('image_records');
            obj.define_product('beta_records');
            obj.define_product('density_image');
            obj.define_product('volume_mask_image');
        end
        
        function result = render_images(obj, image_set, alpha_set, render_settings, directory, renderer)

            if ~exist('renderer', 'var')
                renderer = obj.volume_renderer;
            end
            
            file_paths = image_set.file_paths;
            descriptions = image_set.descriptions;
            
            intercept_image_set = [];
            intercept_alpha_set = [];
            intercept_indices = [];
            non_intercept_indices = [];
            
            if obj.render_intercept_separately

                intercept_matches = regexp(image_set.descriptions, 'intercept(\s+\[[^]]+])?', 'match');

                for index=1:numel(image_set.descriptions)
                    match = intercept_matches{index};
                    
                    if isempty(match)
                        intercept_matches{index} = '';
                    else
                        intercept_matches{index} = match{1};
                    end
                end

                intercept_indices = strcmp(intercept_matches, 'intercept');

                non_intercept_indices = (1:numel(image_set.file_paths))';
                non_intercept_indices = non_intercept_indices(~intercept_indices);

                intercept_indices = find(intercept_indices);

                if ~isempty(intercept_indices)
                    
                    intercept_image_set = image_set.select(intercept_indices);
                    image_set = image_set.select(non_intercept_indices);

                    if ~isempty(alpha_set)
                        intercept_alpha_set = alpha_set.select(intercept_indices);
                        alpha_set = alpha_set.select(non_intercept_indices);
                    end
                end
            end
            
            result = hdng.utilities.Dictionary();
            
            if ~obj.gather_volumes_only
                
                context = geospm.volumes.RenderContext();
                context.render_settings = render_settings;

                context.image_volumes = image_set;
                context.alpha_volumes = alpha_set;
                context.output_directory = directory;
                
                image_paths = renderer.render(context);

                if ~isempty(intercept_image_set)
                    context.image_volumes = intercept_image_set;
                    context.alpha_volumes = intercept_alpha_set;
                    
                    intercept_image_paths = renderer.render(context);
                    
                    image_paths_tmp = cell(numel(file_paths), 1);
                    image_paths_tmp(non_intercept_indices) = image_paths;
                    image_paths_tmp(intercept_indices) = intercept_image_paths;
                    
                    image_paths = image_paths_tmp;
                end
                
                for index=1:numel(image_paths)
                    paths = image_paths{index};
                    image_paths(index) = paths(1);
                end
            else
                image_paths = {};
            end
            
            result('volumes') = hdng.experiments.Value.from(file_paths);
            result('images') = hdng.experiments.Value.from(image_paths);
            result('descriptions') = hdng.experiments.Value.from(descriptions);
                
            result = hdng.experiments.Value.from(result);
        end
        
        function result = render_beta_images(obj, beta_records, output_directory, session, render_settings)
            
            beta_names = session.regression_x_names;
            beta_files = session.regression_beta_files;
            
            volume_set = geospm.volumes.VolumeSet();
            volume_set.file_paths = beta_files;
            volume_set.descriptions = beta_names;

            result = obj.render_images(volume_set, [], render_settings, output_directory);
            
            beta_images = result.content('images').content;
            
            for i=1:numel(beta_files)
                
                file_path = beta_files{i};
                name = beta_names{i};

                beta_record = hdng.utilities.Dictionary();
                beta_record('name') = hdng.experiments.Value.from(name);
                beta_record('beta_volume') = hdng.experiments.Value.from(file_path);
                
                if ~obj.gather_volumes_only
                    image_path = beta_images{i};
                    beta_record('beta_image') = hdng.experiments.Value.from(image_path);
                end
                
                beta_records.include_record(beta_record);
            end
        end
        
        function result = render_contrast_images(obj, threshold_contrasts, output_directory, session, render_settings)
            
            
            result = hdng.utilities.Dictionary();

            volumes = {};
            images = {};
            descriptions = {};

            for index=1:numel(threshold_contrasts)
    
                contrasts = threshold_contrasts{index};
                
                % When there are multiple components in a composite 
                % contrast we only select the first one.

                volume_set = geospm.volumes.VolumeSet();
                volume_set.file_paths = session.contrast_files(contrasts(:, 1));
                volume_set.descriptions = session.contrast_names(contrasts(:, 1));
                
                for k=1:numel(volume_set.descriptions)
                    volume_set.descriptions{k} = [volume_set.descriptions{k} ' [contrast]'];
                end
                
                if size(contrasts, 2) > 1

                    volume_set.optional_output_names = cell(size(contrasts, 1), 1);

                    for k=1:size(contrasts, 1)

                        contrast_name = 'con';

                        for c=1:size(contrasts, 2)
                            contrast_name = [contrast_name, '_', sprintf('%04d', contrasts(k, c))]; %#ok<AGROW> 
                        end

                        volume_set.optional_output_names{k} = contrast_name;
                    end
                end

                result = obj.render_images(volume_set, [], render_settings, output_directory);
                result = result.content;

                tmp_volumes = result('volumes').content;
                tmp_images = result('images').content;
                tmp_descriptions = result('descriptions').content;

                volumes = [volumes; tmp_volumes]; %#ok<AGROW> 
                images = [images; tmp_images]; %#ok<AGROW> 
                descriptions = [descriptions; tmp_descriptions]; %#ok<AGROW> 
            end
            
            result('volumes') = hdng.experiments.Value.from(volumes);
            result('images') = hdng.experiments.Value.from(images);
            result('descriptions') = hdng.experiments.Value.from(descriptions);

            result = hdng.experiments.Value.from(result);
        end
        
        function result = render_map_images(obj, output_directory, session, render_settings)
            
            volume_set = geospm.volumes.VolumeSet();
            volume_set.file_paths = session.contrast_map_files;
            volume_set.descriptions = session.contrast_names;
            
            statistics = session.contrast_map_statistics;

            for k=1:numel(volume_set.descriptions)
                volume_set.descriptions{k} = [volume_set.descriptions{k} ' [' statistics{k} ' map]'];
            end

            result = obj.render_images(volume_set, [], render_settings, output_directory);
        end
        
        
        function result = render_residuals_image(obj, output_directory, session, render_settings)
            
            volume_set = geospm.volumes.VolumeSet();
            volume_set.file_paths = { session.regression_residual_sum_of_squares_file };
            volume_set.descriptions = { 'Residual Sum of Squares' };

            result = obj.render_images(volume_set, [], render_settings, output_directory, obj.monochrome_renderer);
        end
        
        function image_record = build_image_record(obj, threshold_index, statistic, ...
                    mask_file_paths, map_file_paths, map_descriptions, ...
                    map_output_names, ...
                    contrast_file_paths, contrast_descriptions, ...
                    settings, output_directory)

            image_record = hdng.utilities.Dictionary();
            image_record('threshold') = hdng.experiments.Value.from(threshold_index);
            image_record('statistic') = hdng.experiments.Value.from(statistic);

            mask_set = geospm.volumes.VolumeSet();
            mask_set.file_paths = mask_file_paths;

            masks_value = obj.render_images(mask_set, [], settings, output_directory, obj.mask_renderer);

            map_set = geospm.volumes.VolumeSet();
            map_set.file_paths = map_file_paths;
            map_set.descriptions = map_descriptions;
            map_set.optional_output_names = map_output_names;

            maps_value = obj.render_images(map_set, mask_set, settings, output_directory);
            
            if obj.render_maskless_maps
                map_without_mask_set = geospm.volumes.VolumeSet();
                map_without_mask_set.file_paths = map_file_paths;
                map_without_mask_set.descriptions = map_descriptions;
                map_without_mask_set.optional_output_names = map_output_names;

                for i=1:numel(map_without_mask_set.file_paths)

                    if numel(map_without_mask_set.optional_output_names) >= i
                        output_name = [map_without_mask_set.optional_output_names{i} '_unmasked'];
                    else
                        [~, output_name, ~] = fileparts(map_without_mask_set.file_paths{i});
                        output_name = [output_name '_unmasked']; %#ok<AGROW>
                    end

                    map_without_mask_set.optional_output_names{i} = output_name;
                end

                maps_value = obj.render_images(map_without_mask_set, [], settings, output_directory);
            end
            
            contrast_set = geospm.volumes.VolumeSet();
            contrast_set.file_paths = contrast_file_paths;
            contrast_set.descriptions = contrast_descriptions;

            contrasts_value = obj.render_images(contrast_set, mask_set, settings, output_directory);

            image_record('masks') = masks_value;
            image_record('maps') = maps_value;
            image_record('contrasts') = contrasts_value;
        end
        
        function [pseudo_contrasts, pseudo_maps] = define_pseudo_contrasts_and_maps(~, session, beta_volumes)
            
            pseudo_contrasts = containers.Map('KeyType', 'char', 'ValueType', 'any');
            pseudo_maps = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            beta_files = session.regression_beta_files;
            
            entry = struct();
            entry.volumes = cell(numel(beta_files), 1);
            
            for i=1:numel(beta_files)
                
                file_path = beta_files{i};
                [~, file_name, file_ext] = fileparts(file_path);
                
                file_name = [file_name, file_ext]; %#ok<AGROW>
                
                [start, tokens] = regexp(file_name, '^beta_([0-9]+)\.nii$', 'start', 'tokens');

                if isempty(start)
                    continue
                end
                
                beta_index = str2double(tokens{1});
                
                entry.volumes{beta_index} = beta_volumes{i};
            end
            
            pseudo_contrasts('beta') = entry;
            pseudo_maps('beta') = entry;
        end
        
        function result = run(obj, arguments)
            
            result = struct();
            
            image_records = hdng.experiments.RecordArray();
            beta_records = hdng.experiments.RecordArray();
            
            result.image_records = image_records;
            result.beta_records = beta_records;
            
            session = geospm.spm.SPMSession(fullfile(arguments.spm_output_directory, 'SPM.mat'));
            
            grid = geospm.Grid();
            crs = hdng.SpatialCRS.empty;
            
            if ~isempty(arguments.grid_data)
                grid = arguments.grid_data.grid;
                crs = arguments.grid_data.crs;
            end
            
            if obj.ignore_crs
                crs = hdng.SpatialCRS.empty;
            end
            
            settings = geospm.volumes.RenderSettings();
            
            settings.formats = obj.image_formats;
            settings.grid = grid;
            settings.crs = crs;
            settings.centre_pixels = obj.centre_pixels;
            
            output_directory = fullfile(arguments.directory, 'images');
            hdng.utilities.rmdir(output_directory, true, false);
            
            [dirstatus, dirmsg] = mkdir(output_directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            monochrome = hdng.colour_mapping.GenericColourMap.monochrome();
            monochrome_mode = hdng.colour_mapping.ColourMap.SLICE_MODE;
            
            if ~isempty(arguments.sample_density) && ~obj.gather_volumes_only
                density_volume = hdng.images.ImageVolume(arguments.sample_density, 'density', fullfile(output_directory, 'density'));
                
                if isempty(settings.crs)
                    density_files = hdng.images.ImageVolume.batch_render_as_vpng({density_volume}, 8, monochrome, monochrome_mode);
                    density_files = density_files(:, 4);
                else
                    density_files = hdng.images.ImageVolume.batch_render_with_georeference(settings.formats, {density_volume}, 8, monochrome, monochrome_mode, grid, crs);
                end
                
                density_files = density_files{1};
                result.density_image = density_files{1};
            else
                result.density_image = '';
            end
            
            bw = hdng.colour_mapping.GenericColourMap.monochrome(0, 1);
            bw_mode = hdng.colour_mapping.ColourMap.SLICE_MODE;
            
            if ~isempty(arguments.volume_mask) && ~obj.gather_volumes_only
                volume_mask = hdng.images.ImageVolume(arguments.volume_mask, 'global mask', fullfile(output_directory, 'global_mask'));
                
                if isempty(settings.crs)
                    volume_mask_files = hdng.images.ImageVolume.batch_render_as_vpng({volume_mask}, 8, bw, bw_mode);
                    volume_mask_files = volume_mask_files(:, 4);
                else
                    volume_mask_files = hdng.images.ImageVolume.batch_render_with_georeference(settings.formats, {volume_mask}, 8, bw, bw_mode, grid, crs);
                end
                
                volume_mask_files = volume_mask_files{1};
                result.volume_mask_image = volume_mask_files{1};
            else
                result.volume_mask_image = '';
            end
            
            if obj.render_residuals && ~obj.gather_volumes_only
                obj.render_residuals_image(output_directory, session, settings);
            end
            
            context = geospm.volumes.RenderContext();
            context.render_settings = settings;
            
            threshold_contrasts = arguments.threshold_contrasts;

            unmasked_betas_value = obj.render_beta_images(beta_records, output_directory, session, settings);
            unmasked_contrasts_value = obj.render_contrast_images(threshold_contrasts, output_directory, session, settings);
            unmasked_maps_value = obj.render_map_images(output_directory, session, settings);
            
            unmasked_beta_volumes = unmasked_betas_value.content('volumes').content;
            
            [pseudo_contrasts, pseudo_maps] = obj.define_pseudo_contrasts_and_maps(session, unmasked_beta_volumes);
            
            entry = struct();
            entry.volumes = unmasked_contrasts_value.content('volumes').content;
            entry.descriptions = unmasked_contrasts_value.content('descriptions').content;
            
            pseudo_contrasts('T') = entry;
            pseudo_contrasts('F') = entry;
            pseudo_contrasts('t_map') = entry;
            
            entry = struct();
            entry.volumes = unmasked_maps_value.content('volumes').content;
            entry.descriptions = unmasked_maps_value.content('descriptions').content;
            
            pseudo_maps('T') = entry;
            pseudo_maps('F') = entry;
            pseudo_maps('t_map') = entry;
            
            % Image record array:
            %
            %   threshold
            %   statistic <- Do we really need this?
            %   contrasts
            %   maps
            %   masks
            %
            
            image_record = hdng.utilities.Dictionary();
            image_record('threshold') = hdng.experiments.Value.empty_with_label('No threshold');
            image_record('statistic') = hdng.experiments.Value.empty_with_label('All statistics');
            image_record('masks') = hdng.experiments.Value.empty_with_label('No masks');
            image_record('maps') = unmasked_maps_value;
            image_record('contrasts') = unmasked_contrasts_value;
            
            image_records.include_record(image_record);
            
            for threshold_index=1:numel(arguments.threshold_directories)

                threshold_directory = arguments.threshold_directories{threshold_index};
                
                [~, threshold_directory_name, ext] = fileparts(threshold_directory);
                threshold_directory_name = [threshold_directory_name ext]; %#ok<AGROW>
                
                threshold_output_directory = fullfile(output_directory, threshold_directory_name);
                
                [matched_files, matched_pairs, matched_statistics] = session.match_statistic_paired_threshold_files('', threshold_directory);
                
                if ~isempty(matched_files)

                    if numel(matched_statistics) ~= 1
                        error('SPMRenderImages.run(): Cannot handle a threshold with more than one statistic.');
                    end
                    
                    matched_statistic = matched_statistics{1};
                    map_output_names = cell(numel(matched_files), 1);
                    
                    for index=1:numel(matched_files)
                        [~, file_name, ~] = fileparts(matched_files{index});
                        
                        if endsWith(file_name, '_mask')
                            file_name = file_name(1:end-5);
                        end
                        
                        map_output_names{index} = file_name;
                    end
                    
                    map_file_paths = pseudo_maps(matched_statistic);
                    map_descriptions = map_file_paths.descriptions(matched_pairs(:, 1));
                    map_file_paths = map_file_paths.volumes(matched_pairs(:, 1));
                    
                    contrast_file_paths = pseudo_contrasts(matched_statistic);
                    contrast_descriptions = contrast_file_paths.descriptions(matched_pairs(:, 1));
                    contrast_file_paths = contrast_file_paths.volumes(matched_pairs(:, 1));
                    
                    image_record = obj.build_image_record(...
                        threshold_index, matched_statistic, ...
                        matched_files, map_file_paths, map_descriptions, map_output_names, ...
                        contrast_file_paths, contrast_descriptions, settings, threshold_output_directory);
                    
                    image_records.include_record(image_record);
                end
                
                [match_result, matched_statistics] = session.match_statistic_threshold_files('', threshold_directory);
                
                if isempty(match_result.matched_files)
                    [match_result, matched_statistics] = session.match_pseudo_statistics_threshold_files(threshold_directory, {'beta', 't_map'});
                end
                
                if isempty(matched_files) || obj.render_component_contrasts
                
                    if ~match_result.did_match_all_files
                        error(['SPMRenderImages.run(): Couldn''t locate all threshold files in ''' threshold_directory '''.']);
                    end

                    if numel(matched_statistics) == 0
                        continue;
                    elseif numel(matched_statistics) ~= 1
                        error('SPMRenderImages.run(): Cannot handle a threshold with more than one statistic.');
                    end
                    
                    matched_files = match_result.matched_files;
                    matched_statistic = matched_statistics{1};
                    
                    map_output_names = {};
                    
                    map_file_paths = pseudo_maps(matched_statistic);
                    map_descriptions = map_file_paths.descriptions(match_result.matched_contrasts);
                    map_file_paths = map_file_paths.volumes(match_result.matched_contrasts);
                    
                    contrast_file_paths = pseudo_contrasts(matched_statistic);
                    contrast_descriptions = contrast_file_paths.descriptions(match_result.matched_contrasts);
                    contrast_file_paths = contrast_file_paths.volumes(match_result.matched_contrasts);
                    
                    image_record = obj.build_image_record(...
                        threshold_index, matched_statistic, ...
                        matched_files, map_file_paths, map_descriptions, map_output_names, ...
                        contrast_file_paths, contrast_descriptions, settings, threshold_output_directory);
                    
                    image_records.include_record(image_record);
                end
            end
        end
    end
end
