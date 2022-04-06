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

classdef StructuralSimilarityIndex < geospm.validation.scores.ImageScore
    %StructuralSimilarityIndex Computes the intersection over union.
    %   Takes the variable names of an experiment's data.
    
    properties
    end
    
    methods
        
        function obj = StructuralSimilarityIndex()
            obj = obj@geospm.validation.scores.ImageScore();
            obj.score_descriptions = { 'Structural Similarity Index' };
        end
        
        
        function result = compute_scores_for_slice(~, target_z, target_slice, result_z, result_slice) %#ok<INUSL>
            result = ssim(result_slice, target_slice);
            
            if isempty(result)
                result = 0.0;
            end
        end
        
    end
    
    
    methods (Access=protected)
        
        function result = compute_identifier(~)
            result = 'structural_similarity_index';
        end
    end
end
