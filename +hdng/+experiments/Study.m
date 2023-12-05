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

classdef Study < handle
    %Study .
    % 
    
    properties
        strategy
        prefix
        name
        attachments
    end
    
    properties (SetAccess=private)
        completed_stages
        records
        record_attributes
        command_paths
    end
     
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = Study()
            obj.name = '';
            obj.prefix = '';
            obj.strategy = [];
            obj.completed_stages = {};
            obj.records = {};
            obj.record_attributes = hdng.experiments.RecordAttributeMap();
            obj.attachments = struct();
            obj.command_paths = {};


            attribute = obj.record_attributes.define('stage');
            attribute.description = 'Stage';

            attribute = obj.record_attributes.define('stage_index');
            attribute.description = 'Stage Index';
        end
        
        function result = canonical_path(~, base_path, local_path)
            
            path_prefix = base_path;
            
            if startsWith(local_path, path_prefix)
                result = local_path(numel(path_prefix)+numel(filesep)+1:end);
            else
                result = local_path;
            end
        end
        
        function result = absolute_path(~, base_path, local_path)
            
            path_prefix = filesep;
            
            if ~startsWith(local_path, path_prefix)
                result = [base_path filesep local_path];
            else
                result = local_path;
            end
        end
        
        function directory_path = execute(obj, directory_path, options)
            
            if numel(directory_path) == 0
                directory_path = pwd;
            end
            
            if ~exist('options', 'var')
                options = struct();
            end
            
            directory_path = hdng.utilities.make_absolute_path(directory_path);
            
            if ~isfield(options, 'is_rehearsal')
                options.is_rehearsal = false;
            end
            
            if ~isfield(options, 'random_seed')
                options.random_seed = cast(randi(2^31, 1), 'uint32');
            end
            
            if ~isfield(options, 'canonical_base_path')
                options.canonical_base_path = directory_path;
            elseif numel(options.canonical_base_path) == 0
                options.canonical_base_path = directory_path;
            end
            
            if ~isfield(options, 'source_ref')
                options.source_ref = '';
            end
            
            options.canonical_base_path = hdng.utilities.make_absolute_path(options.canonical_base_path);
            
            if ~isfield(options, 'no_stage_path')
                options.no_stage_path = true;
            end
            
            random_state = RandStream('mt19937ar', 'Seed', options.random_seed);
            
            stage_iterator = obj.strategy.iterate_stages(obj);
            
            index = 1;
            
            while true
                
                [is_valid, stage] = stage_iterator.next();
                 
                if ~is_valid
                    break;
                end
                
                stage_options = struct();
                stage_options.is_rehearsal = options.is_rehearsal;
                stage_options.random_seed = cast(random_state.randi(2^31, 1), 'uint32');
                stage_options.study_random_seed = options.random_seed;
                stage_options.canonical_base_path = options.canonical_base_path;
                stage_options.source_ref = options.source_ref;
                
                if options.no_stage_path
                    subdirectory_path = directory_path;
                else
                    subdirectory_path = sprintf('%s%s%s%s', directory_path, filesep, obj.prefix, stage.identifier);
                end
                
                stage.execute(subdirectory_path, stage_options);
                
                for record_index=1:numel(stage.records)
                    record = stage.records{record_index}.copy();
                    record('stage_index') = hdng.experiments.Value.from(cast(index, 'int64'), sprintf('%d', cast(index, 'int64')));
                    record('stage') = hdng.experiments.Value.from(stage.identifier);
                    obj.records = [obj.records; {record}];
                end
                
                stage_attributes = stage.record_attributes.attributes;

                for index=1:numel(stage_attributes)
                    stage_attribute = stage_attributes{index};
                    study_attribute = obj.record_attributes.define(stage_attribute.identifier);
                    study_attribute.attachments = stage_attribute.attachments;
                    study_attribute.description = stage_attribute.description;
                end
                
                obj.completed_stages = [obj.completed_stages; { stage }];
                
                obj.command_paths = [obj.command_paths; stage.command_paths];
            end
            
            do_compress = true;
            do_base64 = true;
            
            file_name = sprintf('%s%s', obj.prefix, 'records.json');
            
            if do_compress
                file_name = [file_name '.gz'];
            end
            
            file_path = fullfile(directory_path, file_name);
            obj.save_records_as_json(file_path, do_compress, do_base64);
            
            file_name = sprintf('%s%s', obj.prefix, 'debug_records.json');
            file_path = fullfile(directory_path, file_name);
            obj.save_records_as_json(file_path, false, false);
            
            file_name = sprintf('%s%s', obj.prefix, 'command_paths.txt');
            file_path = fullfile(directory_path, file_name);
            obj.save_command_paths(file_path);
            
            file_name = sprintf('%s%s', obj.prefix, 'commands.txt');
            file_path = fullfile(directory_path, file_name);
            obj.save_commands(options.canonical_base_path, file_path);
            
            directory_path = options.canonical_base_path;
        end
        
        function save_command_paths(obj, file_path)
            
            if ~isempty(obj.command_paths)
                text = join(obj.command_paths, newline);
                text = text{1};
            else
                text = newline;
            end
            
            hdng.utilities.save_text(text, file_path);
        end
        
        function save_commands(obj, base_path, file_path)
            
            text = '';
            
            for i=1:numel(obj.command_paths)
                command_path = obj.absolute_path(base_path, obj.command_paths{i});
                command_text = hdng.utilities.load_text(command_path);
                
                if ~endsWith(command_text, newline)
                    command_text = [command_text newline]; %#ok<AGROW>
                end
                
                text = [text command_text]; %#ok<AGROW>
            end
            
            hdng.utilities.save_text(text, file_path);
        end
        
        function save_records_as_json(obj, file_path, compression, base64)
            
            if ~exist('compression', 'var')
                compression = false;
            end
            
            if ~exist('base64', 'var')
                base64 = false;
            end
            
            options = struct();
            options.compression = compression;
            options.base64 = base64;
            
            format = hdng.experiments.JSONFormat();
            
            [parent_directory, ~, ~] = fileparts(file_path);
            
            [dirstatus, dirmsg] = mkdir(parent_directory);
            
            if ~dirstatus
                error(dirmsg);
            end
            
            bytes = format.encode(obj.records, obj.record_attributes, obj.attachments, [], options);
            hdng.utilities.save_bytes(bytes, file_path);
        end
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
