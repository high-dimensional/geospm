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

classdef AKDEBandwidth < geospm.validation.scores.SPMRegressionScore
    %AKDEBandwidth 
    %   
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = AKDEBandwidth()
            obj = obj@geospm.validation.scores.SPMRegressionScore();
            
            attribute = obj.result_attributes.define('akde_bandwidths');
            attribute.description = 'AKDE Bandwidths';
        end
    end
    
    methods (Access=protected)
        
        function compute_for_spm_regression(obj, spm_regression, extra_variables, evaluation, mode) %#ok<INUSL>
            
            results = evaluation.results;
            
            only_if_missing = strcmp(mode, hdng.experiments.Score.COMPUTE_IF_MISSING);
            
            if only_if_missing && results.holds_key('akde_bandwidths')
                return
            end
            
            bandwidths = obj.estimate_kernel_bandwidths(spm_regression);
            
            array = hdng.experiments.RecordArray();
            
            array.define_attribute('term').description = 'Term';
            array.define_attribute('stddev').description = 'Standard Deviation';
            array.define_attribute('diameter').description = sprintf('Diameter @%.3f', spm_regression.smoothing_levels_p_value);
            
            array.define_partitioning_attachment({
                struct('identifier', 'term', 'category', 'partitioning'), ...
                struct('identifier', 'stddev', 'category', 'content'), ...
                struct('identifier', 'diameter', 'category', 'content')});
            
            
            for index=1:numel(bandwidths)
                
                stddev = mean(bandwidths{index});
                diameter = geospm.utilities.diameter_from_p_stddev(spm_regression.smoothing_levels_p_value, stddev, 2);
                term_name = spm_regression.domain_expression.term_names{index};
                
                record = hdng.utilities.Dictionary();
                record('term') = hdng.experiments.Value.from(term_name);
                record('stddev') = hdng.experiments.Value.from(stddev);
                record('diameter') = hdng.experiments.Value.from(diameter);
                
                array.include_record(record);
            end
            
            results('akde_bandwidths') = hdng.experiments.Value.from(array); %#ok<NASGU>
        end
        
        function result = estimate_kernel_bandwidths(~, spm_regression)
            
            result = cell(spm_regression.domain_expression.N_terms, 1);
            
            for index=1:spm_regression.domain_expression.N_terms
                
                kernel_result = geospm.validation.utilities. ...
                    akde_for_univariate_spatial_data([1, 1, 0], ...
                    [spm_regression.model.spatial_resolution + 1 1], ...
                    spm_regression.model.spatial_resolution, ...
                    spm_regression.spatial_data, ...
                    0.5, ...
                    index);
                
                result{index} = kernel_result.bandwidth;
            end
        end
    end
end
