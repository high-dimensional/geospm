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

classdef CriticalHeightThresholds < geospm.validation.scores.SPMRegressionScore
    %CriticalHeightThresholds 
    %   
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = CriticalHeightThresholds()
            obj = obj@geospm.validation.scores.SPMRegressionScore();
            
            attribute = obj.result_attributes.define('critical_height_thresholds');
            attribute.description = 'Critical Height Thresholds';
        end
    end
    
    methods (Access=protected)
        
        function compute_for_spm_regression(obj, spm_regression, extra_variables, evaluation, mode)
            
            results = evaluation.results;
            
            only_if_missing = strcmp(mode, hdng.experiments.Score.COMPUTE_IF_MISSING);
            
            if only_if_missing && results.holds_key('critical_height_thresholds')
                return
            end
            
            spm_session = extra_variables.spm_session;
            
            residuals_file_pattern = '^(ResI_[0-9]+\.nii)$';
            [file_paths, ~] = hdng.utilities.scan_files(spm_session.directory, residuals_file_pattern);
            
            if isempty(file_paths)
                warning('%s.compute(): Score is not applicable, missing residual files ''ResI_*.nii'' in results directory: %s.', class(obj), spm_session.directory);
                return
            end
            
            critical_height_thresholds = obj.compute_critical_height_thresholds(spm_regression, spm_session);
            results('critical_height_thresholds') = hdng.experiments.Value.from(critical_height_thresholds);  %#ok<NASGU>
        end
        
        function result = compute_critical_height_thresholds(~, spm_regression, spm_session)
            
            result = hdng.experiments.RecordArray();
            
            
            result.define_attribute('statistic').description = 'Statistic';
            result.define_attribute('threshold').description = 'Threshold';
            result.define_attribute('slice').description = 'Selected Slice';
            result.define_attribute('critical_height').description = 'EC-Derived Critical Height Thresholds';
            result.define_attribute('fwhm').description = 'Full-Width-Half-Maximum';
            result.define_attribute('diameter').description = 'Diameters';
            result.define_attribute('resels').description = 'Resel Values';
            
            %no_threshold_value = hdng.experiments.Value.empty_with_label('no threshold');
            
            available_statistics = spm_session.contrast_statistics;
            
            for i=1:numel(available_statistics)

                statistic = available_statistics{i};
                statistic_value = hdng.experiments.Value.from(statistic, [statistic ' Statistic']);

                for j=1:numel(spm_regression.thresholds)

                    threshold = spm_regression.thresholds{j};
                    
                    if ~strcmp(threshold.correction, geospm.SignificanceTest.FAMILY_WISE_ERROR)
                        continue
                    end

                    threshold_value = hdng.experiments.Value.from(j, threshold.description);
                    
                    [slice, slice_thresholds, fwhms, resels] = geospm.validation.utilities.select_slice_by_critical_height_threshold(spm_session.variables, threshold.value, statistic);
                    
                    slice_resels = resels(slice, :);
                    slice_fwhm = mean(fwhms(slice, 1:2));
                    
                    diameter = geospm.utilities.diameter_from_p_fwhm(spm_regression.smoothing_levels_p_value, slice_fwhm, 2);
                    
                    record = hdng.utilities.Dictionary();
                    
                    record('statistic') = statistic_value;
                    record('threshold') = threshold_value;
                    record('slice') = hdng.experiments.Value.from(cast(slice, 'int64') - 1);
                    record('critical_height') = hdng.experiments.Value.from(slice_thresholds(slice));
                    record('fwhm') = hdng.experiments.Value.from(slice_fwhm);
                    record('diameter') = hdng.experiments.Value.from(diameter);
                    record('resels') = hdng.experiments.Value.from(slice_resels);
                    
                    result.include_record(record);
                end
            end
        end
         
    end
end
