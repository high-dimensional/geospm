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

function run(varargin)

    options = hdng.utilities.parse_struct_from_varargin(varargin{:});

    if ~isfield(options, 'study_directory')
        options.study_directory = '';
    end
    
    if ~isfield(options, 'canonical_base_path')
        options.canonical_base_path = options.study_directory;
    end
    
    if ~isfield(options, 'study_random_seed')
        options.study_random_seed = randi(intmax('uint32'), 1);
    end
    
    if ~isfield(options, 'run_mode')
        options.run_mode = geospm.validation.SpatialExperiment.REGULAR_MODE;
    end
    
    if ~isfield(options, 'nifti_mode')
        options.nifti_mode = geospm.validation.SpatialExperiment.NIFTI_KEEP;
    end
    
    if ~isfield(options, 'add_probes')
        options.add_probes = false;
    end
    
    if ~isfield(options, 'trace_thresholds')
        options.trace_thresholds = false;
    end
    
    if ~isfield(options, 'apply_density_mask')
        options.apply_density_mask = false;
    end
    
    if ~isfield(options, 'density_mask_factor')
        options.density_mask_factor = [];
    end
    
    if ~isfield(options, 'null_level')
        options.null_level = 0.5;
    end
    
    if ~isfield(options, 'null_level_map')
        options.null_level_map = containers.Map('KeyType', 'char', 'ValueType', 'double');
    end
    
    if ~isfield(options, 'standardise_predictions')
        options.standardise_predictions = true;
    end
    
    if ~isfield(options, 'n_repetitions')
        
        if ~isfield(options, 'repetition')
            options.n_repetitions = 5;
        else
            options.n_repetitions = numel(options.repetition);
        end
    end
    
    if ~isfield(options, 'repetition')
        options.repetition = num2cell(1:options.n_repetitions);
    end
    
    if ~isfield(options, 'experiments')
        %spm_regression = struct('experiment_type', 'geospm.validation.experiments.SPMRegression');
        %kriging = struct('experiment_type', 'geospm.validation.experiments.Kriging');
        
        spm_regression = geospm.validation.configure_spm_experiment(options);

        options.experiments = { spm_regression ...
                                };
    end
    
    for i=1:numel(options.experiments)
        experiment = options.experiments{i};

        if ~isfield(experiment, 'experiment_type')
            error('Expected experiment type in experiment specification.');
        end
        
        if ~isfield(experiment, 'extra_requirements')
            experiment.extra_requirements = {};
        end
        
        if ~isfield(experiment, 'extra_variables')
            experiment.extra_variables = {};
        end
        
        options.experiments{i} = experiment;
    end
    
    if ~isfield(options, 'extra_variables')
        options.extra_variables = {};
    end
    
    for i=1:numel(options.experiments)
        experiment = options.experiments{i};
        options.extra_variables = [options.extra_variables, experiment.extra_variables];
    end
    
    for i=1:numel(options.extra_variables)
        variable = options.extra_variables{i};

        if ~isfield(variable, 'identifier')
            error('Expected identifier for variable specification.');
        end
        
        if ~isfield(variable, 'requirements')
            variable.requirements = {};
        end
        
        if ~isfield(variable, 'value_generator')
            error('Expected value_generator for variable specification.');
        end
        
        options.extra_variables{i} = variable;
    end
    
    if ~isfield(options, 'generators')
        
        generate_circles = struct('generator_type', 'factorisation');
        generate_circles.initialiser = 'geospm.validation.generator_models.A_AxB_B';
        generate_circles.options = struct('use_fractals', false);
        generate_circles.description = 'Circles';
        
        generate_fractals = struct('generator_type', 'factorisation');
        generate_fractals.initialiser = 'geospm.validation.generator_models.A_AxB_B';
        generate_fractals.options = struct('use_fractals', true);
        generate_fractals.description = 'Fractals';
        
        options.generators = { generate_circles, ...
                               generate_fractals };
                            
        options.generators = { generate_fractals };
        
        if isfield(options, 'noise_level') && isempty(options.noise_level)
            error('Cannot define default for generators if noise_level is declared empty.');
        end
        
        options.controls = { {'a_probability', 'A Probability', 'dependency', 'noise_level', @noise_level_conversion}, ...
                             {'b_probability', 'B Probability', 'dependency', 'noise_level', @noise_level_conversion}};
    end
    
    if ~isfield(options, 'controls')
        options.controls = {};
    end
    
    if ~isfield(options, 'n_samples')
        options.n_samples = {500 1000 1500 2000 2500};
    end
    
    if ~isfield(options, 'scale_factor')
        options.scale_factor = 1;
    end
    
    if ~isfield(options, 'noise_level')
        options.noise_level = num2cell(1 - [0.7, 0.8, 0.9, 1]);
    end
    
    if ~isfield(options, 'sampling_strategy')
        options.sampling_strategy = 'standard_sampling';
    end

    if ~isfield(options, 'add_nugget')
        options.add_nugget = true;
    end
    
    if ~isfield(options, 'add_position_jitter')
        options.add_position_jitter = true;
    end
    
    if ~isfield(options, 'add_observation_noise')
        options.add_observation_noise = true;
    end
    
    if ~isfield(options, 'observation_noise')
        options.observation_noise = 0.005;
    end
    
    if ~isfield(options, 'coincident_observations_mode')
        options.coincident_observations_mode = geospm.models.sampling.Subsampling.JITTER_MODE;
    end
    
    if ~isfield(options, 'domain_encoding')
        options.domain_encoding = geospm.models.DomainEncodings.DIRECT_ENCODING;
    end
    
    if ~isfield(options, 'is_rehearsal')
        options.is_rehearsal = false;
    end
    
    if ~isfield(options, 'randomisation_variables')
        options.randomisation_variables = ...
            { hdng.experiments.Schedule.REPETITION, ...
              geospm.validation.Constants.N_SAMPLES };
    end
    
    if ~isempty(options.noise_level) && ~any(strcmp('noise_level', options.randomisation_variables))
        options.randomisation_variables = [options.randomisation_variables, 'noise_level'];
    end
    
    if ~isfield(options, 'stage_identifier')
        options.stage_identifier = '1';
    end
    
    if ~isfield(options, 'no_stage_path')
        options.no_stage_path = true;
    end
    
    if ~isfield(options, 'evaluation_prefix')
        options.evaluation_prefix = '';
    end
    
    source_version = hdng.utilities.SourceVersion(fileparts(mfilename('fullpath')));
    
    schedule = hdng.experiments.Schedule();
    
    source_version = hdng.experiments.constant(schedule, geospm.validation.Constants.SOURCE_VERSION, 'Source Version', source_version.string);
    source_version.interactive = struct('default_display_mode', 'select_all');
    
    null_level = hdng.experiments.constant(schedule, geospm.validation.Constants.NULL_LEVEL, 'Null Level', options.null_level);
    null_level.interactive = struct('default_display_mode', 'select_all');
    
    standardise_predictions = hdng.experiments.constant(schedule, geospm.validation.Constants.STANDARDISE_PREDICTIONS, 'Standardise Predictions', options.standardise_predictions);
    standardise_predictions.interactive = struct('default_display_mode', 'select_all');
    
    hdng.experiments.Variable(...
        schedule, ...
        geospm.validation.Constants.REPETITION, ...
        hdng.experiments.ValueList.from(options.repetition{:}), {}, ...
        'description', 'Repetition');
    
    %debug_count = hdng.utilities.NumericValue(0);
    
    generator = geospm.validation.value_generators.CreateGenerators(options.generators);
    %generator.debug_path = @() sprintf('%s%sdebug_%d', options.study_directory, filesep, debug_count.post_increment());
    
    generator = hdng.experiments.Variable(...
        schedule, ...
        geospm.validation.Constants.GENERATOR, ...
        generator, {}, ...
        'description', 'Generator');
    
    transform = eye(2, 3);
    transform(1, 1) = options.scale_factor;
    transform(2, 2) = options.scale_factor;
    
    transform = hdng.experiments.constant(...
        schedule, geospm.validation.Constants.TRANSFORM, 'Transform', transform);
    
    if isfield(options, 'sample_density')
        
        sample_density = hdng.experiments.constant(schedule, geospm.validation.Constants.SAMPLE_DENSITY, 'Sample Density', options.sample_density);
        
        spatial_sample_count = geospm.validation.value_generators.SpatialSampleCount();
        hdng.experiments.Variable(schedule, geospm.validation.Constants.N_SAMPLES, ...
            spatial_sample_count, {generator, sample_density, transform}, 'description', 'Number of Samples');
    else
        hdng.experiments.constant(schedule, geospm.validation.Constants.N_SAMPLES, 'Number of Samples', options.n_samples{:});
    end
    
    if ~isempty(options.noise_level)
        hdng.experiments.constant(schedule, 'noise_level', 'Noise Level', options.noise_level{:});
    end
    
    experiment_values = cell(numel(options.experiments), 1);
    
    for index=1:numel(options.experiments)
        experiment = options.experiments{index};
        
        if isfield(experiment, 'description')
            description = experiment.description;
        else
            description = experiment.experiment_type;
        end
        
        experiment = hdng.experiments.Value.from(experiment, description, missing, 'builtin.missing');
        experiment_values{index} = experiment;
    end
    
    hdng.experiments.constant(schedule, geospm.validation.Constants.EXPERIMENT, 'Experiment Type', experiment_values{:});
    
    observation_noise = hdng.experiments.constant(schedule, geospm.validation.Constants.ADDITIVE_OBSERVATION_NOISE, 'Additive Observation Noise', options.observation_noise * cast(options.add_observation_noise, 'double'));
    observation_noise.interactive = struct('default_display_mode', 'select_all');
    
    sampling_strategy = geospm.validation.value_generators.CreateSamplingStrategy(options.sampling_strategy, ...
        'add_position_jitter', options.add_position_jitter, ...
        'add_observation_noise', options.add_observation_noise, ...
        'observation_noise', options.observation_noise, ...
        'coincident_observations_mode', options.coincident_observations_mode );
    
    hdng.experiments.Variable(schedule, geospm.validation.Constants.SAMPLING_STRATEGY, sampling_strategy, {}, 'description', 'Sampling Strategy');
    
    create_domain_expressions = geospm.validation.value_generators.CreateDomainExpressions('encoding', options.domain_encoding);
    hdng.experiments.Variable(schedule, geospm.validation.Constants.DOMAIN_EXPRESSION, create_domain_expressions, {generator}, 'description', 'Domain Expression');
    
    controls = cell(1, numel(options.controls));
    
    for i=1:numel(options.controls)
        control_specifier = options.controls{i};
        control_identifier = control_specifier{1};
        control_description = control_specifier{2};
        iterator_type = control_specifier{3};
        
        interactive = struct();
        interactive.default_display_mode = 'auto';
        
        if strcmpi(iterator_type, 'dependency')
            control_requirements = control_specifier(4);
            control_arguments = control_specifier(5:end);
            interactive.default_display_mode = 'select_all';
        else
            control_requirements = {};
            control_arguments = control_specifier(4:end);
        end
        
        control_adapter = geospm.validation.value_generators.ControlAdapter(control_identifier, iterator_type, control_requirements, control_arguments{:});
        
        requirements = {generator};
        
        for j=1:numel(control_requirements)
            r = control_requirements{j};
            r = schedule.variables_by_identifier(r);
            requirements = [requirements, {r}]; %#ok<AGROW>
        end
        
        controls{i} = hdng.experiments.Variable(schedule, control_identifier, control_adapter, requirements, 'interactive', interactive, 'description', control_description);
    end
    
    randomisation_requirements = {};
    
    if numel(options.randomisation_variables) == 0
        options.randomisation_variables = schedule.variables;
    else
        for i=1:numel(options.randomisation_variables)
            r = options.randomisation_variables{i};
            r = schedule.variables_by_identifier(r);
            randomisation_requirements = [randomisation_requirements, {r}]; %#ok<AGROW>
        end
    end
    
    random_seed = hdng.experiments.RandomSeed(options.randomisation_variables);
    random_seed = hdng.experiments.Variable(schedule, geospm.validation.Constants.RANDOM_SEED, random_seed, randomisation_requirements, 'interactive', struct('default_display_mode', 'select_all'), 'description', 'Random Seed');
    
    spatial_model = geospm.validation.value_generators.GenerateSpatialModel('description', 'Spatial Model');
    hdng.experiments.Variable(schedule, geospm.validation.Constants.SPATIAL_MODEL, spatial_model, [{generator, transform, random_seed}, controls], 'description', 'Spatial Model');
    
    for i=1:numel(options.extra_variables)
        variable = options.extra_variables{i};
        
        requirements = {};
        
        for j=1:numel(variable.requirements)
            r = variable.requirements{j};
            r = schedule.variables_by_identifier(r);
            requirements = [requirements, {r}]; %#ok<AGROW>
        end
        
        if ~isfield(variable, 'interactive')
            variable.interactive = struct('default_display_mode', 'auto');
        end
        
        if ~isfield(variable, 'description')
            variable.description = variable.identifier;
        end
        
        hdng.experiments.Variable(schedule, variable.identifier, variable.value_generator, requirements, 'interactive', variable.interactive, 'description', variable.description);
    end
    
    
    hdng.experiments.constant(schedule, geospm.validation.Constants.SPM_VERSION, 'SPM Version', geospm.spm.SPMJobList.access_spm_interface().version_string);
    
    evaluator = geospm.validation.Evaluator();
    evaluator.run_mode = options.run_mode;
    
    evaluator.nifti_mode = options.nifti_mode;
    evaluator.add_probes = options.add_probes;
    evaluator.trace_thresholds = options.trace_thresholds;
    evaluator.apply_density_mask = options.apply_density_mask;
    evaluator.density_mask_factor = options.density_mask_factor;
    evaluator.null_level = options.null_level;
    evaluator.null_level_map = options.null_level_map;
    evaluator.standardise_predictions = options.standardise_predictions;
    
    evaluator.score_contexts = geospm.validation.configure_scores(options);
    
    strategy = hdng.experiments.SimpleStrategy();
    strategy.schedule = schedule;
    strategy.evaluator = evaluator;
    strategy.stage_identifier = options.stage_identifier;
    strategy.prefix = options.evaluation_prefix;
    
    study = hdng.experiments.Study();
    study.strategy = strategy;
    study.prefix = options.evaluation_prefix;
    
    study_options = struct();
    study_options.is_rehearsal = options.is_rehearsal;
    study_options.random_seed = options.study_random_seed;
    study_options.canonical_base_path = options.canonical_base_path;
    study_options.no_stage_path = options.no_stage_path;
    
    study.execute(options.study_directory, study_options);
end

function [value, description] = noise_level_conversion(value, ~)
    value = 1 - value;
    description = num2str(value);
end
