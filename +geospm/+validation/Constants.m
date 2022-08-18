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

classdef Constants < handle
    %Constants Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        
        SOURCE_VERSION = 'source_version'
        
        NULL_LEVEL = 'null_level'
        
        REPETITION = 'repetition'
        EXPERIMENT = 'experiment'
        RANDOM_SEED = 'random_seed'
        
        DOMAIN = 'domain'
        GENERATOR = 'generator'
        SPATIAL_MODEL = 'spatial_model'
        SAMPLING_STRATEGY = 'sampling_strategy'
        
        SAMPLE_DENSITY = 'sample_density'
        N_SAMPLES = 'n_samples'
        SMOOTHING_LEVELS = 'smoothing_levels'
        SMOOTHING_LEVELS_P_VALUE = 'smoothing_levels_p_value'
        
        TRANSFORM = 'transform'
        DOMAIN_EXPRESSION = 'domain_expression'
        SPATIAL_RESOLUTION = 'spatial_resolution'
        
        THRESHOLDS = 'thresholds'
        THRESHOLD_CONTRASTS = 'threshold_contrasts'
        
        SMOOTHING_METHOD = 'smoothing_method'
        
        SPM_VERSION = 'spm_version'
    end
    
end
