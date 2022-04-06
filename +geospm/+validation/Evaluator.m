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

classdef Evaluator < hdng.experiments.Evaluator
    
    %SimulatedEvaluator Encapsulates a method of generating stages in a study.
    %
    
    properties
        results
        configuration_variable
        rng_variable
        run_mode
        nifti_mode
        add_probes
        trace_thresholds
        
        apply_volume_mask
        volume_mask_factor
        
        no_targets
        load_targets
        
        colour_map
        colour_map_mode
        
        render_intercept_separately
        
        add_georeference_to_images
        do_write_spatial_data
        
        null_level
        null_level_map
        
        diagnostics
        last_experiment
    end
    
    properties (Dependent, Transient)
        score_contexts
    end
    
    properties (GetAccess=private, SetAccess=private)
        score_contexts_
    end
    
    methods
        
        function obj = Evaluator()
            obj = obj@hdng.experiments.Evaluator();
            
            obj.score_contexts_ = {};
            
            obj.run_mode = geospm.validation.SpatialExperiment.REGULAR_MODE;
            obj.nifti_mode = geospm.validation.SpatialExperiment.NIFTI_KEEP;
            obj.add_probes = false;
            obj.trace_thresholds = false;
            obj.apply_volume_mask = false;
            obj.volume_mask_factor = [];
            
            obj.no_targets = false;
            obj.load_targets = false;
            
            obj.colour_map = [];
            obj.colour_map_mode = hdng.colour_mapping.ColourMap.LAYER_MODE;
            
            obj.render_intercept_separately = false;
            
            obj.add_georeference_to_images = false;
            obj.do_write_spatial_data = true;
            
            obj.null_level = 0.5;
            obj.null_level_map = containers.Map('KeyType', 'char', 'ValueType', 'double');
            
            obj.diagnostics = {};
            obj.last_experiment = {};
        end
        
        function result = get.score_contexts(obj)
            result = obj.score_contexts_;
        end
        
        function remove_result_attributes(obj, names)

            for index=1:numel(names)
                name = names{index};
                obj.result_attributes.remove(name);
            end
        end
        
        function add_result_attributes(obj, attributes)

            for index=1:numel(attributes)
                
                attribute = attributes{index};
                
                evaluator_attribute = obj.result_attributes.define(attribute.identifier);

                evaluator_attribute.attachments = attribute.attachments;
                evaluator_attribute.description = attribute.description;
            end
        end
        
        function set.score_contexts(obj, value)
            
            for index=1:numel(value)
                
                context = value{index};
                
                if ~isfield(context, 'score')
                    error('geospm.validation.Evaluator.set.score_contexts(): Missing expected ''score'' field in context.');
                end
                
                if ~isfield(context, 'score_mode')
                    error('geospm.validation.Evaluator.set.score_contexts(): Missing expected ''score_mode'' field in context.');
                end
            end
            
            for index=1:numel(obj.score_contexts_)
                
                context = obj.score_contexts_{index};
                obj.remove_result_attributes(context.score.result_attributes.names);
            end
            
            obj.score_contexts_ = value;
            
            for index=1:numel(obj.score_contexts_)
                
                context = obj.score_contexts_{index};
                obj.add_result_attributes(context.score.result_attributes.attributes);
            end
        end
        
        function apply(obj, evaluation, options)
            
            obj.last_experiment = {};
            
            if ~isfield(options, 'is_rehearsal')
                options.is_rehearsal = false;
            end
            
            configuration = evaluation.configuration;
            
            status = ['    directory: ' evaluation.directory newline];
            
            configuration_keys = configuration.values.keys();
            
            for index=1:numel(configuration_keys)
                key = configuration_keys{index};
                value = configuration.values(key);
                status = [status sprintf('    %s: %s\n', key, value.label)]; %#ok<AGROW>
            end
            
            fprintf('Evaluating experiment:\n%s\n', status);
            
            if ~options.is_rehearsal
                
                random_seed = configuration(geospm.validation.Constants.RANDOM_SEED);
                settings = configuration(geospm.validation.Constants.EXPERIMENT);
                spatial_model = configuration(geospm.validation.Constants.SPATIAL_MODEL);
                sampling_strategy = configuration(geospm.validation.Constants.SAMPLING_STRATEGY);
                n_samples = configuration(geospm.validation.Constants.N_SAMPLES);

                experiment_type = str2func(settings.experiment_type);

                extra_requirements = settings.extra_requirements;

                for index=1:numel(extra_requirements)
                    identifier = extra_requirements{index};
                    extra_requirements{index} = configuration(identifier);
                end
                
                experiment = experiment_type(...
                                random_seed, ...
                                evaluation.directory, ...
                                obj.run_mode, ...
                                obj.nifti_mode, ...
                                spatial_model, ...
                                sampling_strategy, ...
                                n_samples, ...
                                extra_requirements{:});
                
                obj.created_experiment(experiment);
                            
                obj.last_experiment = experiment;
                            
                experiment.add_probes = obj.add_probes;
                experiment.canonical_base_path = evaluation.canonical_base_path;
                experiment.do_write_spatial_data = obj.do_write_spatial_data;
                
                experiment.colour_map_mode = obj.colour_map_mode;
                
                if ~isempty(obj.colour_map)
                    experiment.colour_map = obj.colour_map;
                end
                
                if isprop(experiment, 'render_intercept_separately')
                    experiment.render_intercept_separately = obj.render_intercept_separately;
                end
                
                if isprop(experiment, 'trace_thresholds')
                    experiment.trace_thresholds = obj.trace_thresholds;
                end
                 
                if isprop(experiment, 'apply_volume_mask')
                    experiment.apply_volume_mask = obj.apply_volume_mask;
                     
                    if isprop(experiment, 'volume_mask_factor') && ~isempty(obj.volume_mask_factor)
                        experiment.volume_mask_factor = obj.volume_mask_factor;
                    end
                end
                
                if isprop(experiment, 'no_targets')
                    experiment.no_targets = obj.no_targets;
                end
                
                if isprop(experiment, 'load_targets')
                    experiment.load_targets = obj.load_targets;
                end
                
                if isprop(experiment, 'add_georeference_to_images')
                    experiment.add_georeference_to_images = obj.add_georeference_to_images;
                end
                
                if isprop(experiment, 'null_level')
                    experiment.null_level = obj.null_level;
                end
                
                if isprop(experiment, 'null_level_map')
                    
                    null_level_names = keys(obj.null_level_map);
                    
                    for i=1:numel(null_level_names)
                        null_level_name = null_level_names{i};
                        experiment.null_level_map(null_level_name) = obj.null_level_map(null_level_name);
                    end
                end
                 
                 
                evaluation.start_time = obj.now();
                 
                experiment.run();
                 
                evaluation.stop_time = obj.now();
                 
                %duration = evaluation.duration;
                %duration.Format = 'hh:mm:ss.SSS';
                
                evaluation.attachments.experiment = experiment;
                evaluation.results = experiment.results;
                
                if ~obj.no_targets
                    if strcmp(obj.run_mode, geospm.validation.SpatialExperiment.REGULAR_MODE) || ...
                         strcmp(obj.run_mode, geospm.validation.SpatialExperiment.RESUME_MODE) || ...
                         strcmp(obj.run_mode, geospm.validation.SpatialExperiment.LOAD_MODE)

                        for index=1:numel(obj.score_contexts)
                            context = obj.score_contexts{index};
                            context.score.compute(evaluation, context.score_mode);
                         end
                    end
                end
                
                experiment.cleanup();
                 
                experiment_attributes = experiment.result_attributes.attributes;
                
                for index=1:numel(experiment_attributes)
                    experiment_attribute = experiment_attributes{index};
                    evaluator_attribute = obj.result_attributes.define(experiment_attribute.identifier);
                     
                    evaluator_attribute.attachments = experiment_attribute.attachments;
                    evaluator_attribute.description = experiment_attribute.description;
                end
                
                for i=1:numel(experiment.diagnostics)
                    diagnostic = experiment.diagnostics{i};
                    diagnostic.configuration_number = configuration.number;
                    diagnostic.experiment = status;
                    
                    obj.diagnostics = [obj.diagnostics; diagnostic];
                end
            else
                
                evaluator_attribute = obj.result_attributes.define('command_paths');
                evaluator_attribute.description = 'Command Paths';
                
                evaluation.results('command_paths') = hdng.experiments.Value.empty_with_label('No command files.');
            end
        end
        
        function save_diagnostics_as_json(obj, file_path)
            json = jsonencode(obj.diagnostics);
            hdng.utilities.save_text(json, file_path);
        end
    end
    
    methods (Access=protected)
        
        function created_experiment(obj, experiment) %#ok<INUSD>
        end
        
    end
    
    methods (Static, Access=public)
    end
    
end
