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

function [spm_regression] = configure_spm_experiment(options)

    spm_regression = struct();
    spm_regression.experiment_type = 'geospm.validation.experiments.SPMRegression';
    spm_regression.description = 'SPM';
    spm_regression.extra_variables = {};
    
    conditional = hdng.experiments.ConditionalGenerator();
    conditional.requirement = 'experiment';
    conditional.requirement_test = @(value) strcmp(value.experiment_type, 'geospm.validation.experiments.SPMRegression');
    conditional.missing_label = '-';
    
    if ~isfield(options, 'spm_thresholds')
        options.spm_thresholds = { 'T[2]: p<0.05 (FWE)' };
    end
    
    conditional.value_generator = hdng.experiments.ValueList.from(...
        geospm.SignificanceTest.from_char(options.spm_thresholds));
    
    spm_regression_thresholds = struct(...
        'identifier', 'spm_regression_thresholds', ...
        'description', 'SPM Thresholds', ...
        'value_generator', conditional, ...
        'interactive', struct('default_display_mode', 'auto') ...
    );
    
    spm_regression_thresholds.requirements = { conditional.requirement };
    
    spm_regression.extra_variables = [spm_regression.extra_variables, {spm_regression_thresholds}];
    
    
    
    conditional = hdng.experiments.ConditionalGenerator();
    conditional.requirement = 'experiment';
    conditional.requirement_test = @(value) strcmp(value.experiment_type, 'geospm.validation.experiments.SPMRegression');
    conditional.missing_label = '-';
    
    if ~isfield(options, 'smoothing_levels')
        %options.smoothing_levels = geospm.validation.utilities.suggest_smoothing_levels([120 120]);
        options.smoothing_levels = [20 50 80];
    end
    
    if ~isfield(options, 'scale_factor')
        options.scale_factor = 1.0;
    end
    
    smoothing_levels = options.smoothing_levels * options.scale_factor;
    
    conditional.value_generator = hdng.experiments.ValueList.from(smoothing_levels);
    
    smoothing_levels = struct(...
        'identifier', geospm.validation.Constants.SMOOTHING_LEVELS, ...
        'description', 'Smoothing Levels', ...
        'value_generator', conditional, ...
        'interactive', struct('default_display_mode', 'auto') ...
    );
    
    smoothing_levels.requirements = { conditional.requirement };
    
    spm_regression.extra_variables = [spm_regression.extra_variables, {smoothing_levels}];
    
    
    
    
    conditional = hdng.experiments.ConditionalGenerator();
    conditional.requirement = 'experiment';
    conditional.requirement_test = @(value) strcmp(value.experiment_type, 'geospm.validation.experiments.SPMRegression');
    conditional.missing_label = '-';
    
    if ~isfield(options, 'smoothing_levels_p_value')
        options.smoothing_levels_p_value = 0.95;
    else
        if options.smoothing_levels_p_value <= 0.0 || options.smoothing_levels_p_value >= 1.0
            error('configure_spm_experiment(): Specified options.smoothing_levels_p_value is not in (0, 1.0): %f', options.smoothing_levels_p_value);
        end
    end
    
    conditional.value_generator = hdng.experiments.ValueList.from(options.smoothing_levels_p_value);
    
    smoothing_levels_p_value = struct(...
        'identifier', geospm.validation.Constants.SMOOTHING_LEVELS_P_VALUE, ...
        'description', 'Smoothing Levels P-Value', ...
        'value_generator', conditional, ...
        'interactive', struct('default_display_mode', 'auto') ...
    );
    
    smoothing_levels_p_value.requirements = { conditional.requirement };
    
    spm_regression.extra_variables = [spm_regression.extra_variables, {smoothing_levels_p_value}];
    
    conditional = hdng.experiments.ConditionalGenerator();
    conditional.requirement = 'experiment';
    conditional.requirement_test = @(value) strcmp(value.experiment_type, 'geospm.validation.experiments.SPMRegression');
    conditional.missing_label = '-';
    
    if ~isfield(options, 'smoothing_levels_as_z_dimension')
        options.smoothing_levels_as_z_dimension = { true };
    end
    
    if ~iscell(options.smoothing_levels_as_z_dimension)
        options.smoothing_levels_as_z_dimension = { options.smoothing_levels_as_z_dimension };
    end
    
    conditional.value_generator = hdng.experiments.ValueList.from(options.smoothing_levels_as_z_dimension{:});
    
    smoothing_levels_as_z_dimension = struct(...
        'identifier', 'smoothing_levels_as_z_dimension', ...
        'description', 'SPM Smoothing Levels as Z Dimension', ...
        'value_generator', conditional, ...
        'interactive', struct('default_display_mode', 'auto') ...
    );
    
    smoothing_levels_as_z_dimension.requirements = { conditional.requirement };
    
    spm_regression.extra_variables = [spm_regression.extra_variables, {smoothing_levels_as_z_dimension}];
    


    
    conditional = hdng.experiments.ConditionalGenerator();
    conditional.requirement = 'experiment';
    conditional.requirement_test = @(value) strcmp(value.experiment_type, 'geospm.validation.experiments.SPMRegression');
    conditional.missing_label = '-';
    
    if ~isfield(options, 'smoothing_method')
        options.smoothing_method = 'default';
    end
    
    options.smoothing_method = geospm.spm.configure_smoothing_method(options.smoothing_method);
    
    conditional.value_generator = hdng.experiments.ValueList.from(hdng.experiments.Value.from(options.smoothing_method, options.smoothing_method.description));
    
    smoothing_method = struct(...
        'identifier', geospm.validation.Constants.SMOOTHING_METHOD, ...
        'description', 'Smoothing Method', ...
        'value_generator', conditional, ...
        'interactive', struct('default_display_mode', 'auto') ...
    );
    
    smoothing_method.requirements = { conditional.requirement };
    
    spm_regression.extra_variables = [spm_regression.extra_variables, {smoothing_method}];
    
    
    
    conditional = hdng.experiments.ConditionalGenerator();
    conditional.requirement = 'experiment';
    conditional.requirement_test = @(value) strcmp(value.experiment_type, 'geospm.validation.experiments.SPMRegression');
    conditional.missing_label = '-';
    
    if ~isfield(options, 'spm_observation_transforms')
        options.spm_observation_transforms = { geospm.stages.ObservationTransform.IDENTITY };
    end
    
    conditional.value_generator = hdng.experiments.ValueList.from(options.spm_observation_transforms{:});
    
    observation_transform = struct(...
        'identifier', 'spm_observation_transforms', ...
        'description', 'SPM Observation Transform', ...
        'value_generator', conditional, ...
        'interactive', struct('default_display_mode', 'auto') ...
    );
    
    observation_transform.requirements = { conditional.requirement };
    
    spm_regression.extra_variables = [spm_regression.extra_variables, {observation_transform}];
    
    
    
    conditional = hdng.experiments.ConditionalGenerator();
    conditional.requirement = 'experiment';
    conditional.requirement_test = @(value) strcmp(value.experiment_type, 'geospm.validation.experiments.SPMRegression');
    conditional.missing_label = '-';
    
    if ~isfield(options, 'spm_add_intercept')
        options.spm_add_intercept = { true };
    end

    if ~iscell(options.spm_add_intercept)
        options.spm_add_intercept = { options.spm_add_intercept };
    end
    
    conditional.value_generator = hdng.experiments.ValueList.from(options.spm_add_intercept{:});
    
    spm_add_intercept = struct(...
        'identifier', 'spm_add_intercept', ...
        'description', 'SPM Add Intercept', ...
        'value_generator', conditional, ...
        'interactive', struct('default_display_mode', 'auto') ...
    );
    
    spm_add_intercept.requirements = { conditional.requirement };
    
    spm_regression.extra_variables = [spm_regression.extra_variables, {spm_add_intercept}];
    
    
    spm_regression.extra_requirements = {
        geospm.validation.Constants.DOMAIN_EXPRESSION, ...
        geospm.validation.Constants.SMOOTHING_LEVELS, ...
        geospm.validation.Constants.SMOOTHING_LEVELS_P_VALUE, ...
        geospm.validation.Constants.SMOOTHING_LEVELS_AS_Z_DIMENSION, ...
        geospm.validation.Constants.SMOOTHING_METHOD, ...
        'spm_regression_thresholds', ...
        'spm_observation_transforms', ...
        'spm_add_intercept' };
    

end
