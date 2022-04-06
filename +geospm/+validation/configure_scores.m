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

function score_contexts = configure_scores(options)
    
    if ~isfield(options, 'scores')
        
        options.scores = { 'geospm.validation.scores.ConfusionMatrix', ...
                           'geospm.validation.scores.StructuralSimilarityIndex', ...
                           'geospm.validation.scores.AKDEBandwidth', ...
                           'geospm.validation.scores.ResidualSmoothness', ...
                           'geospm.validation.scores.ResidualVariances', ...
                           'geospm.validation.scores.VoxelCounts', ...
                           'geospm.validation.scores.InterclassCorrelation', ...
                           'geospm.validation.scores.HausdorffDistance', ...
                           'geospm.validation.scores.MahalanobisDistance', ...
                           'geospm.validation.scores.Coverage', ...
                           'geospm.validation.scores.SelectSmoothingByCoverage' ...
                         };
    end
    
    if ~isfield(options, 'default_score_mode')
        options.default_score_mode = hdng.experiments.Score.COMPUTE_ALWAYS;
    end
    
    score_contexts = cell(numel(options.scores), 1);
    
    for index=1:numel(options.scores)
        
        score_specifier = options.scores{index};
        parts = split(score_specifier, ':');
        
        if numel(parts) > 2
            error('geospm.validation.configure_scores(): Too many parts in specifier ''%s''.', score_specifier);
        end
            
        score_type = parts{1};
        mode = options.default_score_mode;
        
        if numel(parts) == 2
            mode = parts{2};
        end
        
        score = hdng.experiments.Score.create(score_type);
        
        context = struct();
        context.score = score;
        context.score_mode = mode;
        
        score_contexts{index} = context;
    end
end
