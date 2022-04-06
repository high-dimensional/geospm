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

classdef InterclassCorrelation < geospm.validation.scores.ImageScore
    %InterclassCorrelation
    
    properties
    end
    
    methods
        
        function obj = InterclassCorrelation()
            obj = obj@geospm.validation.scores.ImageScore();
            obj.score_descriptions = { 'Interclass Correlation' };
        end
        
        function result = compute_scores_for_slice(~, target_z, target_slice, result_z, result_slice) %#ok<INUSL>
            
            target_mean = mean(target_slice, [1, 2]);
            result_mean = mean(result_slice, [1, 2]);
            
            grand_mean = (target_mean + result_mean) / 2.0;
            mean_slice = (target_slice + result_slice) ./ 2.0;
            
            MS_between = 2.0 * sum(power(mean_slice - grand_mean, 2.0), [1, 2]) / (numel(target_slice) - 1);
            MS_within  = sum(power(target_slice - mean_slice, 2.0) + power(result_slice - mean_slice, 2.0), [1, 2]) / numel(target_slice);
            
            result = (MS_between - MS_within) / (MS_between + MS_within);
        end
        
    end
    
    
    methods (Access=protected)
        
        function result = compute_identifier(~)
            result = 'icc';
        end
    end
end
