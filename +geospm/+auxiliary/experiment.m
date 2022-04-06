% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2021,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function result = experiment()
    result = struct();
    result.spm_thresholds = {'T[2]: p<0.05 (FWE)'};
    result.domain_encoding = {'direct_with_interactions'};
    result.add_observation_noise = true;
    result.repetition = {1};
    result.run_mode = 'regular';
    result.default_score_mode = 'always';
    result.sampling_strategy = 'standard_sampling';
    result.coincident_observations_mode = 'jitter';
    result.n_samples = num2cell(1600);
    result.noise_level = num2cell([0.0, 0.05, 0.10]);
    result.smoothing_levels = [25 35 45];
    result.smoothing_method = geospm.auxiliary.smoothing_method();
    result.experiments = { 'SPM' };
    result.kriging_kernel = { 'Mat' };
    result.generators = {{...
        'geospm.validation.generator_models.A_AxB_B:Koch Snowflake', ...
        'Koch Snowflakes, No Interaction'}};
    result.is_rehearsal = false;
end
