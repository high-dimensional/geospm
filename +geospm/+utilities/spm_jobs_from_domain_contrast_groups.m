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

function contrast_jobs = spm_jobs_from_domain_contrast_groups(contrast_groups)

    contrast_jobs = cell(size(contrast_groups, 1), 1);

    for index=1:size(contrast_groups, 1)

        job = create_spm_contrast_job();
        job.statistic = contrast_groups{index, 1};

        job_contrasts = contrast_groups{index, 2};

        for c=1:numel(job_contrasts)
            contrast = job_contrasts{c};
            job.contrasts =      [job.contrasts; {contrast.weights}];
            job.contrast_names = [job.contrast_names; {contrast.name}];
        end

        contrast_jobs{index} = job;
    end
end

function result = create_spm_contrast_job()
    result = struct();
    result.statistic = [];
    result.contrasts = {};
    result.contrast_names = {};
end
