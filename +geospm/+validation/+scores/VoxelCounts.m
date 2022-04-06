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

classdef VoxelCounts < geospm.validation.scores.SPMRegressionScore
    %VoxelCounts 
    %   
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = VoxelCounts()
            obj = obj@geospm.validation.scores.SPMRegressionScore();
            
            attribute = obj.result_attributes.define('voxel_counts');
            attribute.description = 'Voxel Counts';
        end
    end
    
    methods (Access=protected)
        
        function compute_for_spm_regression(obj, spm_regression, ~, evaluation, mode)
            
            results = evaluation.results;
            
            only_if_missing = strcmp(mode, hdng.experiments.Score.COMPUTE_IF_MISSING);
            
            if only_if_missing && results.holds_key('voxel_counts')
                return
            end
            
            voxel_count_records = obj.compute_per_slice_voxel_counts(spm_regression);
            results('voxel_counts') = hdng.experiments.Value.from(voxel_count_records); %#ok<NASGU>
        end
        
        function result = compute_per_slice_voxel_counts(~, spm_regression)
        
            result = hdng.experiments.RecordArray();
            
            result.define_attribute('threshold').description = 'Threshold';
            result.define_attribute('term').description = 'Term';
            result.define_attribute('voxel_counts').description = 'Per Slice Voxel Counts';
            result.define_attribute('voxel_counts.max_slice').description = 'Index of Slice With Maximum Voxel Count';
            result.define_attribute('statistic_average').description = 'Per Slice Average Statistic';
            result.define_attribute('statistic_average.max_slice').description = 'Index of Slice With Maximum Average Statistic';
            
            result.define_partitioning_attachment({
                struct('identifier', 'threshold', 'category', 'partitioning', 'view_mode', 'select'), ...
                struct('identifier', 'term', 'category', 'partitioning'), ...
                struct('identifier', 'voxel_counts', 'category', 'content'), ...
                struct('identifier', 'voxel_counts.max_slice', 'category', 'content'), ...
                struct('identifier', 'statistic_average', 'category', 'content'), ...
                struct('identifier', 'statistic_average.max_slice', 'category', 'content')});
            
            term_records = spm_regression.results('terms').content.unsorted_records;
            
            for index=1:numel(term_records)
                
                record = term_records{index};

                threshold_value = record('threshold');
                
                if strcmp(threshold_value.type_identifier, 'builtin.null')
                    continue
                end
                
                term_name_value = record('term');
                
                mask_volume = record('mask').content;
                mask_path = spm_regression.absolute_path(mask_volume.scalars.path);
                
                map_volume = record('map').content;
                map_path = spm_regression.absolute_path(map_volume.scalars.path);
                
                new_record = hdng.utilities.Dictionary();

                new_record('threshold') = threshold_value;
                new_record('term') = term_name_value;
                
                %fprintf('Computing per slice voxel count:\n  term=%s\n  mask_path=%s\n  map_path=%s\n', term_name, mask_path, map_path);
                
                [slice_statistic_sum, slice_voxel_counts] = geospm.validation.utilities.sum_voxels_per_slice(map_path, mask_path);

                [~, max_voxel_count_slice] = max(slice_voxel_counts);
                
                new_record('voxel_counts') = hdng.experiments.Value.from(slice_voxel_counts);
                new_record('voxel_counts.max_slice') = hdng.experiments.Value.from(cast(max_voxel_count_slice, 'int64') - 1);
                
                statistic_average = slice_statistic_sum ./ slice_voxel_counts;
                [~, max_statistic_average_slice] = max(statistic_average);
                
                new_record('statistic_average') = hdng.experiments.Value.from(statistic_average);
                new_record('statistic_average.max_slice') = hdng.experiments.Value.from(cast(max_statistic_average_slice, 'int64') - 1);

                result.include_record(new_record);
            end
        end
        
    end
end
