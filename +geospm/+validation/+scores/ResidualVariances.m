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

classdef ResidualVariances < geospm.validation.scores.SPMRegressionScore
    %ResidualVariances 
    %   
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = ResidualVariances()
            obj = obj@geospm.validation.scores.SPMRegressionScore();
            
            attribute = obj.result_attributes.define('residual_variance_per_slice');
            attribute.description = 'Residual Variance per Slice';
            
            attribute = obj.result_attributes.define('residual_variance_min_slice');
            attribute.description = 'Residual Variance Minimum Slice';
            
            attribute = obj.result_attributes.define('residual_variance');
            attribute.description = 'Residual Variance';
        end
    end
    
    methods (Access=protected)
        
        function compute_for_spm_regression(obj, spm_regression, extra_variables, evaluation, mode)
            
            spm_session = extra_variables.spm_session;
            
            results = evaluation.results;
            
            only_if_missing = strcmp(mode, hdng.experiments.Score.COMPUTE_IF_MISSING);
            
            if only_if_missing && results.holds_key('residual_variance')
                return
            end
            
            [residual_variances, min_slice, variance_records] = obj.compute_per_slice_residual_variances(spm_regression, spm_session);

            results('residual_variance_per_slice') = hdng.experiments.Value.from(residual_variances);
            results('residual_variance_min_slice') = hdng.experiments.Value.from(cast(min_slice, 'int64') - 1);
            results('residual_variance') = hdng.experiments.Value.from(variance_records); %#ok<NASGU>
        end
        
        
        function [variances, min_slice, result] = compute_per_slice_residual_variances(~, spm_regression, spm_session)
            
            variances = geospm.validation.utilities.compute_per_slice_residual_variance(spm_session.directory);
            [~, min_slice] = min(variances);
            
            residual_variance_path = [spm_session.directory filesep 'ResMS.nii'];
            
            result = hdng.experiments.RecordArray();
        
            result.define_attribute('threshold').description = 'Threshold';
            result.define_attribute('term').description = 'Term';
            result.define_attribute('variance').description = 'Per Slice Variance';
            result.define_attribute('variance.min_slice').description = 'Index of Slice With Minimum Variance';
            result.define_attribute('average_variance').description = 'Per Slice Average Variance';
            result.define_attribute('average_variance.min_slice').description = 'Index of Slice With Minimum Average Variance';
            
            result.define_partitioning_attachment({
                struct('identifier', 'threshold', 'category', 'partitioning', 'view_mode', 'select'), ...
                struct('identifier', 'term', 'category', 'partitioning'), ...
                struct('identifier', 'variance', 'category', 'content'), ...
                struct('identifier', 'variance.min_slice', 'category', 'content'), ...
                struct('identifier', 'average_variance', 'category', 'content'), ...
                struct('identifier', 'average_variance.min_slice', 'category', 'content')});
            
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
                
                new_record = hdng.utilities.Dictionary();

                new_record('threshold') = threshold_value;
                new_record('term') = term_name_value;

                [slice_variance_sum, slice_voxel_counts] = geospm.validation.utilities.sum_voxels_per_slice(residual_variance_path, mask_path);

                average_variance = slice_variance_sum ./ slice_voxel_counts;

                [~, min_variance_slice] = min(slice_variance_sum);

                new_record('variance') = hdng.experiments.Value.from(slice_variance_sum);
                new_record('variance.min_slice') = hdng.experiments.Value.from(cast(min_variance_slice, 'int64') - 1);
                
                [~, min_average_variance_slice] = min(average_variance);
                
                new_record('average_variance') = hdng.experiments.Value.from(average_variance);
                new_record('average_variance.min_slice') = hdng.experiments.Value.from(cast(min_average_variance_slice, 'int64') - 1);

                result.include_record(new_record);
            end
        end
        
    end
end
