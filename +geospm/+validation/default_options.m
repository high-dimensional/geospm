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

function [options] = default_options(options)
    
    if ~isfield(options, 'study_directory')
        options.study_directory = hdng.utilities.make_timestamped_directory();
    end
    
    if ~isfield(options, 'canonical_base_path')
        options.canonical_base_path = options.study_directory;
    end
    
    if ~isfield(options, 'run_mode')
        options.run_mode = geospm.validation.SpatialExperiment.REGULAR_MODE;
    end
    
    if ~isfield(options, 'default_score_mode')
        options.default_score_mode = hdng.experiments.Score.COMPUTE_ALWAYS;
    end
    
    if ~isfield(options, 'nifti_mode')
        options.nifti_mode = geospm.validation.SpatialExperiment.NIFTI_KEEP;
    end
    
    if ~isfield(options, 'add_probes')
        options.add_probes = false;
    end
    
    if ~isfield(options, 'repetition')
        options.repetition = {1};
    end

    if ~isfield(options, 'scale_factor')
        options.scale_factor = 1;
    end

    if ~isfield(options, 'is_rehearsal')
        options.is_rehearsal = false;
    end

    if ~isfield(options, 'n_samples')
        options.n_samples = {1000};
    end
    
    if ~isfield(options, 'noise_level')
        options.noise_level = {0.15};
    end

    if ~isfield(options, 'domain_encoding')
        options.domain_encoding = geospm.models.DomainEncodings.DIRECT_ENCODING;
    end
    
    if ~isfield(options, 'add_position_jitter')
        options.add_position_jitter = true;
    end
    
    if ~isfield(options, 'add_observation_noise')
        options.add_observation_noise = true;
    end
end
