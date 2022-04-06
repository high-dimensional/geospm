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

classdef ResidualSmoothness < geospm.validation.scores.SPMRegressionScore
    %ResidualSmoothness 
    %   
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = ResidualSmoothness()
            obj = obj@geospm.validation.scores.SPMRegressionScore();
            
            attribute = obj.result_attributes.define('residual_smoothness');
            attribute.description = 'Residual Smoothness';
            
            attribute = obj.result_attributes.define('residual_smoothness_fwhm');
            attribute.description = 'Residual Smoothness (FWHM)';
        end
    end
    
    methods (Access=protected)
        
        function compute_for_spm_regression(obj, spm_regression, extra_variables, evaluation, mode) %#ok<INUSL>
            
            results = evaluation.results;
            
            only_if_missing = strcmp(mode, hdng.experiments.Score.COMPUTE_IF_MISSING);
            
            if only_if_missing && results.holds_key('residual_smoothness')
                return
            end
            
            spm_session = extra_variables.spm_session;
            
            smoothness_fwhm = spm_session.variables.xVol.FWHM;
            smoothness_p_value = geospm.utilities.diameter_from_p_fwhm(spm_regression.smoothing_levels_p_value, smoothness_fwhm, 2);

            results('residual_smoothness_fwhm') = hdng.experiments.Value.from(smoothness_fwhm);
            results('residual_smoothness') = hdng.experiments.Value.from(smoothness_p_value); %#ok<NASGU>
        end
    end
end
