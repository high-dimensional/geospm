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

classdef Kriging < geospm.validation.SpatialExperiment
    %Kriging Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        thresholds
        null_level
        null_level_map
        standardise_predictions
        
        run_global_smoothing_level
        run_local_smoothing_levels
        
        applicable_smoothing_levels
        
        variogram_function
        add_nugget
        
        adjust_variance
    end
    
    properties (Dependent, Transient)
        kriging_directory_path
    end
    
    methods
        
        function obj = Kriging(seed, ...
                        directory, ...
                        run_mode, ...
                        nifti_mode, ...
                        model_and_metadata, ...
                        sampling_strategy, ...
                        N_samples, ...
                        domain_expression, ...
                        thresholds, ...
                        variogram_function, ...
                        add_nugget)
            
            obj = obj@geospm.validation.SpatialExperiment(seed, directory, ...
                run_mode, nifti_mode, ...
                model_and_metadata, sampling_strategy, N_samples, ...
                domain_expression);
            
            obj.thresholds = thresholds;
            obj.null_level = 0.5;
            obj.null_level_map = containers.Map('KeyType', 'char', 'ValueType', 'double');
            obj.standardise_predictions = true;
            
            obj.variogram_function = variogram_function;
            obj.add_nugget = add_nugget;
            
            obj.adjust_variance = false;
            
            obj.run_global_smoothing_level = true;
            obj.run_local_smoothing_levels = false;
            
            obj.applicable_smoothing_levels = [];
            
            obj.write_z_coordinate = false;
            
            attribute = obj.result_attributes.define('covariances');
            attribute.description = 'Covariance Terms';
            
            attribute = obj.result_attributes.define('add_nugget');
            attribute.description = 'Add Nugget';
        end
        
        function results = format_smoothing_levels(obj)
            
            results = {};
            
            if obj.run_local_smoothing_levels
                for i=1:numel(obj.applicable_smoothing_levels)
                    results{end + 1} = num2str(obj.applicable_smoothing_levels(i), '%.3f'); %#ok<AGROW>
                end
            end
            
            if obj.run_global_smoothing_level
                results{end + 1} = 'global';
            end
        end
        
        
        function compute_spatial_data(obj)
            
            do_filter_interaction_terms = false;
            
            if do_filter_interaction_terms
                
                %{
                predictor_terms = obj.variable_term_indices();
                
                for i=1:numel(predictor_terms)
                    index = predictor_terms{i};
                    term = obj.domain_expression.terms{index};
                    predictor_terms{i} = term;
                end
                
                obj.spatial_data_expression = geospm.models.DomainExpression(predictor_terms);
                %}
            end
            
            obj.spatial_data = obj.spatial_data_expression.compute_spatial_data(obj.model.domain, obj.model_data);
        end
        
        
        function delete_existing_threshold_directories(obj)

            name_pattern = '^th_([0-9]+).*';

            %Scan the directory for files matching the name pattern
            threshold_directories = hdng.utilities.scan_directories(obj.directory, name_pattern);
            
            for index=1:numel(threshold_directories)
                threshold_directory = threshold_directories{index};
                hdng.utilities.rmdir(threshold_directory, true, false);
            end
        end
        
        function run(obj)
            
            run@geospm.validation.SpatialExperiment(obj);
            
            if strcmp(obj.run_mode, geospm.validation.SpatialExperiment.RESUME_MODE)
                obj.delete_existing_threshold_directories();
            end
            
            %Write targets
            target_records = obj.write_targets();
            
            %Setup and run analysis
            expression_data_path = fullfile(obj.directory, [obj.expression_data_name '.csv']);
            [kriging_directory, command_files] = obj.run_kriging(expression_data_path, obj.variogram_function);
            
            obj.results('terms') = hdng.experiments.Value.from(obj.define_term_records());
            obj.results('duration') = hdng.experiments.Value.from(0.0);
            obj.results('command_paths') = hdng.experiments.Value.from(command_files);
            obj.nifti_files = {};
            
            if ~strcmp(obj.run_mode, geospm.validation.SpatialExperiment.DEFERRED_MODE)
                
                if ~strcmp(obj.run_mode, geospm.validation.SpatialExperiment.LOAD_MODE)
                    
                    result_name = [obj.expression_data_name '_cokriged.mat'];

                    [term_records, covariance_records, duration] = ...
                        obj.build_niftis_and_render_images(target_records, kriging_directory, result_name);

                    obj.results('terms') = hdng.experiments.Value.from(term_records);

                    if covariance_records.length > 0
                        obj.results('covariances') = hdng.experiments.Value.from(covariance_records);
                    end

                    obj.results('duration') = hdng.experiments.Value.from(duration);
                    
                else
                    obj.reuse_results();
                    term_records = obj.results('terms').content;
                end
                
                obj.nifti_files = obj.gather_nifti_files_from_term_records(term_records);
            end
        end
        
        function result = get.kriging_directory_path(obj)
            result = fullfile(obj.directory, 'kriging_output');
        end
        
        function [kriging_directory, command_files] = run_kriging(obj, kriging_data_path, variogram_function)
            
            kriging_directory = fullfile(obj.directory, 'kriging_output');
            
            [dirstatus, dirmsg] = mkdir(kriging_directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            command_files = {};
            
            r_interface = geospm.validation.SpatialExperiment.create_r_interface();
            
            if obj.run_global_smoothing_level
                command_file = obj.run_level(r_interface, kriging_directory, kriging_data_path, [], variogram_function);
                
                if ~isempty(command_file)
                    command_files{end + 1} = command_file;
                end
            end
            
            if obj.run_local_smoothing_levels
                for i=1:numel(obj.applicable_smoothing_levels)
                    fwhm = obj.applicable_smoothing_levels(i);
                    command_file = obj.run_level(r_interface, kriging_directory, kriging_data_path, fwhm, variogram_function);

                    if ~isempty(command_file)
                        command_files{end + 1} = command_file; %#ok<AGROW>
                    end
                end
            end
        end
        
        function command_file = run_level(obj, r_interface, kriging_directory, data_path, max_distance, variogram_function)
            
            if ~isempty(max_distance)
                output_directory = fullfile(kriging_directory, num2str(max_distance, '%d'));
            else
                output_directory = fullfile(kriging_directory, 'global');
            end
            
            [dirstatus, dirmsg] = mkdir(output_directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            output_directory_argument = output_directory;
            
            if strcmp(obj.run_mode, geospm.validation.SpatialExperiment.DEFERRED_MODE)
                output_directory_argument = ['${OUTPUT_ROOT}/' obj.canonical_path(output_directory)];
                data_path = ['${INPUT_ROOT}/' obj.canonical_path(data_path)];
            end
            
            arguments = {
                'cokrige', ...
                '-o', output_directory_argument, ...
                '-r', sprintf('%d', obj.rng.randi(2^31 - 1)), ...
                '-s', '1', ...
                '-t', '1', ...
                '-m', num2str(obj.model.spatial_resolution(1), '%d'), ...
                '-n', num2str(obj.model.spatial_resolution(2), '%d'), ...
                '-c', variogram_function, ...
                };
            
            if obj.add_nugget
                arguments = [arguments {'-g'}];
            end
            
            if ~isempty(max_distance)
                arguments{end + 1} = '-d';
                arguments{end + 1} = num2str(max_distance, '%d');
            end
            
            arguments{end + 1} = data_path;
            
            command = r_interface.format_call(arguments{:});
            %command_file = '';
            
            file_path = fullfile(output_directory, 'command.txt');
            hdng.utilities.save_text(sprintf('%s %s', obj.canonical_path(obj.directory), command), file_path);
                
            %file_path = fullfile(output_directory, 'command.json');
            %hdng.utilities.save_text(hdng.utilities.encode_json(arguments), file_path);
                
            command_file = obj.canonical_path(file_path);
            
            if strcmp(obj.run_mode, geospm.validation.SpatialExperiment.REGULAR_MODE)
                r_interface.call(arguments{:});
            end
        end
        
        function results = load_level_results(obj, level, kriging_directory, file_name)
            
            level_directory = fullfile(kriging_directory, level);
            result_path = fullfile(level_directory, file_name);
            
            if exist(result_path, 'file')
                results = load(result_path, 'metadata', 'predictions', 'variances', 'covariances');
            else
                
                results = struct();
                results.metadata = struct();
                results.metadata.duration = 0;
                results.predictions = struct();
                results.variances = struct();
                results.covariances = struct();

                obj.log_diagnostic(...
                    sprintf('Missing results file ''%s'' for level ''%s''.', file_name, level), ...
                    'An empty results structure was created.');
            end
        end
        
        function [terms, covariances, duration] = gather_kriging_results(obj, kriging_directory, result_name)
            
            N_terms = obj.domain_expression.N_terms;
             
            levels = obj.format_smoothing_levels();
            dimensions = [obj.model.spatial_resolution numel(levels)];
            
            terms = struct();
            covariances = struct();
            
            % Initialize term_results, a structure which holds a field
            % named after each term. Each field is a substructure with
            % prediction and variance fields initialized to zero volumes.
            
            for i=1:N_terms
                name = obj.domain_expression.term_names{i};
                
                term = struct();
                
                term.prediction = zeros(dimensions);
                term.variance = zeros(dimensions);
                
                terms.(name) = term;
            end
            
            duration = 0.0;
            
            % Gather the results for prediction, variance and covariance
            % across all smoothing levels. Predictions and variances are
            % loaded into the respective fields for each term in term_results.
            % covariances_results will hold the covariance for each pair of terms
            % in a field.
            
            cov_names = {};
            N_covariances = 0;
            
            for i=1:numel(levels)
                
                level = levels{i};
                level_results = obj.load_level_results(level, kriging_directory, result_name);
                
                duration = duration + level_results.metadata.duration;
                
                if i == 1
                    cov_names = fieldnames(level_results.covariances);
                    N_covariances = numel(cov_names);
                end
                
                for j=1:N_covariances
                    name = cov_names{j};
                    covariance = level_results.covariances.(name);
                    covariances.(name)(:,:,i) = covariance;
                end
                
                for j=1:N_terms
                    
                    name = obj.domain_expression.term_names{j};
                    
                    term = terms.(name);
                    
                    if isfield(level_results.predictions, name) && ...
                       isfield(level_results.variances, name)
                   
                        prediction = level_results.predictions.(name);
                        variance = level_results.variances.(name);

                        term.prediction(:,:,i) = prediction;
                        term.variance(:,:,i) = variance;
                    else
                        obj.log_diagnostic(...
                            sprintf('Missing prediction or variance term field ''%s'' in results for level ''%s''.', name, level), ...
                            'The prediction and variance were set to zero.');
                    end
                    
                    terms.(name) = term;
                end
            end
        end
        
        function result = gather_nifti_files_from_term_records(obj, term_records)
            
            result = containers.Map('KeyType', 'char', 'ValueType', 'char');
            
            records = term_records.unsorted_records;
            
            for index=1:numel(records)
                record = records{index};
                
                volumes = { ...
                    record('prediction'), ...
                    record('variance'), ...
                    record('mask'), ...
                    record('target') };
                
                for v_index=1:numel(volumes)
                    
                    if strcmp(volumes{v_index}.type_identifier, 'builtin.null')
                        continue;
                    end
                    
                    volume = volumes{v_index}.content;
                    
                    if isempty(volume.scalars)
                        continue;
                    end
                    
                    if ~endsWith(volume.scalars.path, '.nii')
                        continue;
                    end
                    
                    result(volume.scalars.path) = obj.absolute_path(volume.scalars.path);
                end
            end
            
            result = result.values();
        end
        
        function term_records = define_term_records(~)
            
            term_records = hdng.experiments.RecordArray();
            
            term_records.define_attribute('threshold').description = 'Threshold';
            term_records.define_attribute('term').description = 'Term';
            term_records.define_attribute('prediction').description = 'Prediction';
            term_records.define_attribute('variance').description = 'Variance';
            term_records.define_attribute('mask').description = 'Mask';
            term_records.define_attribute('target').description = 'Target';
            term_records.define_attribute('result').description = 'Result';
            
            term_records.define_partitioning_attachment({
                struct('identifier', 'threshold', 'category', 'partitioning', 'view_mode', 'select'), ...
                struct('identifier', 'term', 'category', 'partitioning'), ...
                struct('identifier', 'prediction', 'category', 'content'), ...
                struct('identifier', 'variance', 'category', 'content'), ...
                struct('identifier', 'mask', 'category', 'content'), ...
                struct('identifier', 'target', 'category', 'content'), ...
                struct('identifier', 'result', 'category', 'content')});
        end
        
        function maps = build_test_maps_for_term(obj, context, renderer, kriging_directory, term_name, term)
            
            term_null_level = obj.null_level;
            
            if isKey(obj.null_level_map, term_name)
                term_null_level = obj.null_level_map(term_name);
            end
            
            maps = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            term_index = find(strcmp(term_name, obj.spatial_data.variable_names), 1);
            
            
            if ~obj.adjust_variance
                term_stddev = sqrt(term.variance);
            else
                %v = var(term.prediction(:));
                
                resolution = obj.model.spatial_resolution(1:2);
                v = zeros(resolution);

                for i=1:resolution(1)

                    select_x = floor(obj.spatial_data.x) == i;

                    for j=1:resolution(2)

                        select_y = floor(obj.spatial_data.y) == j;
                        values = obj.spatial_data.observations(select_x & select_y, term_index);

                        if isempty(values)
                            continue;
                        end

                        v(i, j) = var(values);
                    end
                end
                
                n_zero_cells = sum(v(1:2:end, 1:2:end) == 0, 'all') ...
                                + sum(v(1:2:end, 2:2:end) == 0, 'all') ...
                                + sum(v(2:2:end, 1:2:end) == 0, 'all');
                
                if n_zero_cells >= (floor(resolution(1) / 2) * floor(resolution(2) / 2) - 10)
                    v(1:2:end, :) = v(2:2:end, :);
                    v(:, 1:2:end) = v(:, 2:2:end);
                end
                
                term_stddev = sqrt((term.variance + v));
            end
            
            if obj.standardise_predictions
                statistic_map = (term.prediction - term_null_level) ./ term_stddev;
            else
                statistic_map = term.prediction;
            end
            
            statistic_path = fullfile(kriging_directory, [term_name '_normal.nii']);
            geospm.utilities.write_nifti(statistic_map, statistic_path);

            map_volume = hdng.experiments.VolumeReference();
            map_volume.scalars = hdng.experiments.ImageReference(obj.canonical_path(statistic_path), obj.source_ref);
            obj.render_image(map_volume, context, renderer);
            
            for i=1:numel(obj.thresholds)
                threshold = obj.thresholds{i};
                maps(threshold.distribution) = {statistic_path, statistic_map};
            end
        end
        
        function [term_records, cov_records] = write_niftis_and_render_images(obj, target_records, term_results, covariance_results, kriging_directory)
            
            % Writes nifti files for the kriging results and gathers all
            % output in a record array with the following fields:
            %   
            %   term: name of domain expression term
            %   prediction: volume (only scalars)
            %   variance: volume (only scalars)
            %   threshold: index of threshold or null
            %   mask: volume (only scalars) or null
            %   target: volume
            %
            
            term_records = obj.define_term_records();
            
            image_directory = fullfile(obj.directory, 'images');
            
            [dirstatus, dirmsg] = mkdir(image_directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            renderer = geospm.volumes.ColourMapping();
            renderer.colour_map = hdng.colour_mapping.GenericColourMap.monochrome();
            renderer.colour_map_mode = hdng.colour_mapping.ColourMap.VOLUME_MODE;
            
            context = geospm.volumes.RenderContext();
            context.render_settings = geospm.volumes.RenderSettings();
            context.output_directory = image_directory;
            
            N_thresholds = numel(obj.thresholds);
            
            for j=1:N_thresholds
                
                threshold_directory = fullfile(obj.directory, sprintf('th_%d', j));
                hdng.utilities.rmdir(threshold_directory, true, false);
            end
            
            N_terms = obj.domain_expression.N_terms;
            
            for i=1:N_terms
                
                term_name = obj.domain_expression.term_names{i};
                
                term = term_results.(term_name);
                
                pred_path = fullfile(kriging_directory, [term_name '_pred.nii']);
                var_path = fullfile(kriging_directory, [term_name '_var.nii']);
                
                geospm.utilities.write_nifti(cast(term.prediction, 'single'), pred_path, spm_type('float32'));
                geospm.utilities.write_nifti(cast(term.variance, 'single'), var_path, spm_type('float32'));
                
                term_name_value = hdng.experiments.Value.from(term_name);
                targets = target_records.select(struct('term', term_name_value));

                if targets.length ~= 1
                    error('Kriging.write_kriging_niftis() can''t match target record or target record missing.');
                end
                
                matched_target_record = targets.unsorted_records{1};
                target_volume = matched_target_record('target');
                
                pred_volume = hdng.experiments.VolumeReference();
                pred_volume.scalars = hdng.experiments.ImageReference(obj.canonical_path(pred_path), obj.source_ref);

                var_volume = hdng.experiments.VolumeReference();
                var_volume.scalars = hdng.experiments.ImageReference(obj.canonical_path(var_path), obj.source_ref);
                
                context.output_directory = image_directory;

                [dirstatus, dirmsg] = mkdir(context.output_directory);
                if dirstatus ~= 1; error(dirmsg); end

                obj.render_image(pred_volume, context, renderer);
                obj.render_image(var_volume, context, renderer);
                
                pred_volume = hdng.experiments.Value.from(pred_volume);
                var_volume = hdng.experiments.Value.from(var_volume);
                
                record = hdng.utilities.Dictionary();

                record('threshold') = hdng.experiments.Value.empty_with_label('Not applicable');
                record('term') = term_name_value;
                record('prediction') = pred_volume;
                record('variance') = var_volume;
                record('mask') = hdng.experiments.Value.empty_with_label('Not applicable');
                %record('map') = map_volume;
                record('target') = hdng.experiments.Value.empty_with_label('Not applicable');
                record('result') = hdng.experiments.Value.empty_with_label('Not applicable');
                
                term_records.include_record(record);
                
                test_maps = obj.build_test_maps_for_term(context, renderer, kriging_directory, term_name, term);
                
                for j=1:N_thresholds
                    
                    threshold = obj.thresholds{j};
                    threshold_string = sprintf('th_%d', j);
                    threshold_directory = fullfile(obj.directory, threshold_string);
                    
                    [dirstatus, dirmsg] = mkdir(threshold_directory);
                    if dirstatus ~= 1; error(dirmsg); end
                    
                    if ~isKey(test_maps, threshold.distribution)
                        error('Kriging.write_kriging_niftis(): No statistic for test distribution ''%s''.', threshold.distribution);
                    end
                    
                    threshold_file = fullfile(...
                        threshold_directory, 'threshold.txt');
                
                    hdng.utilities.save_text(...
                        [threshold.description newline], ...
                        threshold_file);
                    
                    test_map = test_maps(threshold.distribution);
                    
                    term.mask{j} = threshold.test(test_map{2});
                    
                    mask_path = fullfile(threshold_directory, [term_name '_mask.nii']);
                    geospm.utilities.write_nifti(cast(term.mask{j}, 'uint8'), mask_path, spm_type('uint8'));

                    mask_volume = hdng.experiments.VolumeReference();
                    mask_volume.scalars = hdng.experiments.ImageReference(obj.canonical_path(mask_path), obj.source_ref);

                    context.output_directory = fullfile(image_directory, threshold_string);

                    [dirstatus, dirmsg] = mkdir(context.output_directory);
                    if dirstatus ~= 1; error(dirmsg); end
                    
                    obj.render_image(mask_volume, context, renderer);
                    
                    mask_volume = hdng.experiments.Value.from(mask_volume);
                    
                    record = hdng.utilities.Dictionary();
                    
                    record('threshold') = hdng.experiments.Value.from(j, threshold.description);
                    record('term') = term_name_value;
                    record('prediction') = pred_volume;
                    record('variance') = var_volume;
                    record('mask') = mask_volume;
                    %record('map') = map_volume;
                    record('target') = target_volume;
                    record('result') = mask_volume;
                    
                    term_records.include_record(record);
                    
                    %fprintf('===== write_kriging_niftis() for term %s:\n    image-path: %s\n    scalars-path: %s', name_value.content, target.content.image.path, mask_volume.content.image.path);
                end
            end
            
            cov_records = hdng.experiments.RecordArray();
            
            cov_records.define_attribute('name').description = 'Name';
            cov_records.define_attribute('covariance').description = 'Covariance';
            
            cov_records.define_partitioning_attachment({
                struct('identifier', 'name', 'category', 'partitioning', 'view_mode', 'select'), ...
                struct('identifier', 'covariance', 'category', 'content')});
            
            cov_names = fieldnames(covariance_results);
            N_covariances = numel(cov_names);

            for i=1:N_covariances
                
                term_name = cov_names{i};
                covariance = covariance_results.(term_name);
                
                cov_path = fullfile(kriging_directory, [term_name '_cov.nii']);
                geospm.utilities.write_nifti(cast(covariance, 'single'), cov_path, spm_type('float32'));
                
                term_name_value = hdng.experiments.Value.from(term_name);
                
                record = hdng.utilities.Dictionary();
                record('name') = term_name_value;
                
                cov_volume = hdng.experiments.VolumeReference();
                cov_volume.scalars = hdng.experiments.ImageReference(obj.canonical_path(cov_path), obj.source_ref);
                
                context.output_directory = image_directory;

                [dirstatus, dirmsg] = mkdir(context.output_directory);
                if dirstatus ~= 1; error(dirmsg); end
                
                obj.render_image(cov_volume, context, renderer);
                
                cov_volume = hdng.experiments.Value.from(cov_volume);
                
                record('covariance') = cov_volume;
                
                cov_records.include_record(record);
            end
        end
        
        function result = build_volume_reference(obj, scalars_path, image_path, slice_names)
            
            if ~exist('slice_names', 'var')
                slice_names = [];
            end
            
            scalars_path = obj.canonical_path(scalars_path);
            image_path = obj.canonical_path(image_path);
            
            result = hdng.experiments.VolumeReference();
            result.scalars = hdng.experiments.ImageReference(scalars_path, obj.source_ref);
            result.image = hdng.experiments.ImageReference(image_path, obj.source_ref);
            result.slice_names = slice_names;
            
        end
        
        function image_path = render_image(obj, volume, context, renderer)
            

            volume_set = geospm.volumes.VolumeSet();
            volume_set.file_paths = {obj.absolute_path(volume.scalars.path)};

            context.image_volumes = volume_set;
            context.alpha_volumes = [];

            image_paths = renderer.render(context);
            image_paths = image_paths{1};
            image_path = obj.canonical_path(image_paths{1});
            volume.image = hdng.experiments.ImageReference(image_path, obj.source_ref);
        end
        
        function [term_records, covariance_records, duration] = ...
                build_niftis_and_render_images(obj, target_records, kriging_directory, result_name)
            
            [term_results, covariance_results, duration] = ...
                obj.gather_kriging_results(kriging_directory, result_name);
            
            [term_records, covariance_records] = ...
                obj.write_niftis_and_render_images(target_records, term_results, covariance_results, kriging_directory);
        end
        
        
    end
    
    
    methods (Static, Access=public)
    end
    
end
