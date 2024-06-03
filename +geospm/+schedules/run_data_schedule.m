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

function run_data_schedule(study_random_seed, study_directory, data_specifiers, run_mode, varargin)
    
    %{
        
        study_random_seed - The randomisation seed of the study. Specify
        a value to replicate a particular run of a study, otherwise a
        default value is generated via 'randi(intmax('uint32'), 1)'.
        
        study_directory - A path to the study directory. If empty, a
        timestamped directory in the current working directory will be
        created.
        
        data_specifiers - A cell array of data specifiers

        run_mode - The run mode for the study.
        
        The following name-value arguments are supported:
        
        -------------------------------------------------------------------
        
        n_samples – 

        n_repetitions – Defaults to 1.

        generate_report - Defaults to true.

        geospm_arguments - A struct with the following fields:
            
            write_applied_mask

            smoothing_levels
            smoothing_levels_p_value
            smoothing_levels_as_z_dimension
            smoothing_method
            
            spm_thresholds
            spm_observation_transforms
            spm_add_intercept

        kriging_arguments - A struct with the following fields:
            
            kriging_thresholds
            adjust_variance

        grid_options

        apply_density_mask
        density_mask_factor

        apply_geographic_mask
        add_georeference_to_images

        presentation_layers
        colour_map
        colour_map_mode
        
        study_name
        attachments
        granular
        source_ref
        optional_cmds
        
        render_intercept_separately
        set_model_grid
        do_write_spatial_data
        experiments

        model_specifier:
    
        label
        variables
        interactions
    %}
    
    options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    options.study_random_seed = 325791692;
    options.study_random_seed = 209466425;
    
    options.study_random_seed = study_random_seed;
    options.study_directory = study_directory;
    
    if ~isfield(options, 'n_samples')
        options.n_samples = { 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 15000 };
    end
    
    if ~isfield(options, 'n_repetitions')
        options.n_repetitions = 1;
    end
    
    if ~isfield(options, 'generate_report')
        options.generate_report = true;
    end
    
    if ~isfield(options, 'geospm_arguments')
        options.geospm_arguments = {};
    end
    
    if ~isfield(options.geospm_arguments, 'write_applied_mask')
        options.geospm_arguments.write_applied_mask = true;
    end
    
    if ~isfield(options.geospm_arguments, 'smoothing_levels')
        options.geospm_arguments.smoothing_levels = [10 20 30 50];
    end

    if ~isfield(options.geospm_arguments, 'smoothing_levels_p_value')
        options.geospm_arguments.smoothing_levels_p_value = 0.95;
    end

    if ~isfield(options.geospm_arguments, 'smoothing_levels_as_z_dimension')
        options.geospm_arguments.smoothing_levels_as_z_dimension = true;
    end

    if ~isfield(options.geospm_arguments, 'smoothing_method')
        options.geospm_arguments.smoothing_method = 'default';
    end

    if ~isfield(options.geospm_arguments, 'spm_thresholds')
        options.geospm_arguments.spm_thresholds = { 'T[1,2]: p<0.05 (FWE)' };
    end

    if ~isfield(options.geospm_arguments, 'spm_observation_transforms')
        options.geospm_arguments.spm_observation_transforms = { geospm.stages.ObservationTransform.IDENTITY };
    end

    if ~isfield(options.geospm_arguments, 'spm_add_intercept')
        options.geospm_arguments.spm_add_intercept = true;
    end
    
    if ~isfield(options, 'kriging_arguments')
        options.kriging_arguments = {};
    end

    if ~isfield(options.kriging_arguments, 'kriging_thresholds')
        options.kriging_arguments.kriging_thresholds = { 'normal [2]: p < 0.05', 'normal [1,2]: p < 0.05' };
    end

    if ~isfield(options.kriging_arguments, 'adjust_variance')
        options.kriging_arguments.adjust_variance = true;
    end
    
    if ~isfield(options, 'grid_options')
        options.grid_options = [];
    end
    
    if ~isfield(options, 'apply_density_mask')
        options.apply_density_mask = true;
    end
    
    if ~isfield(options, 'density_mask_factor')
        options.density_mask_factor = 10.0;
    end
    
    if ~isfield(options, 'apply_geographic_mask')
        options.apply_geographic_mask = true;
    end
    
    if ~isfield(options, 'add_georeference_to_images')
        options.add_georeference_to_images = true;
    end

    if ~isfield(options, 'presentation_layers')
        options.presentation_layers = {};
    end

    if ~isfield(options, 'colour_map')
        options.colour_map = [];
    end

    if ~isfield(options, 'colour_map_mode')
        options.colour_map_mode = '';
    end
    
    if ~isfield(options, 'study_name')
        [~, options.study_name, ~] = fileparts(study_directory);
    end
    
    if ~isfield(options, 'attachments')
        options.attachments = struct();
    end
    
    if ~isfield(options, 'source_ref')
        options.source_ref = '';
    end
    
    if ~isfield(options, 'granular')
        options.granular = hdng.one_struct( ...
            'server_url', 'http://localhost:9999' ...
        );
    end

    if ~isfield(options, 'optional_cmds')
        options.optional_cmds = {};
    end
    
    if isempty(options.source_ref)
        if ~isempty(options.granular.server_url)
            granular_service = hdng.granular.Service.local_instance();
            granular_connection = granular_service.connect(options.granular.server_url);
            
            [source, ~] = granular_connection.add_local_directory_source(study_directory, options.study_name);
            
            if isempty(source)
                error('run_data_schedule(): Couldn''t create granular source.');
            end
        
            options.source_ref = source.file_root;
        end
    end
    
    if ~isfield(options, 'render_intercept_separately')
        options.render_intercept_separately = false;
    end
    
    if ~isfield(options, 'set_model_grid')
        options.set_model_grid = true;
    end
    
    if ~isfield(options, 'trace_thresholds')
        options.trace_thresholds = false;
    end
    
    if ~isfield(options, 'do_write_spatial_data')
        options.do_write_spatial_data = true;
    end

    if ~isfield(options, 'experiments')
        
        spm_regression = geospm.validation.configure_spm_experiment(options.geospm_arguments);

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
    
    options.extra_variables = {
        

        geospm.schedules.configure_variable(...
            geospm.validation.Constants.N_SAMPLES, 'Number of Samples', ...
            {}, options.n_samples);
       
        geospm.schedules.configure_variable(...
            'spatial_data_specifier', 'Spatial Data Specifier', ...
            {}, data_specifiers);
        
        geospm.schedules.configure_variable(...
            'experiment_label', 'Experiment Label', ...
            {'spatial_data_specifier'}, ...
            geospm.validation.value_generators.ExtractStructField('from', 'spatial_data_specifier', 'field', 'identifier', 'label_field', 'label') ...
         );
         
        geospm.schedules.configure_variable(...
            geospm.validation.Constants.EXPERIMENT, 'Experiment Type', ...
            {}, experiment_values);

    };
    
    options.extra_variables = options.extra_variables';
    
    %{
    sampling_strategy = geospm.validation.value_generators.CreateSamplingStrategy(options.sampling_strategy, ...
        'add_position_jitter', options.add_position_jitter, ...
        'add_observation_noise', options.add_observation_noise, ...
        'observation_noise', options.observation_noise, ...
        'coincident_observations_mode', options.coincident_observations_mode );
    
    hdng.experiments.Variable(schedule, geospm.validation.Constants.SAMPLING_STRATEGY, sampling_strategy, {}, 'description', 'Sampling Strategy');
    
    create_domain_expressions = geospm.validation.value_generators.CreateDomainExpressions('encoding', options.domain_encoding);
    hdng.experiments.Variable(schedule, geospm.validation.Constants.DOMAIN_EXPRESSION, create_domain_expressions, {generator}, 'description', 'Domain Expression');
    %}

    
    for i=1:numel(options.experiments)
        experiment = options.experiments{i};
        options.extra_variables = [options.extra_variables, experiment.extra_variables];
    end
    
    options = rmfield(options, 'n_samples');

    
    options.evaluator = geospm.validation.DataEvaluator();
    
    options.evaluator.do_write_spatial_data = options.do_write_spatial_data;
    options = rmfield(options, 'do_write_spatial_data');
    
    options.evaluator.apply_density_mask = options.apply_density_mask;
    options.evaluator.density_mask_factor = options.density_mask_factor;
    
    options = rmfield(options, 'apply_density_mask');
    options = rmfield(options, 'density_mask_factor');

    options.evaluator.apply_geographic_mask = options.apply_geographic_mask;
    options = rmfield(options, 'apply_geographic_mask');
    
    options.evaluator.render_intercept_separately = options.render_intercept_separately;
    options = rmfield(options, 'render_intercept_separately');
    
    options.evaluator.add_georeference_to_images = options.add_georeference_to_images;
    options = rmfield(options, 'add_georeference_to_images');
    
    options.evaluator.presentation_layers = options.presentation_layers;
    options = rmfield(options, 'presentation_layers');
    
    options.evaluator.set_model_grid = options.set_model_grid;
    options = rmfield(options, 'set_model_grid');
    
    options.evaluator.trace_thresholds = options.trace_thresholds;
    options = rmfield(options, 'trace_thresholds');

    if ~isempty(options.colour_map)
        options.evaluator.colour_map = options.colour_map;
    end

    options = rmfield(options, 'colour_map');

    if ~isempty(options.colour_map_mode)
        options.evaluator.colour_map_mode = options.colour_map_mode;
    end

    options = rmfield(options, 'colour_map_mode');
    
    if ~isempty(options.grid_options)
        options.evaluator.grid_options = options.grid_options;
    end
    
    options = rmfield(options, 'grid_options');
    
    options = rmfield(options, 'geospm_arguments');
    
    options = rmfield(options, 'kriging_arguments');
    
    options.evaluator.run_mode = run_mode;
    options.evaluator.null_level = 0.0;
    
    %{
    for i=1:numel(file_specifier.bool_variables)
        bool_variable = file_specifier.bool_variables{i};
        options.evaluator.null_level_map(bool_variable) = 0.5;
    end
    %}

    assign_null_levels(data_specifiers, options.evaluator);
    
    if ~strcmp(run_mode, geospm.validation.SpatialExperiment.DEFERRED_MODE)
        
        score_options = struct();
        score_options.scores = { 'geospm.validation.scores.ConfusionMatrix', ...
                                 'geospm.validation.scores.StructuralSimilarityIndex', ...
                                 'geospm.validation.scores.InterclassCorrelation', ...
                                 'geospm.validation.scores.HausdorffDistance', ...
                                 'geospm.validation.scores.MahalanobisDistance', ...
        };

        options.evaluator.score_contexts = geospm.validation.configure_scores(score_options);
    
        options.evaluator.no_targets = false;
        options.evaluator.load_targets = true;
    else
        
        options.evaluator.no_targets = true;
        options.evaluator.load_targets = false;
    end
    
    generate_report = options.generate_report && ...
                      ~strcmp(run_mode, geospm.validation.SpatialExperiment.DEFERRED_MODE) && ...
                      ~strcmp(run_mode, geospm.validation.SpatialExperiment.LOAD_MODE);
    
    options = rmfield(options, 'generate_report');
    
    if generate_report
        
        generator = geospm.validation.reports.EvaluationReport();
        
        %{
        generator.add_table_key('add_nugget', false);
        generator.add_table_key('threshold', []);
        generator.add_table_key('method');
        generator.add_table_key('coincident_observations_mode');
        
        generator.table_row_key = 'variogram_function';
        %}
        
        generator.add_table_key('method');
        generator.add_table_key('coincident_observations_mode');
        generator.table_row_key = 'threshold';
        
        options.evaluator.report_generator = generator;
    end
    
    arguments = hdng.utilities.struct_to_name_value_sequence(options);
    
    study_path = geospm.validation.run_study(arguments{:});
    
    options.evaluator.save_diagnostics_as_json(fullfile(study_path, 'diagnostics.json'));
    
    if generate_report
        
        document = generator.layout();

        context = hdng.documents.renderers.HTMLContext();
        renderer = hdng.documents.renderers.HTMLRenderer();

        attributes = struct();
        attributes.rel = 'stylesheet';
        attributes.type = 'text/css';
        attributes.href = 'report.css';
        attributes.media = 'all';

        context.simple_tag('link', attributes, hdng.documents.renderers.HTMLContext.HEAD_SECTION);

        renderer.render(document, context);

        context.save_output(fullfile(study_path, 'report.html'));
    end

    for index=1:numel(options.optional_cmds)
        
        cmd = options.optional_cmds{index};
        
        optional_args = hdng.utilities.struct_to_name_value_sequence(cmd.options);
        cmd_function = str2func(cmd.func);
        cmd_function(cmd.arguments{:}, optional_args{:});
    end
end

function assign_null_levels(data_specifiers, evaluator)

    variable_type_map = struct();
    variable_bool_map = struct();

    for index=1:numel(data_specifiers)
        specifier = data_specifiers{index};
        variables = specifier.file_options.variables;
    
        for i=1:numel(variables)
            variable = variables(i);
    
            identifier = variable.resolve_name();

            if ~isfield(variable_type_map, identifier)
                variable_type_map.(identifier) = struct();
            end

            types = variable_type_map.(identifier);
            types.(variable.type) = true;
            variable_type_map.(identifier) = types;
            
            is_logical = strcmp(variable.type, 'logical');

            if is_logical
                variable_bool_map.(identifier) = true;
                evaluator.null_level_map(identifier) = 0.5;
            end

            if isfield(variable_bool_map, identifier) && numel(fieldnames(types)) > 1
                error('Inconsistent variable types across one or more data specifiers.');
            end
        end
        
    end
end