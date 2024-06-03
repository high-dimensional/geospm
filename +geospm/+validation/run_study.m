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

function study_path = run_study(varargin)
    
    %{
        Runs all experiments in a study.

        The following name-value arguments are supported:
        -------------------------------------------------------------------

        study_directory - A path to the study directory. If empty, a
        timestamped directory in the current working directory will be
        created.

        study_name - The name of the study. The default value is ''.

        canonical_base_path - A path to be used as the canonical base path
        for all metadata instead of the study directory, which is the
        default.

        source_ref - A granular server source reference to be used in
        conjunction with the canonical_base_path in all file references
        when writing metadata. Empty ('') by default, otherwise specify the
        UUID4 of a source stored in a granular server. 
        
        study_random_seed - The randomisation seed of the study. Specify
        a value to replicate a particular run of a study, otherwise a
        default value is generated via 'randi(intmax('uint32'), 1)'.

        is_rehearsal - Indicates a whether this run is a rehearsal. A
        rehearsal iterates all experiments in a study without running them.
        Defaults to 'false'.

        n_repetitions - Specifies the number of times individual 
        experiments in the study are repeated.

        repetition - An array of unique repetition numbers to be used as
        a variable in the study.

        randomisation_variables - A cell array of study schedule variables
        whose values affect the randomisation of each experiment. If not
        specified, only hdng.experiments.Schedule.REPETITION is assumed to
        be a randomisation variable.
        
        stage_identifier -

        no_stage_path - Defaults to 'true'.

        evaluation_prefix - Defaults to ''.
        
        evaluator - The evaluator instance to be used. If not specified,
        a hdng.experiments.SimulatedEvaluator instance will be created.

        extra_variables - A cell array of additional variables to be 
        included in the study schedule. Each variable is specified as a
        struct with the following fields:

            identifier - a unique identifier of the variable
            description - a human-readable text label
            requirements - a cell array of identifier of variables this
            variable depends on.
            value_generator - An instance of a value generator that
            iterates all values of the variable to be used.
            
            interactive - A struct of presentation parameters. Currently
            defaults to a single field, 'default_display_mode' and a default
            value, 'auto'.
        
        attachments - A struct of optional study attachments.

        The following variables will always be defined in the study
        schedule:

        geospm.validation.Constants.SOURCE_VERSION
        geospm.validation.Constants.REPETITION
        geospm.validation.Constants.RANDOM_SEED
        geospm.validation.Constants.SPM_VERSION
        
    %}

    options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    if ~isfield(options, 'study_directory')
        options.study_directory = hdng.utilities.make_timestamped_directory();
    end

    if ~isfield(options, 'study_name')
        options.study_name = '';
    end
    
    if ~isfield(options, 'canonical_base_path')
        options.canonical_base_path = options.study_directory;
    end
    
    if ~isfield(options, 'source_ref')
        options.source_ref = '';
    end
    
    if ~isfield(options, 'study_random_seed')
        options.study_random_seed = randi(intmax('uint32'), 1);
    end

    if ~isfield(options, 'is_rehearsal')
        options.is_rehearsal = false;
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
    
    if ~isfield(options, 'randomisation_variables')
        options.randomisation_variables = ...
            { hdng.experiments.Schedule.REPETITION, ...
              };
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
    
    if ~isfield(options, 'evaluator')
        options.evaluator = hdng.experiments.SimulatedEvaluator();
    end
    
    if ~isfield(options, 'extra_variables')
        options.extra_variables = {};
    end
    
    %{
        Extra variable: 
            identifier
            requirements
            value_generator
            interactive: struct('default_display_mode', 'auto')
            description
    %}
    
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
    
    if ~isfield(options, 'attachments')
        options.attachments = {};
    end
    
    source_version = hdng.utilities.SourceVersion(fileparts(mfilename('fullpath')));
    
    schedule = hdng.experiments.Schedule();
    
    source_version = hdng.experiments.constant(schedule, geospm.validation.Constants.SOURCE_VERSION, 'Source Version', source_version.string);
    source_version.interactive = struct('default_display_mode', 'select_all');
    
    hdng.experiments.Variable(...
        schedule, ...
        geospm.validation.Constants.REPETITION, ...
        hdng.experiments.ValueList.from(options.repetition{:}), {}, ...
        'description', 'Repetition');
    
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
    hdng.experiments.Variable(schedule, geospm.validation.Constants.RANDOM_SEED, random_seed, randomisation_requirements, 'interactive', struct('default_display_mode', 'select_all'), 'description', 'Random Seed');
    
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
    
    strategy = hdng.experiments.SimpleStrategy();
    strategy.schedule = schedule;
    strategy.evaluator = options.evaluator;
    strategy.stage_identifier = options.stage_identifier;
    strategy.prefix = options.evaluation_prefix;
    
    study = hdng.experiments.Study();
    study.strategy = strategy;
    study.prefix = options.evaluation_prefix;
    study.name = options.study_name;
    study.attachments = options.attachments;
    
    study_options = struct();
    study_options.is_rehearsal = options.is_rehearsal;
    study_options.random_seed = options.study_random_seed;
    study_options.canonical_base_path = options.canonical_base_path;
    study_options.source_ref = options.source_ref;
    study_options.no_stage_path = options.no_stage_path;
    
    study_path = study.execute(options.study_directory, study_options);
end

%{
function [with_requirements, without_requirements] = ...
    filter_extra_variables_by_requirements(extra_variables, requirements)

    with_requirements = {};
    without_requirements = {};
    
    for i=1:numel(extra_variables)
        variable = extra_variables{i};
        has_requirements = false;
        
        for j=1:numel(variable.requirements)
            r = variable.requirements{j};
            
            if any(match_string(r, requirements))
                with_requirements = [with_requirements variable]; %#ok<AGROW>
                has_requirements = true;
            end
        end
        
        if ~has_requirements
            without_requirements = [without_requirements variable]; %#ok<AGROW>
        end
    end
end


function result = match_string(value, candidates)

    result = zeros(numel(candidates), 1, 'logical');

    for i=1:numel(candidates)
        result(i) = strcmp(value, candidates{i});
    end
end
%}
