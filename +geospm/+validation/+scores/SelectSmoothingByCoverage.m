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

classdef SelectSmoothingByCoverage < geospm.validation.scores.SPMRegressionScore
    %SelectSmoothingByCoverage 
    %   
    
    properties
        copied_scores
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = SelectSmoothingByCoverage()
            obj = obj@geospm.validation.scores.SPMRegressionScore();
            
            obj.copied_scores = [];
            
            attribute = obj.result_attributes.define('terms_by_coverage');
            attribute.description = 'Terms By Coverage';
        end
    end
    
    methods (Access=protected)
        
        function compute_for_spm_regression(obj, spm_regression, extra_variables, evaluation, mode)
            
            results = evaluation.results;
            threshold_directories = extra_variables.threshold_directories;
            
            if ~results.holds_key('coverage')
                return
            end
            
            only_if_missing = strcmp(mode, hdng.experiments.Score.COMPUTE_IF_MISSING);
            
            if only_if_missing && results.holds_key('terms_by_coverage')
                return
            end
            
            obj.copied_scores = containers.Map('KeyType', 'char', 'ValueType', 'logical');
            
            term_records = results('terms').content;
            coverage_records = results('coverage').content;
            
            terms_by_coverage = obj.extract_images(spm_regression, term_records, coverage_records, threshold_directories);
            
            partitioning = terms_by_coverage.attachments.partitioning;
            
            scores = obj.copied_scores.keys();
            
            for index=1:numel(scores)
                score = scores{index};
                
                volume_attribute = term_records.attribute_for_name(score);
                slice_attribute = terms_by_coverage.attribute_for_name(score);
                slice_attribute.description = volume_attribute.description;
                
                partitioning.define_attribute(score, 'content');
            end
            
            results('terms_by_coverage') = hdng.experiments.Value.from(terms_by_coverage); %#ok<NASGU>
        end
        
        function result = extract_images(obj, spm_regression, term_records, coverage_records, ~)
            
            
            result = hdng.experiments.RecordArray();
            
            result.define_attribute('threshold').description = 'Threshold';
            result.define_attribute('term').description = 'Term';
            result.define_attribute('slice').description = 'Index of Slice With Maximum Coverage';
            result.define_attribute('contrast').description = 'Contrast';
            result.define_attribute('map').description = 'Map';
            result.define_attribute('mask').description = 'Mask';
            result.define_attribute('result').description = 'Result';
            result.define_attribute('target').description = 'Target';
            
            result.define_partitioning_attachment({
                struct('identifier', 'threshold', 'category', 'partitioning', 'view_mode', 'select'), ...
                struct('identifier', 'term', 'category', 'partitioning'), ...
                struct('identifier', 'slice', 'category', 'content'), ...
                struct('identifier', 'contrast', 'category', 'content'), ...
                struct('identifier', 'map', 'category', 'content'), ...
                struct('identifier', 'mask', 'category', 'content'), ...
                struct('identifier', 'result', 'category', 'content'), ...
                struct('identifier', 'target', 'category', 'content')});
            
            
            for index=1:numel(spm_regression.thresholds)
                
                match = struct();
                match.threshold = hdng.experiments.Value.from(index);
                
                matched_records = coverage_records.select(match);
                
                if matched_records.length ~= 1
                    error('SelectSmoothingByCoverage.extract_images() can''t match threshold record or threshold record missing in coverage.');
                end
                
                coverage_record = matched_records.unsorted_records{1};
                
                slice_by_coverage = coverage_record('coverage.max_slice').content;
                slice_by_coverage = slice_by_coverage + 1;
                
                match = struct();
                match.threshold_or_statistic = hdng.experiments.Value.from(index);
                
                matched_records = term_records.select(match);
                
                if matched_records.length == 0
                    error('SelectSmoothingByCoverage.extract_images() can''t match term records or term records missing in result terms.');
                end
                
                obj.extract_term_images_for_threshold(result, spm_regression, matched_records, slice_by_coverage);
            end
        end
        
        function copy_scores(obj, record, new_record, slice)
            
            keys = record.keys();
            
            for index=1:numel(keys)
                key = keys{index};
                
                if ~startsWith(key, 'score.')
                    continue
                end
                
                if endsWith(key, '.max') || endsWith(key, '.min')
                    continue
                end
                
                scores = record(key).content;
                
                if ~isempty(scores)
                    new_record(key) = hdng.experiments.Value.from(scores(slice));
                else
                    new_record(key) = hdng.experiments.Value.empty_with_label('Not Applicable');
                end
                
                obj.copied_scores(key) = true;
            end
        end
        
        function extract_term_images_for_threshold(obj, result, spm_regression, term_records, slice)
            
            records = term_records.unsorted_records;
            
            for index=1:numel(records)
                
                record = records{index};
                
                new_record = hdng.utilities.Dictionary();
                
                new_record('threshold') = record('threshold_or_statistic');
                new_record('term') = record('term');
                new_record('slice') = hdng.experiments.Value.from(cast(slice, 'int64') - 1); % Added 21 July 21: Subtract one "again" to have a zero-based slice
                
                volume = record('contrast').content;
                volume = obj.extract_volume_slice(spm_regression, volume, slice, true);
                new_record('contrast') = hdng.experiments.Value.from(volume);
                
                volume = record('mask').content;
                volume = obj.extract_volume_slice(spm_regression, volume, slice, false);
                mask = hdng.experiments.Value.from(volume);
                new_record('mask') = mask;
                new_record('result') = mask;
                
                volume = record('map').content;
                volume = obj.extract_volume_slice(spm_regression, volume, slice, true);
                new_record('map') = hdng.experiments.Value.from(volume);
                
                new_record('target') = record('target');
                
                obj.copy_scores(record, new_record, slice);
                
                result.include_record(new_record);
            end
        end
        
        function slice_volume = extract_volume_slice(~, spm_regression, volume, slice, has_alpha)
            
            image_slice_path = [];
            
            if ~isempty(volume.image)
                
                image_path = spm_regression.absolute_path(volume.image.path);
                [threshold_directory, image_name, ~] = fileparts(image_path);

                output_directory = fullfile(threshold_directory, 'by_coverage');
                [dirstatus, dirmsg] = mkdir(output_directory);
                if dirstatus ~= 1; error(dirmsg); end

                vpng_parts = regexp(image_name, '(.+)\(([0-9]+)@([0-9]+),([0-9]+)\)$', 'tokens');
                vpng_parts = vpng_parts{1};

                [~, image_base_name, image_base_name_ext] = fileparts(vpng_parts{1});

                image_base_name = [image_base_name image_base_name_ext];

                image_levels = str2double(vpng_parts{2});
                image_width = str2double(vpng_parts{3});
                image_height = str2double(vpng_parts{4});

                [image_data, ~, image_alpha] = imread(image_path);
                image_size = size(image_data);

                N_levels = numel(spm_regression.smoothing_levels);
                slice_height = image_size(1) / N_levels;

                if image_levels ~= N_levels
                    error('SelectSmoothingByCoverage.extract_volume_slice(): Smoothing levels in SPMRegression do not match image slices in file: %d != %d', N_levels, image_levels);
                end

                if image_height ~= slice_height
                    error('SelectSmoothingByCoverage.extract_volume_slice(): Image data slice height does not match vpng specifier: %d != %d', slice_height, image_height);
                end

                if image_width ~= image_size(2)
                    error('SelectSmoothingByCoverage.extract_volume_slice(): Image data slice width does not match vpng specifier: %d != %d', image_size(2), image_width);
                end


                slice_data = image_data(((slice - 1) * slice_height + 1):slice*slice_height, :, :);
                image_slice_path = fullfile(output_directory, [image_base_name '.png']);

                args = {};

                if has_alpha
                    args{end + 1} = 'Alpha';
                    args{end + 1} = image_alpha(((slice - 1) * slice_height + 1):slice*slice_height, :);
                end

                imwrite(slice_data, image_slice_path, args{:});
            end
            
            
            
            if ~isempty(volume.scalars)
                nifti_path = spm_regression.absolute_path(volume.scalars.path);
                [threshold_directory, nifti_name, ~] = fileparts(nifti_path);

                output_directory = fullfile(threshold_directory, 'by_coverage');
                [dirstatus, dirmsg] = mkdir(output_directory);
                if dirstatus ~= 1; error(dirmsg); end

                [nifti_data, nifti_data_type] = geospm.utilities.read_nifti(nifti_path);
                nifti_size = size(nifti_data);

                if numel(nifti_size) == 3
                    nifti_levels = nifti_size(3);
                else
                    nifti_levels = 1;
                end

                if nifti_levels ~= N_levels
                    error('SelectSmoothingByCoverage.extract_volume_slice(): Smoothing levels in SPMRegression do not match nifti slices in file: %d != %d', N_levels, nifti_levels);
                end

                slice_data = nifti_data(:, :, slice);
                scalars_slice_path = fullfile(output_directory, [nifti_name '.nii']);

                geospm.utilities.write_nifti(slice_data, scalars_slice_path, nifti_data_type);
            end
            
            slice_names = {};
            
            if ~isempty(volume.slice_names)
                slice_names = volume.slice_names(slice);
            end
            
            slice_volume = spm_regression.build_volume_reference(scalars_slice_path, image_slice_path, slice_names);
        end
    end
end
