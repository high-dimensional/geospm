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

classdef SPMRegression < geospm.validation.SpatialExperiment
    %SPMRegression Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        thresholds
        
        smoothing_levels
        smoothing_levels_p_value
        smoothing_levels_as_z_dimension
        
        smoothing_method
        
        observation_transform
        
        render_images
        trace_thresholds

        apply_density_mask
        density_mask_factor
        
        add_intercept
        render_intercept_separately
        
        analysis
        
        regression_stage
        
        apply_target_heuristic
    end
    
    properties (GetAccess=public, SetAccess=private)
        contrasts
        contrast_groups
        contrasts_per_threshold
    end
    
    properties (Transient, Dependent)
        volume_slice_names
        N_composite_contrasts
    end
    
    methods
        
        function obj = SPMRegression(seed, ...
                directory, ...
                run_mode, ...
                nifti_mode, ...
                model_and_metadata, ...
                sampling_strategy, ...
                N_samples, ...
                domain_expression, ...
                smoothing_levels, ...
                smoothing_levels_p_value, ...
                smoothing_levels_as_z_dimension, ...
                smoothing_method, ...
                thresholds, ...
                observation_transform, ...
                add_intercept )
            
            obj = obj@geospm.validation.SpatialExperiment(seed, directory, ...
                    run_mode, nifti_mode, ...
                    model_and_metadata, sampling_strategy, N_samples, ...
                    domain_expression);
            
            obj.thresholds = thresholds;
            obj.observation_transform = observation_transform;
            
            obj.contrasts = {};
            obj.contrast_groups = {};
            obj.contrasts_per_threshold = {};
            
            obj.render_images = true;
            obj.trace_thresholds = false;
            obj.apply_density_mask = false;
            obj.density_mask_factor = [];
            
            obj.add_intercept = add_intercept;
            obj.render_intercept_separately = true;
            
            obj.smoothing_levels = smoothing_levels;
            
            if smoothing_levels_p_value <= 0.0 || smoothing_levels_p_value >= 1.0
                error('geospm.validation.SPMRegression.ctor(): ''smoothing_levels_p_value'' is not in (0, 1.0): %f', options.smoothing_levels_p_value);
            end
            
            obj.smoothing_levels_p_value = smoothing_levels_p_value;
            obj.smoothing_levels_as_z_dimension = smoothing_levels_as_z_dimension;
            
            obj.smoothing_method = smoothing_method;
            
            obj.analysis = [];
            obj.regression_stage = [];
            
            obj.apply_target_heuristic = true;
            
            attribute = obj.result_attributes.define('spm_output_directory');
            attribute.description = 'SPM Output Directory';
            
            attribute = obj.result_attributes.define('threshold_directories');
            attribute.description = 'Threshold Directories';
            
            attribute = obj.result_attributes.define('model_density');
            attribute.description = 'Model Density';
            
            if obj.add_intercept
                intercept_term = geospm.models.DomainTerm({}, @() 1, 'intercept');
                terms = [obj.domain_expression.terms, {intercept_term}];
                obj.spatial_data_expression = geospm.models.DomainExpression(terms);
            end
        end
        
        function results = get.volume_slice_names(obj)
            
            results = {};
            
            for i=1:numel(obj.smoothing_levels)
                results{end + 1} = sprintf('Smoothing %g@%g', obj.smoothing_levels(i), obj.smoothing_levels_p_value);  %#ok<AGROW>
            end
        end
        
        function N = get.N_composite_contrasts(obj)
            
            N = 0;
            
            for i=1:numel(obj.composite_contrasts_per_threshold)
                tmp_contrasts = obj.composite_contrasts_per_threshold(i);
                N = N + size(tmp_contrasts, 1);
            end
        end
        
        
        function results = format_smoothing_levels(obj)
            
            results = {};
            
            for i=1:numel(obj.smoothing_levels)
                results{end + 1} = num2str(obj.smoothing_levels(i), '%.3f'); %#ok<AGROW>
            end
        end
        
        function compute_spatial_data(obj)
            compute_spatial_data@geospm.validation.SpatialExperiment(obj);
        end
        
        function targets = compute_targets(obj)
            
            targets = compute_targets@geospm.validation.SpatialExperiment(obj);
            
            if ~obj.apply_target_heuristic
                return
            end
            
            %This is a heuristic that works for now (in the noise range up
            %to 36%):
            %First, we record all single-variable terms and form the union
            %of all multi-variable terms.
            %Second, we subtract the union of all multi-variable terms from
            %all single-variable terms.
            
            count = [];
            
            adjust_targets = {};
            
            for i=1:obj.domain_expression.N_terms
                term = obj.domain_expression.terms{i};
                
                if numel(term.variables) > 1
                    
                    adjust_targets = [adjust_targets, {i}]; %#ok<AGROW>
                else
                    
                    if isempty(count)
                        count = targets{i};
                    else
                        count = count + targets{i};
                    end
                end
            end
            
            single_effects = count == 1;
            
            if ~isempty(single_effects) && ~isempty(adjust_targets)
                
                interaction_effects = ~single_effects;
                
                for i=1:numel(adjust_targets)
                    index = adjust_targets{i};
                    targets{index} = targets{index} & interaction_effects;
                end
            end
        end
        
        function [analysis, arguments] = setup_analysis(obj)

            analysis = geospm.SpatialAnalysis();

            analysis.define_requirement('directory');
            analysis.define_requirement('spatial_data');
            analysis.define_requirement('spatial_index');
            
            analysis.define_requirement('observation_transform');
            
            analysis.define_requirement('smoothing_levels');
            analysis.define_requirement('smoothing_levels_p_value');
            analysis.define_requirement('smoothing_levels_as_z_dimension');
            
            analysis.define_requirement('smoothing_method');
            
            analysis.define_requirement('regression_run_computation');
            analysis.define_requirement('regression_spmmat_path');
            
            analysis.define_requirement('regression_add_intercept');
            analysis.define_requirement('contrasts');
            
            analysis.define_requirement('thresholds');
            analysis.define_requirement('threshold_contrasts');
            
            analysis.define_requirement('regression_probes');
            
            analysis.define_product('sample_density');
            analysis.define_product('selection');
            
            if strcmp(obj.run_mode, geospm.validation.SpatialExperiment.REGULAR_MODE) || ...
                 strcmp(obj.run_mode, geospm.validation.SpatialExperiment.RESUME_MODE)
                analysis.define_product('threshold_directories');
                analysis.define_product('image_records');
                analysis.define_product('beta_records');
                analysis.define_product('density_image');
            end
            
            analysis.define_product('spm_job_list');
            analysis.define_product('spm_output_directory');
            analysis.define_product('regression_probe_file');
            
            grid = geospm.Grid();
            grid.span_frame([1, 1, 1], [obj.model.spatial_resolution + 1 1], obj.model.spatial_resolution);

            grid_stage = geospm.stages.GridTransform(analysis, 'grid', grid, 'assigned_grid', obj.model_grid, 'data_product', 'untransformed_grid_data', 'spatial_index_product', 'untransformed_grid_index');
            
            geospm.stages.ObservationTransform(analysis, ...
                'data_requirement', 'untransformed_grid_data', ...
                'spatial_index_requirement', 'untransformed_grid_index', ...
                'data_product', 'grid_data', ...
                'spatial_index_product', 'grid_spatial_index', ...
                'transform_requirement', 'observation_transform');
            
            geospm.stages.SPMSpatialSmoothing(analysis);
            
            obj.regression_stage = geospm.stages.SPMDistanceRegression(analysis);
            obj.regression_stage.apply_density_mask = obj.apply_density_mask;
            obj.regression_stage.write_applied_mask = true;
            
            if ~isempty(obj.density_mask_factor)
                obj.regression_stage.density_mask_factor = obj.density_mask_factor;
            end

            if obj.apply_geographic_mask
                obj.regression_stage.optional_mask = obj.compute_geographic_mask();
            end
            
            if obj.smoothing_levels_as_z_dimension
                if strcmp(obj.run_mode, geospm.validation.SpatialExperiment.REGULAR_MODE) || ...
                     strcmp(obj.run_mode, geospm.validation.SpatialExperiment.RESUME_MODE)
                    
                    geospm.stages.SPMApplyThresholds(analysis, [], 'output_prefix', 'th_');
                    
                    render_image_stage = geospm.stages.SPMRenderImages(analysis);
                    render_image_stage.render_intercept_separately = obj.render_intercept_separately;
                    render_image_stage.volume_renderer.colour_map = obj.colour_map;
                    render_image_stage.volume_renderer.colour_map_mode = obj.colour_map_mode;
                    render_image_stage.ignore_crs = true;
                    render_image_stage.centre_pixels = obj.centre_pixels;
                    
                    if ~obj.render_images
                        render_image_stage.gather_volumes_only = true;
                    end
    
                    if obj.add_georeference_to_images
                        render_image_stage_2 = geospm.stages.SPMRenderImages(analysis, 'geo_');
                        render_image_stage_2.render_intercept_separately = obj.render_intercept_separately;
                        render_image_stage_2.volume_renderer.colour_map = obj.colour_map;
                        render_image_stage_2.volume_renderer.colour_map_mode = obj.colour_map_mode;
                        render_image_stage_2.ignore_crs = false;
                        render_image_stage_2.centre_pixels = obj.centre_pixels;
        
                        if ~obj.render_images
                            render_image_stage_2.gather_volumes_only = true;
                        end
                    end
                    
                    if obj.trace_thresholds
                        threshold_stage = geospm.stages.SPMTraceThresholdRegions(analysis);
                        threshold_stage.centre_pixels = obj.centre_pixels;
                    end
                end
            else
                if strcmp(obj.run_mode, geospm.validation.SpatialExperiment.REGULAR_MODE) || ...
                     strcmp(obj.run_mode, geospm.validation.SpatialExperiment.RESUME_MODE)
                    
                    geospm.stages.SPMApplyThresholds(analysis, [], 'output_prefix', 'th_');
                end
            end
            
            arguments = struct();
            arguments.directory = obj.directory;
            arguments.spatial_data = obj.spatial_data;
            arguments.spatial_index = obj.spatial_index;
            
            arguments.observation_transform = obj.observation_transform;
            
            arguments.smoothing_levels = obj.smoothing_levels;
            arguments.smoothing_levels_p_value = obj.smoothing_levels_p_value;
            arguments.smoothing_levels_as_z_dimension = obj.smoothing_levels_as_z_dimension;
            
            arguments.smoothing_method = obj.smoothing_method;
            
            arguments.regression_probes = [];
            
            if obj.add_probes
                [grid_probe_data, ~] = grid_stage.grid.grid_data(obj.probe_data);
                arguments.regression_probes = grid_probe_data;
            end
            
            arguments.regression_add_intercept = false;
            arguments.contrasts = geospm.utilities.spm_jobs_from_domain_contrast_groups(obj.contrast_groups);
            
            % For SPMApplyThresholds
            arguments.thresholds = obj.thresholds;
            arguments.threshold_contrasts = obj.contrasts_per_threshold;
            
            arguments.regression_run_computation = ...
                ~strcmp(obj.run_mode, geospm.validation.SpatialExperiment.DEFERRED_MODE);
            
            arguments.regression_spmmat_path = '';
            
            if strcmp(obj.run_mode, geospm.validation.SpatialExperiment.RESUME_MODE)
                arguments.regression_spmmat_path = fullfile(obj.directory, 'spm_output', 'SPM.mat');
            end
        end
        
        function save_density(obj, density_scalars, density_image_path)
             
            density_scalars_path = fullfile(obj.directory, 'density.nii');
            
            if ~strcmp(obj.run_mode, geospm.validation.SpatialExperiment.RESUME_MODE)
                geospm.utilities.write_nifti(density_scalars, density_scalars_path);
            end
            
            density = obj.build_volume_reference(density_scalars_path, density_image_path, obj.volume_slice_names);
            obj.results('model_density') = hdng.experiments.Value.from(density);
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
        
        function threshold_directories = define_threshold_directories(obj)

            threshold_directories = cell(numel(obj.thresholds), 1);

            for index=1:numel(obj.thresholds)
                threshold = obj.thresholds{index};
                threshold_directory = geospm.stages.SPMApplyThresholds.directory_name_for_threshold(index, threshold);
                threshold_directories{index} = fullfile(obj.directory, threshold_directory);
            end
        end
        
        function results = load_analysis_results(obj)
            
            results = struct();
            
            results.threshold_directories = obj.define_threshold_directories();
            results.spm_output_directory = fullfile(obj.directory, obj.regression_stage.output_directory_name);
            
            %{
            spm_job_list
            sample_density
            density_image
            regression_probe_file
            image_records
            %}
            
        end
        
        function run(obj)

            run@geospm.validation.SpatialExperiment(obj);
            
            if strcmp(obj.run_mode, geospm.validation.SpatialExperiment.RESUME_MODE)
                obj.delete_existing_threshold_directories();
            end
            
            %obj.spatial_data.show_variogram();
            
            %Write targets
            target_records = obj.write_targets(true, false);
            
            if obj.add_intercept
                intercept_target = hdng.utilities.Dictionary();
                intercept_target('term') = hdng.experiments.Value.from('intercept');
                intercept_target('target') = hdng.experiments.Value.empty_with_label('no target');

                target_records.include_record(intercept_target);
            end
            
            %Create contrasts
            
            [obj.contrasts, obj.contrasts_per_threshold] = ...
                geospm.utilities.define_simple_contrasts(...
                    obj.thresholds, obj.spatial_data_expression.term_names);
                
            [obj.contrasts, obj.contrast_groups] = ...
                geospm.utilities.order_domain_contrasts(...
                obj.contrasts, {'T', 'F'});
            
            contrasts_per_threshold_tmp = obj.contrasts_per_threshold;
            
            for index=1:numel(contrasts_per_threshold_tmp)
                threshold_contrasts = contrasts_per_threshold_tmp{index};
                threshold_contrast_indices = zeros(size(threshold_contrasts));
                
                for c=1:numel(threshold_contrasts)
                    contrast = threshold_contrasts{c};
                    threshold_contrast_indices(c) = contrast.order;
                end
                

                threshold_contrast_indices = sortrows(threshold_contrast_indices, 1);

                contrasts_per_threshold_tmp{index} = threshold_contrast_indices;
            end

            obj.contrasts_per_threshold = contrasts_per_threshold_tmp;
            

            %Setup analysis
            [obj.analysis, arguments] = obj.setup_analysis();

            
            if ~strcmp(obj.run_mode, geospm.validation.SpatialExperiment.LOAD_MODE)
                %Run analysis
                results = obj.analysis.run(arguments);

                if strcmp(obj.run_mode, geospm.validation.SpatialExperiment.DEFERRED_MODE)
                    results.threshold_directories = obj.define_threshold_directories();
                end
            else
                results = obj.load_analysis_results();
            end
            
            spm_output_directory = hdng.experiments.FileReference();
            spm_output_directory.path = obj.canonical_path(results.spm_output_directory);
            spm_output_directory.source_ref = obj.source_ref;
            
            obj.results('spm_output_directory') = hdng.experiments.Value.from(spm_output_directory);
            
            threshold_directories = cell(numel(results.threshold_directories), 1);
            
            for index=1:numel(results.threshold_directories)
                threshold_directory = hdng.experiments.FileReference();
                threshold_directory.path = obj.canonical_path(results.threshold_directories{index});
                threshold_directory.source_ref = obj.source_ref;
                threshold_directories{index} = threshold_directory;
            end
            
            obj.results('threshold_directories') = hdng.experiments.Value.from(threshold_directories, 'Threshold Directories');
            
            if ~strcmp(obj.run_mode, geospm.validation.SpatialExperiment.DEFERRED_MODE)

                if ~strcmp(obj.run_mode, geospm.validation.SpatialExperiment.LOAD_MODE)
                    spm_job_list = results.spm_job_list;

                    duration = seconds(spm_job_list.stopped_at - spm_job_list.started_at);
                    obj.results('duration') = hdng.experiments.Value.from(duration);

                    %Recover SPM session
                    spm_session = geospm.spm.SPMSession(fullfile(results.spm_output_directory, 'SPM.mat'));

                    %Save sample density
                    obj.save_density(results.sample_density, results.density_image);

                    if obj.add_probes
                        %Summarise probes
                        obj.summarise_probes(results.regression_probe_file);
                    end
                    
                    term_records = obj.build_term_records(spm_session, results.threshold_directories, results.image_records, target_records);            

                    obj.results('terms') = hdng.experiments.Value.from(term_records);
                else
                    obj.reuse_results();
                end
                
                obj.nifti_files = [obj.scan_for_nifti_files(obj.directory); ...
                                   obj.scan_for_nifti_files(results.spm_output_directory); ...
                                   obj.scan_for_nifti_files([obj.directory filesep 'targets'])];

                for index=1:numel(results.threshold_directories)
                    threshold_directory = results.threshold_directories{index};

                    obj.nifti_files = [obj.nifti_files; obj.scan_for_nifti_files(threshold_directory)];
                end
            end
        end
        
        function cleanup(obj)
            
            if strcmp(obj.run_mode, geospm.validation.SpatialExperiment.REGULAR_MODE) || ...
                  strcmp(obj.run_mode, geospm.validation.SpatialExperiment.RESUME_MODE)
                
                spm_output_directory = obj.results('spm_output_directory').content.resolve_path_relative_to(obj.canonical_base_path);
                spm_session = geospm.spm.SPMSession(fullfile(spm_output_directory, 'SPM.mat'));
                
                %Clean up ResI_ images if they still exist
                residuals_file_pattern = '^(ResI_[0-9]+\.nii)$';
                [file_paths, ~] = hdng.utilities.scan_files(spm_session.directory, residuals_file_pattern);
                
                if ~isempty(file_paths)
                    hdng.utilities.delete(false, file_paths{:});
                end
            end
            
            cleanup@geospm.validation.SpatialExperiment(obj);
        end
        
        function result = unpack_volume_value(~, volume_value)
            
            result = struct();
            
            if strcmp(volume_value.type_identifier, 'builtin.dict' )
                volume_dictionary = volume_value.content;

                result.scalars = volume_dictionary('volumes').content;
                result.images = volume_dictionary('images').content;
                
            elseif strcmp(volume_value.type_identifier, 'builtin.null' )
                
                result.scalars = [];
                result.images = [];
            else
                error('SPMRegression.unpack_volume_value(): Expected ''builtin.dict'' but have ''%s''.', volume_value.type_identifier);
            end
        end
        
        function result = build_volume_reference(obj, scalars_path, image_path, slice_names)
            
            if ~exist('slice_names', 'var')
                slice_names = [];
            end
            
            if ~isempty(scalars_path)
                scalars_path = obj.canonical_path(scalars_path);
            end
            
            if ~isempty(image_path)
                image_path = obj.canonical_path(image_path);
            end
            
            result = hdng.experiments.build_volume_reference(scalars_path, image_path, slice_names, obj.source_ref);
        end
        
        function result = build_slice_shapes(obj, shape_paths, slice_names)
            
            if ~exist('slice_names', 'var')
                slice_names = [];
            end
            
            for i=1:numel(shape_paths)
                shape_paths{i} = obj.canonical_path(shape_paths{i});
            end
            
            span = obj.model_grid.cell_size .* obj.model_grid.resolution;
            
            result = hdng.experiments.build_slice_shapes(...
                obj.model_grid.origin(1:2), span(1:2), ...
                obj.model_grid.resolution(1:2), ...
                shape_paths, slice_names, obj.source_ref);
        end
        
        function result = build_term_records(obj, spm_session, threshold_directories, image_records, target_records)
            
            % Builds a record array with the following fields:
            %
            %   threshold
            %   term
            %   contrast
            %   map
            %   mask
            %   set-level
            %   cluster-level
            %   result
            %   target
            
            %image_records has the fields { statistic, threshold, masks, maps, contrasts }
            
            result = hdng.experiments.RecordArray();
            
            result.define_attribute('threshold').description = 'Threshold';
            result.define_attribute('statistic').description = 'Statistic';
            
            result.define_attribute('threshold_or_statistic').description = 'Threshold or Statistic';
            
            result.define_attribute('term').description = 'Term';

            result.define_attribute('contrast').description = 'Contrast';
            result.define_attribute('map').description = 'Map';

            result.define_attribute('masked_contrast').description = 'Masked Contrast';
            result.define_attribute('masked_map').description = 'Masked Map';

            result.define_attribute('mask').description = 'Mask';
            result.define_attribute('mask_traces').description = 'Mask Traces';
            
            result.define_attribute('set-level').description = 'Set-Level Statistics';
            result.define_attribute('cluster-level').description = 'Cluster-Level Statistics';
            result.define_attribute('peak-level').description = 'Peak-Level Statistics';
            
            result.define_attribute('result').description = 'Result';
            result.define_attribute('target').description = 'Target';

            result.define_attribute('residuals').description = 'Residuals';
            
            %result.define_attribute('beta').description = 'Beta';
            
            result.define_partitioning_attachment({
                struct('identifier', 'threshold_or_statistic', 'category', 'partitioning', 'view_mode', 'select'), ...
                struct('identifier', 'term', 'category', 'partitioning'), ...
                struct('identifier', 'contrast', 'category', 'content'), ...
                struct('identifier', 'map', 'category', 'content'), ...
                struct('identifier', 'masked_contrast', 'category', 'content'), ...
                struct('identifier', 'masked_map', 'category', 'content'), ...
                struct('identifier', 'mask', 'category', 'content'), ...
                struct('identifier', 'mask_traces', 'category', 'content'), ...
                struct('identifier', 'result', 'category', 'content'), ...
                struct('identifier', 'target', 'category', 'content'), ...
                struct('identifier', 'set-level', 'category', 'content'), ...
                struct('identifier', 'cluster-level', 'category', 'content'), ...
                struct('identifier', 'peak-level', 'category', 'content'), ...
                struct('identifier', 'residuals', 'category', 'content')});
            
            target_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            for index=1:numel(obj.contrasts)
                
                contrast = obj.contrasts{index};
                
                if contrast.attachments.term_index == 0
                    continue
                end
                
                term_name = contrast.name;
                
                targets = target_records.select(struct('term', hdng.experiments.Value.from(term_name)));

                if targets.length ~= 1
                    error('SPMRegression.run() can''t match target record or target record missing.');
                end

                matched_target_record = targets.unsorted_records{1};
                target = matched_target_record('target');
                target_map(term_name) = target;
            end

            %residuals = obj.build_volume_reference(spm_contrasts.scalars{c_index}, spm, obj.volume_slice_names);
            
            records = image_records.unsorted_records;
            
            for index=1:numel(records)
                
                record = records{index};
                
                threshold_value = record('threshold');
                
                spm_contrasts = obj.unpack_volume_value(record('contrasts'));
                spm_maps = obj.unpack_volume_value(record('maps'));
                spm_masked_contrasts = obj.unpack_volume_value(record('masked_contrasts'));
                spm_masked_maps = obj.unpack_volume_value(record('masked_maps'));
                spm_masks = obj.unpack_volume_value(record('masks'));
                spm_mask_traces = obj.unpack_volume_value(record('mask_traces'));
                mask_summaries = record('mask_summaries').content;
                
                is_unmasked = strcmp(threshold_value.type_identifier, 'builtin.null' );
                
                if is_unmasked
                    
                    for c_index=1:numel(spm_contrasts)
                        
                        contrast = obj.get_contrast_for_image_file(spm_contrasts.images{c_index});
                        
                        if strcmp(contrast.name, 'intercept')
                            continue
                        end

                        term_name = contrast.name;
                        term_value_args = {term_name};
                        
                        if isfield(obj.spatial_data.attachments, 'variable_labels') && isfield(obj.spatial_data.attachments.variable_labels, term_name)
                            term_value_args{end + 1} = obj.spatial_data.attachments.variable_labels.(term_name); %#ok<AGROW> 
                        end

                        target = target_map(term_name);
                        new_record = hdng.utilities.Dictionary();
                        new_record('statistic') = hdng.experiments.Value.from(contrast.statistic);
                        new_record('threshold') = hdng.experiments.Value.empty_with_label('Not Applicable');
                        new_record('threshold_or_statistic') = new_record('statistic');
                        new_record('term') = hdng.experiments.Value.from(term_value_args{:});

                        if obj.render_images
                            contrast_image_path = spm_contrasts.images{c_index};
                            map_image_path = spm_maps.images{c_index};
                        else
                            contrast_image_path = [];
                            map_image_path = [];
                        end
                        
                        contrast = obj.build_volume_reference(spm_contrasts.scalars{c_index}, contrast_image_path, obj.volume_slice_names);
                        map = obj.build_volume_reference(spm_maps.scalars{c_index}, map_image_path, obj.volume_slice_names);

                        new_record('contrast') = hdng.experiments.Value.from(contrast);
                        new_record('map') = hdng.experiments.Value.from(map);
                        new_record('mask') = hdng.experiments.Value.empty_with_label('Not Applicable');
                        new_record('mask_traces') = hdng.experiments.Value.empty_with_label('Not Applicable');
                        new_record('mask_summaries') = hdng.experiments.Value.empty_with_label('Not Applicable');
                        new_record('result') = new_record('mask');
                        new_record('target') = target;
                        
                        new_record('set-level') = hdng.experiments.Value.empty_with_label('Not Applicable');
                        new_record('cluster-level') = hdng.experiments.Value.empty_with_label('Not Applicable');
                        new_record('peak-level') = hdng.experiments.Value.empty_with_label('Not Applicable');

                        result.include_record(new_record);
                    end
                end
                
                threshold_index = threshold_value.content;
                threshold = obj.thresholds{threshold_index};
                threshold_directory = threshold_directories{threshold_index};
                threshold_index_string = num2str(threshold_index, '%d');
                threshold_string = ['th_' threshold_index_string];
                
                threshold_value = hdng.experiments.Value.from(threshold_value.content, threshold.description);
                
                %statistic = record('statistic');

                set_match_result = spm_session.match_statistic_set_csv_files('', threshold_directory);

                if ~set_match_result.did_match_all_files
                    error(['SPMRegression.run(): Couldn''t locate all set csv files associated with threshold ''' threshold_string '''.']);
                end

                cluster_match_result = spm_session.match_statistic_cluster_csv_files('', threshold_directory);

                if ~cluster_match_result.did_match_all_files
                    error(['SPMRegression.run(): Couldn''t locate all cluster csv files associated with threshold ''' threshold_string '''.']);
                end

                peak_match_result = spm_session.match_statistic_peak_csv_files('', threshold_directory);

                if ~peak_match_result.did_match_all_files
                    error(['SPMRegression.run(): Couldn''t locate all peak csv files associated with threshold ''' threshold_string '''.']);
                end
                
                threshold_contrasts = obj.contrasts_per_threshold{threshold_index};

                is_consistent = (numel(threshold.tails) == 2) == ...
                                (numel(threshold_contrasts) == 2 * numel(spm_contrasts.scalars));
                
                if ~is_consistent
                    error('SPMRegression.build_term_records(): Expected half the number of images for 2-tailed threshold.');
                end
                
                for c_index=1:numel(spm_contrasts.scalars)
                    
                    threshold_contrast = obj.contrasts{threshold_contrasts(c_index, 1)};
                    term_name = threshold_contrast.name;
                    term_value_args = {term_name};
                    
                    if isfield(obj.spatial_data.attachments, 'variable_labels') && isfield(obj.spatial_data.attachments.variable_labels, term_name)
                        term_value_args{end + 1} = obj.spatial_data.attachments.variable_labels.(term_name); %#ok<AGROW> 
                    end

                    target = target_map(term_name);
                    
                    new_record = hdng.utilities.Dictionary();
                    new_record('statistic') = hdng.experiments.Value.empty_with_label('Not Applicable');
                    new_record('threshold') = threshold_value;
                    new_record('threshold_or_statistic') = threshold_value;
                    new_record('term') = hdng.experiments.Value.from(term_value_args{:});
                    
                    if obj.render_images
                        contrast_image_path = spm_contrasts.images{c_index};
                        map_image_path = spm_maps.images{c_index};
                        masked_contrast_image_path = spm_masked_contrasts.images{c_index};
                        masked_map_image_path = spm_masked_maps.images{c_index};
                        mask_image_path = spm_masks.images{c_index};
                        mask_trace_layer_paths = spm_mask_traces.images{c_index};
                    else
                        contrast_image_path = [];
                        map_image_path = [];
                        masked_contrast_image_path = [];
                        masked_map_image_path = [];
                        mask_image_path = [];
                        mask_trace_layer_paths = [];
                    end
                    
                    contrast = obj.build_volume_reference(spm_contrasts.scalars{c_index}, contrast_image_path, obj.volume_slice_names);
                    map = obj.build_volume_reference(spm_maps.scalars{c_index}, map_image_path, obj.volume_slice_names);
                    masked_contrast = obj.build_volume_reference(spm_masked_contrasts.scalars{c_index}, masked_contrast_image_path, obj.volume_slice_names);
                    masked_map = obj.build_volume_reference(spm_masked_maps.scalars{c_index}, masked_map_image_path, obj.volume_slice_names);
                    mask = obj.build_volume_reference(spm_masks.scalars{c_index}, mask_image_path, obj.volume_slice_names);
                    slice_shapes = obj.build_slice_shapes(mask_trace_layer_paths, obj.volume_slice_names);
                    
                    contrast_mask_summaries = mask_summaries{c_index};
                    
                    summary_name = contrast_mask_summaries{1};
                    summary_name = regexprep(summary_name, '\s*\[contrast\]\s*$', '');

                    if ~strcmp(summary_name, term_name)
                        contrast_mask_summaries = hdng.experiments.Value.empty_with_label('Not Available');
                    else
                        contrast_mask_summaries = hdng.experiments.Value.from(contrast_mask_summaries(2:end));
                    end
                    
                    new_record('contrast') = hdng.experiments.Value.from(contrast);
                    new_record('map') = hdng.experiments.Value.from(map);
                    new_record('masked_contrast') = hdng.experiments.Value.from(masked_contrast);
                    new_record('masked_map') = hdng.experiments.Value.from(masked_map);
                    new_record('mask') = hdng.experiments.Value.from(mask);
                    new_record('mask_traces') = hdng.experiments.Value.from(slice_shapes);
                    new_record('mask_summaries') = contrast_mask_summaries;
                    new_record('result') = new_record('mask');
                    new_record('target') = target;
                    
                    if ~isempty(set_match_result.matched_files)
                        set_level_path = hdng.experiments.FileReference();
                        set_level_path.path = obj.canonical_path(set_match_result.matched_files{c_index});
                        set_level_path.source_ref = obj.source_ref;
                        new_record('set-level') = hdng.experiments.Value.from(set_level_path);
                    else
                        new_record('set-level') = hdng.experiments.Value.empty_with_label('Not Applicable');
                    end
                    
                    if ~isempty(cluster_match_result.matched_files)
                        cluster_level_path = hdng.experiments.FileReference();
                        cluster_level_path.path = obj.canonical_path(cluster_match_result.matched_files{c_index});
                        cluster_level_path.source_ref = obj.source_ref;
                        new_record('cluster-level') = hdng.experiments.Value.from(cluster_level_path);
                    else
                        new_record('cluster-level') = hdng.experiments.Value.empty_with_label('Not Applicable');
                    end
                    
                    if ~isempty(peak_match_result.matched_files)
                        peak_level_path = hdng.experiments.FileReference();
                        peak_level_path.path = obj.canonical_path(peak_match_result.matched_files{c_index});
                        peak_level_path.source_ref = obj.source_ref;
                        new_record('peak-level') = hdng.experiments.Value.from(peak_level_path);
                    else
                        new_record('peak-level') = hdng.experiments.Value.empty_with_label('Not Applicable');
                    end
                    
                    result.include_record(new_record);
                end
            end
        end
        
        function result = gather_nifti_files_from_term_records(obj, term_records)
            
            result = containers.Map('KeyType', 'char', 'ValueType', 'char');
            
            records = term_records.unsorted_records;
            
            for index=1:numel(records)
                record = records{index};
                
                volumes = { ...
                    record('beta'), ...
                    record('contrast'), ...
                    record('map'), ...
                    record('target'), ...
                    record('mask') };
                
                for v_index=1:numel(volumes)
                    
                    volume = volumes{v_index}.content;
                    
                    if isempty(volume) || isempty(volume.scalars)
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
        
        function contrast = get_contrast_for_image_file(obj, image_file)

            contrast = {};
            [~, file_name, ~] = fileparts(image_file);
            tokens = regexp(file_name, '^con_([0-9]+).+', 'tokens');

            if isempty(tokens)
                return
            end

            contrast = obj.contrasts{str2double(tokens{1})};
        end
    end
    
    methods (Static, Access=public)
    end
end
