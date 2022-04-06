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

function [adaptive_kde] = configure_akde_experiment(options)

    adaptive_kde = struct('experiment_type', 'geospm.validation.experiments.AdaptiveKDE');
    adaptive_kde.description = 'Adaptive Kernel Density Estimation';
    adaptive_kde.extra_variables = {};
    
    conditional = hdng.experiments.ConditionalGenerator();
    conditional.requirement = 'experiment';
    conditional.requirement_test = @(value) strcmp(value.experiment_type, 'geospm.validation.experiments.AdaptiveKDE');
    conditional.missing_label = '-';
    
    
    if ~isfield(options, 'akde_thresholds')
        %options.akde_thresholds = { 'none:0.05' };
        options.akde_thresholds = { 'normal: p < 0.05' };
    end
    
    conditional.value_generator = hdng.experiments.ValueList.from(...
        geospm.SignificanceTest.from_char(options.akde_thresholds));
    
    akde_thresholds = struct(...
        'identifier', 'akde_thresholds', ...
        'description', 'AKDE Thresholds', ...
        'value_generator', conditional, ...
        'interactive', struct('default_display_mode', 'auto') ...
    );
    
    akde_thresholds.requirements = { conditional.requirement };
    
    adaptive_kde.extra_variables = [adaptive_kde.extra_variables, {akde_thresholds}];
    
    adaptive_kde.extra_requirements = {
        geospm.validation.Constants.DOMAIN_EXPRESSION, ...
        'akde_thresholds' };
    

end
