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

function run_data_schedule(study_random_seed, study_directory, file_specifier, model_specifiers, run_mode, varargin)
    
    
    %geospm.validation.SpatialExperiment.REGULAR_MODE
    
    %{
    
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
    
    if ~isfield(options, 'method') 
        options.method = { 'SPM' };
    end
    
    if ~isfield(options, 'n_samples')
        options.n_samples = { 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 15000 };
    end
    
    if ~isfield(options, 'n_repetitions')
        options.n_repetitions = 10;
    end
    
    if ~isfield(options, 'generate_report')
        options.generate_report = true;
    end
    
    if ~isfield(options, 'geospm_arguments')
        options.geospm_arguments = [];
    end
    
    if ~isfield(options, 'kriging_arguments')
        options.kriging_arguments = [];
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
    
    if ~isfield(options, 'add_georeference_to_images')
        options.add_georeference_to_images = true;
    end

    if ~isfield(options, 'presentation_layers')
        options.presentation_layers = {};
    end
    
    if ~isfield(options, 'study_name')
        [~, options.study_name, ~] = fileparts(study_directory);
    end
    
    if ~isfield(options, 'source_ref')
        options.source_ref = '';
    end
    
    if ~isfield(options, 'granular')
        options.granular = hdng.one_struct( ...
            'server_url', 'http://localhost:9999' ...
        );
    end
    
    if isempty(options.source_ref)
        if ~isempty(options.granular.server_url)
            granular_service = hdng.granular.Service.local_instance();
            granular_connection = granular_service.connect(options.granular.server_url);
            
            [source, ~] = granular_connection.add_local_directory_source(study_directory, options.study_name);
            
            if isempty(source)
                error('run_parallel_data_schedule(): Couldn''t create granular source.');
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
    
    if ~isfield(options.geospm_arguments, 'write_volume_mask')
        options.geospm_arguments.write_volume_mask = true;
    end

    if ~isfield(options.geospm_arguments, 'spm_add_intercept')
        options.geospm_arguments.spm_add_intercept = true;
    end
    
    if ~isfield(options.geospm_arguments, 'spm_thresholds')
        options.geospm_arguments.spm_thresholds = { 'T[2]: p<0.05 (FWE)', 'T[1,2]: p<0.05 (FWE)' };
    end

    if ~isfield(options.kriging_arguments, 'kriging_thresholds')
        options.kriging_arguments.kriging_thresholds = { 'normal [2]: p < 0.05', 'normal [1,2]: p < 0.05' };
    end
    
    options.spatial_data_specifier = {};
    
    for i=1:numel(model_specifiers)

        model_specifier = model_specifiers{i};
        
        if ~isfield(model_specifier, 'interactions')
            model_specifier.interactions = {};
        end
        
        if ~isfield(model_specifier, 'variable_labels')
            model_specifier.variable_labels = {};
        end
        
        model_file_specifier = file_specifier;
        model_file_specifier.identifier = model_specifier.identifier;
        model_file_specifier.label = model_specifier.label;
        model_file_specifier.group_identifier = model_specifier.group_identifier;
        model_file_specifier.group_label = model_specifier.group_label;
        model_file_specifier.include = [model_file_specifier.include, model_specifier.variables];
        model_file_specifier.interactions = model_specifier.interactions;
        model_file_specifier.variable_labels = model_specifier.variable_labels;
        
        if isfield(model_file_specifier, 'bool_variables')
            model_file_specifier = rmfield(model_file_specifier, 'bool_variables');
        end
        
        for j=1:numel(model_specifier.variables)
            
            variable = model_specifier.variables{j};
            
            if ~ismember(variable, file_specifier.bool_variables)
                model_file_specifier.standardise{end + 1} = variable;
            end
        end
        
        options.spatial_data_specifier{end + 1} = model_file_specifier;
    end
    
    options.extra_variables = {};
    
    options.extra_variables = add_conditional_value_list_variable(...
        options.extra_variables, ...
        'variogram_function', 'Variogram Function', ...
        'method', 'Kriging', ...
        'Mat', 'Gau');
    
    options.extra_variables = add_conditional_value_list_variable(...
        options.extra_variables, ...
        'add_nugget', 'Nugget Component', ...
        'method', 'Kriging', ...
        true, false);
    
    options.extra_variables = add_conditional_value_list_variable(...
        options.extra_variables, ...
        'coincident_observations_mode', 'Coincident Observations Mode', ...
        'method', 'Kriging', ...
        'jitter', 'average');
    
    
    options.evaluator = geospm.validation.DataEvaluator();
    
    options.evaluator.do_write_spatial_data = options.do_write_spatial_data;
    options = rmfield(options, 'do_write_spatial_data');
    
    options.evaluator.apply_volume_mask = options.apply_density_mask;
    options.evaluator.volume_mask_factor = options.density_mask_factor;
    
    options = rmfield(options, 'apply_density_mask');
    options = rmfield(options, 'density_mask_factor');
    
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
    
    if ~isempty(options.grid_options)
        options.evaluator.grid_options = options.grid_options;
    end
    
    options = rmfield(options, 'grid_options');
    
    if ~isempty(options.geospm_arguments)
        argument_names = fieldnames(options.geospm_arguments);
        
        for i=1:numel(argument_names)
            name = argument_names{i};
            
            options.evaluator.geospm_arguments.(name) = options.geospm_arguments.(name);
        end
    end
    
    options = rmfield(options, 'geospm_arguments');
    
    if ~isempty(options.kriging_arguments)
        argument_names = fieldnames(options.kriging_arguments);
        
        for i=1:numel(argument_names)
            name = argument_names{i};
            
            options.evaluator.kriging_arguments.(name) = options.kriging_arguments.(name);
        end
    end
    
    options = rmfield(options, 'kriging_arguments');
    
    options.evaluator.run_mode = run_mode;
    options.evaluator.null_level = 0.0;
    
    for i=1:numel(file_specifier.bool_variables)
        bool_variable = file_specifier.bool_variables{i};
        options.evaluator.null_level_map(bool_variable) = 0.5;
    end
    
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
    
    options.evaluator.adjust_variance = true;
    
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
    
    study_path = geospm.validation.run_comparative_study(arguments{:});
    
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
end

function variables = add_conditional_value_list_variable(variables, identifier, description, requirement, condition_value, varargin)
    
    conditional = create_string_conditional(requirement, condition_value);
    conditional.value_generator = hdng.experiments.ValueList.from(varargin{:});
    
    variable = struct(...
        'identifier', identifier, ...
        'description', description, ...
        'value_generator', conditional ...
    );
    
    variable.requirements = { conditional.requirement };
    variables = [variables, {variable}];
end

function conditional = create_string_conditional(requirement, condition)

    conditional = hdng.experiments.ConditionalGenerator();
    conditional.requirement = requirement;
    conditional.requirement_test = @(value) strcmp(value, condition);
    conditional.missing_label = '-';
    conditional.value_generator = [];
end
