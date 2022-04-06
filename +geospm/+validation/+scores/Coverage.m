% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2022,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef Coverage < geospm.validation.scores.SPMRegressionScore
    %Coverage 
    %   
    
    properties
        verbose
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Coverage()
            obj = obj@geospm.validation.scores.SPMRegressionScore();
            
            attribute = obj.result_attributes.define('coverage');
            attribute.description = 'Coverage';
            
            obj.verbose = false;
        end
    end
    
    methods (Access=protected)
        
        function compute_for_spm_regression(obj, spm_regression, extra_variables, evaluation, mode)
            
            results = evaluation.results;
            threshold_directories = extra_variables.threshold_directories;
            
            only_if_missing = strcmp(mode, hdng.experiments.Score.COMPUTE_IF_MISSING);
            
            if only_if_missing && results.holds_key('coverage')
                return
            end
            
            coverage_records = obj.compute_coverage(spm_regression, threshold_directories);
            results('coverage') = hdng.experiments.Value.from(coverage_records); %#ok<NASGU>
        end
        
        function result = compute_coverage(obj, spm_regression, threshold_directories)
            
            result = hdng.experiments.RecordArray();
            
            result.define_attribute('threshold').description = 'Threshold';
            result.define_attribute('coverage_map').description = 'Coverage Volume';
            result.define_attribute('coverage.max_slice').description = 'Index of Slice With Maximum Coverage';
            
            result.define_partitioning_attachment({
                struct('identifier', 'threshold', 'category', 'partitioning', 'view_mode', 'select'), ...
                struct('identifier', 'coverage_map', 'category', 'content'), ...
                struct('identifier', 'coverage.max_slice', 'category', 'content')});
            
            domain = spm_regression.model.domain;
            encodings = geospm.models.DomainEncodings();
            encoding_method = encodings.resolve_encoding_method('factorial_with_binary_levels');
            
            factorial_expression = encoding_method(encodings, domain);
            
            factorial_data = factorial_expression.compute_spatial_data(...
                spm_regression.model.domain, spm_regression.model_data);
            
            non_zero_factorial_terms = {};
            
            for i=1:factorial_data.P
                values = factorial_data.observations(:, i);
                is_zero = all(values == 0.0);
                
                if is_zero
                    continue
                end
                
                non_zero_factorial_terms = [non_zero_factorial_terms, factorial_expression.terms(i)]; %#ok<AGROW>
            end
            
            factorial_expression = geospm.models.DomainExpression(non_zero_factorial_terms);
            
            coverage_directory = fullfile(spm_regression.directory, 'coverage');
            hdng.utilities.rmdir(coverage_directory, true, false);
            
            [dirstatus, dirmsg] = mkdir(coverage_directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            model_and_metadata = struct();
            model_and_metadata.model = spm_regression.model;
            model_and_metadata.metadata = spm_regression.model_metadata;
            
            coverage_regression = geospm.validation.experiments.SPMRegression(...
                spm_regression.seed, ...
                coverage_directory, ...
                geospm.validation.SpatialExperiment.REGULAR_MODE, ...
                spm_regression.nifti_mode, ...
                model_and_metadata, ...
                spm_regression.sampling_strategy, ...
                spm_regression.N_samples, ...
                factorial_expression, ...
                spm_regression.smoothing_levels, ...
                spm_regression.smoothing_levels_p_value, ...
                spm_regression.smoothing_method, ...
                spm_regression.thresholds, ...
                geospm.stages.ObservationTransform.IDENTITY, ...
                false );
            
            coverage_regression.render_images = obj.verbose;
            coverage_regression.run();
            
            
            colour_map = hdng.colour_mapping.GenericColourMap.monochrome();
            colour_map_mode = hdng.colour_mapping.ColourMap.SLICE_MODE;
            
            coverage_terms = coverage_regression.results('terms').content;
            
            for threshold_index=1:numel(spm_regression.thresholds)
                
                term_records = coverage_terms.select(struct('threshold_or_statistic', hdng.experiments.Value.from(threshold_index))).unsorted_records;
                
                if numel(term_records) ~= factorial_expression.N_terms
                    error('geospm.validation.scores.Coverage.compute_coverage(): Expected number of coverage term records to match number of factorial expression terms.');
                end
                
                coverage_map = zeros([spm_regression.model.spatial_resolution, numel(spm_regression.smoothing_levels)]);
                
                for r_index=1:numel(term_records)
                    term_record = term_records{r_index};
                    mask_volume = term_record('result').content;
                    mask_path = coverage_regression.absolute_path(mask_volume.scalars.path);
                    V = spm_vol(mask_path);
                    mask_data = spm_read_vols(V);
                    coverage_map = coverage_map + mask_data;
                end
                
                coverage_map = coverage_map == 1.0;
                
                directory = threshold_directories{threshold_index};
                coverage_path = fullfile(directory, 'coverage.nii');
                
                geospm.utilities.write_nifti(cast(coverage_map, 'uint8'), coverage_path, spm_type('uint8'));
                
                slice_voxel_counts = geospm.validation.utilities.sum_voxels_per_slice(coverage_path);
                [~, max_voxel_count_slice] = max(slice_voxel_counts);
                
                image_volume = hdng.images.ImageVolume(coverage_map, sprintf('Coverage volume for threshold %d', threshold_index), fullfile(directory, 'coverage'));
                
                render_results = hdng.images.ImageVolume.batch_render_as_vpng( ...
                    {image_volume}, 8, colour_map, colour_map_mode);
                
                image_file = render_results{1, 4};
                image_file = image_file{1};
                
                coverage_volume = spm_regression.build_volume_reference(coverage_path, image_file, spm_regression.volume_slice_names);
                
                coverage_record = hdng.utilities.Dictionary();
                coverage_record('threshold') = term_records{1}('threshold_or_statistic');
                coverage_record('coverage_map') = hdng.experiments.Value.from(coverage_volume);
                coverage_record('coverage.max_slice') = hdng.experiments.Value.from(cast(max_voxel_count_slice, 'int64') - 1);
                
                result.include_record(coverage_record);
            end
            
            if ~obj.verbose
                hdng.utilities.rmdir(coverage_directory, true, false);
            end
        end
    end
end
