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

classdef Stage < handle
    %Stage Defines a set of variables to produce a sequence of configurations.
    % 
    
    properties
        evaluator
        schedule
        
        record_attributes
        identifier
        prefix
        
        command_paths
    end
    
    properties (SetAccess=private)
        evaluations
        records
    end
     
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
        attributes_
    end
    
    methods
        
        function obj = Stage(identifier)
            
            obj.identifier = identifier;
            obj.attributes_ = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            obj.evaluator = hdng.experiments.Evaluator.empty;
            obj.schedule = hdng.experiments.Schedule.empty;
            obj.evaluations = [];
            obj.records = [];
            obj.record_attributes = hdng.experiments.RecordAttributeMap();
            obj.prefix = '';
            
            obj.command_paths = {};
            
            stage_attribute = obj.record_attributes.define('result.duration');
            stage_attribute.description = 'Runtime';
            
            stage_attribute = obj.record_attributes.define('configuration.stage_random_seed');
            stage_attribute.description = 'Stage Random Seed';
            
            stage_attribute = obj.record_attributes.define('configuration.study_random_seed');
            stage_attribute.description = 'Study Random Seed';
            
            stage_attribute = obj.record_attributes.define(['result.' hdng.experiments.Schedule.EXPERIMENT_URL]);
            stage_attribute.description = 'Experiment URL';
        end
        
        function result = count_expected_experiments(obj, constants)
            
            result = 0;
            
            iterator = obj.schedule.iterate_configurations(constants);
            
            while true
                
                [is_valid, ~] = iterator.next();
                
                if ~is_valid
                    break;
                end
                
                result = result + 1;
            end
        end
        
        function execute(obj, directory, options)
            
            if isempty(obj.evaluator)
                return
            end
            
            if isempty(obj.schedule)
                return
            end
            
            if isempty(directory)
                return
            end
            
            directory = hdng.utilities.make_absolute_path(directory);
            
            if ~isfield(options, 'is_rehearsal')
                options.is_rehearsal = false;
            end
            
            if ~isfield(options, 'random_seed')
                options.random_seed = cast(randi(2^31, 1), 'uint32');
            end
            
            if ~isfield(options, 'canonical_base_path')
                options.canonical_base_path = directory;
            end
            
            if ~isfield(options, 'source_ref')
                options.source_ref = '';
            end
            
            constants = struct();
            constants.stage_random_seed = hdng.experiments.Value.from(options.random_seed);
            
            if isfield(options, 'study_random_seed')
                constants.study_random_seed = hdng.experiments.Value.from(options.study_random_seed);
            end
            
            variables = obj.schedule.variables;
            
            for index=1:numel(variables)
                variable = variables{index};
                attribute = obj.record_attributes.define(['configuration.' variable.identifier], true);
                attribute.attachments.interactive = variable.interactive;
                attribute.description = variable.description;
            end
            
            format = hdng.experiments.JSONFormat();
            
            N = obj.count_expected_experiments(constants);
            
            progress_path = [directory filesep obj.prefix 'progress'];
            
            iterator = obj.schedule.iterate_configurations(constants);
            
            while true
                
                [is_valid, configuration] = iterator.next();
                
                if ~is_valid
                    break;
                end
                
                fprintf('=== Configuration %d out of %d in current stage === \n', configuration.number, N);
                
                hdng.utilities.save_text(sprintf('%d:%d\n', configuration.number, N), progress_path);
            
                hdng.experiments.Stage.update_current_configuration(configuration, N, directory);
                
                evaluation = hdng.experiments.Evaluation();
                
                evaluation.configuration = configuration;
                evaluation.directory = sprintf('%s%s%s%d', directory, filesep, obj.prefix, configuration.number);
                evaluation.canonical_base_path = options.canonical_base_path;
                evaluation.source_ref = options.source_ref;
                
                obj.evaluations = [obj.evaluations {evaluation}];
                
                obj.evaluator.apply(evaluation, options);

                canonical_directory = evaluation.canonical_path(evaluation.directory);
                canonical_url = matlab.net.URI(canonical_directory).EncodedURI;
                evaluation.results(hdng.experiments.Schedule.EXPERIMENT_URL) = ...
                    hdng.experiments.Value.from(canonical_url, canonical_directory, canonical_url, 'builtin.url');
                
                record = hdng.utilities.Dictionary();
                
                keys = configuration.values.keys();
                
                for index=1:numel(keys)
                    key = keys{index};
                    record(['configuration.' key]) = configuration.values(key);
                end
                
                keys = evaluation.results.keys();
                
                for index=1:numel(keys)
                    key = keys{index};
                    record(['result.' key]) = evaluation.results(key);
                end
                
                obj.records = [obj.records {record}];
                
                file_name = 'record.json';
                file_path = fullfile(evaluation.directory, file_name);
                
                record_text = hdng.utilities.encode_json(record);
                hdng.utilities.save_text(record_text, file_path);
                
                record_proxy = format.build_proxy_from_records({record}, obj.record_attributes);
                record_text = hdng.utilities.encode_json(record_proxy);
                record_text = hdng.utilities.compress_text(record_text);
                record_text = matlab.net.base64encode(record_text);
                
                file_name = 'record.json.gz';
                file_path = fullfile(evaluation.directory, file_name);
                hdng.utilities.save_text(record_text, file_path);
                
                if evaluation.results.holds_key('command_paths')
                    evaluation_command_paths = evaluation.results('command_paths');
                else
                    evaluation_command_paths = hdng.experiments.Value.from('');
                end
                
                if ~isempty(evaluation_command_paths.content)
                    obj.command_paths = [obj.command_paths; evaluation_command_paths.content];
                end
            end
            
            result_attributes = obj.evaluator.result_attributes.attributes;

            for index=1:numel(result_attributes)
                evaluator_attribute = result_attributes{index};
                stage_attribute = obj.record_attributes.define(['result.' evaluator_attribute.identifier]);
                stage_attribute.attachments = evaluator_attribute.attachments;
                stage_attribute.description = evaluator_attribute.description;
            end
            
            configuration_attributes = obj.evaluator.configuration_attributes.attributes;
            
            for index=1:numel(configuration_attributes)
                evaluator_attribute = configuration_attributes{index};
                stage_attribute = obj.record_attributes.define(['configuration.' evaluator_attribute.identifier]);
                stage_attribute.attachments = evaluator_attribute.attachments;
                stage_attribute.description = evaluator_attribute.description;
            end
            
            hdng.utilities.delete(false, progress_path);
        end
        
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
        
        function previous_state = update_current_configuration(configuration, N, directory)
            
            global state
            
            if isempty(state)
                previous_state = [];
            else
                previous_state = state;
            end
            
            if exist('configuration', 'var')
                state = hdng.one_struct('configuration', configuration, 'N', N, 'directory', directory);
            end
        end
        
    end
    
end
