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
    
    if ~isfield(options, 'n_subsamples')
        %options.n_subsamples = {500 1000 1500 2000 2500};
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
