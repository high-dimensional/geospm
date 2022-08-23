% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2019,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef SPMSession < handle
    
    %SPMSession
    
    properties (Constant)
        cluster_csv_file_pattern = '^spm_.+_([0-9]+)\.csv$';
    end
    
    properties (GetAccess=public, SetAccess=private)
        path % character array ? Path to SPM.mat
    end
    
    properties (Dependent, Transient)
        variables
        
        spm_id
        directory
        regression_mask_file
        regression_y_files
        regression_x_names
        regression_beta_files
        regression_residual_sum_of_squares_file
        resels_per_voxel_file
        
        contrast_statistics % A cell array of statistic names such as 'T' or 'F'.
        
        N_contrasts % The total number of contrasts. This corresponds to
                    % all contrast records in xCon with a unique Vcon file.
                    % If F and t statistics were computed, then each
                    % "conceptual" contrast corresponds to two actual
                    % contrasts, as the t statistic is computed from
                    % a linear combination of the betas, whereas the F
                    % statistic is computed from the extra sum of squares.
        
        contrast_names % For each of the N_contrasts, a user supplied name.
                       % Might contain duplicates, see above.
                       
        contrast_files % For each of the N_contrasts, a path to the unique
                       % contrast file.
                       
        contrast_definitions % For each of the N_contrasts, a vector or matrix.
                             % Might contain duplicates, see above.
        
        contrast_map_files % For each of the N_contrasts, a path to the unique
                           % statistic map file.
                           
        contrast_map_statistics
    end
    
    properties (GetAccess=protected, SetAccess=protected, Transient, Dependent)
        contrast_records
    end
    
    properties (GetAccess=private, SetAccess=private)
        variables_
    end
    
    
    
    methods
        
        function obj = SPMSession(path)
            obj.path = path;
            obj.variables_ = [];
        end
        
        function result = get.variables(obj)
            
            if isempty(obj.variables_)
                container = load(obj.path);
                obj.variables_ = container.SPM;
            end
            
            result = obj.variables_;
        end
        
        function result = get.spm_id(obj)
            
            result = '';
            
            if ~isfield(obj.variables, 'SPMid') || ~ischar(obj.variables.SPMid)
                return
            end
            
            result = obj.variables.SPMid;
        end
        
        function result = get.directory(obj)
            
            result = '';
            
            if ~isfield(obj.variables, 'swd') || ~ischar(obj.variables.swd)
                return
            end
            
            result = obj.variables.swd;
        end
        
        function result = get.regression_mask_file(obj)
            
            result = '';
            
            if ~isfield(obj.variables, 'VM') || ~isstruct(obj.variables.VM)
                return
            end
            
            if ~isfield(obj.variables.VM, 'fname') || ~ischar(obj.variables.VM.fname)
                return
            end
            
            result = obj.make_absolute_path(obj.variables.VM.fname);
        end
        
        function result = get.regression_x_names(obj)
            
            result = {};
            
            if ~isfield(obj.variables, 'xX') || ~isstruct(obj.variables.xX)
                return
            end
            
            if ~isfield(obj.variables.xX, 'name') || ~iscell(obj.variables.xX.name)
                return
            end
            
            N = numel(obj.variables.xX.name);
            result = cell(N, 1);
            
            for i=1:N
                name = obj.variables.xX.name{i};
                result{i} = name;
            end
        end
        
        function result = get.regression_y_files(obj)
            
            result = {};
            
            if ~isfield(obj.variables, 'xY') || ~isstruct(obj.variables.xY)
                return
            end
            
            if ~isfield(obj.variables.xY, 'P') || ~iscell(obj.variables.xY.P)
                return
            end
            
            N = numel(obj.variables.xY.P);
            result = cell(N, 1);
            
            for i=1:N
                y_path = obj.variables.xY.P{i};
                result{i} = obj.make_absolute_path(y_path);
            end
        end
        
        function result = get.regression_beta_files(obj)
            
            result = {};
            
            if ~isfield(obj.variables, 'Vbeta') || ~isstruct(obj.variables.Vbeta)
                return
            end
            
            N = numel(obj.variables.Vbeta);
            result = cell(N, 1);
            
            for i=1:N
                volume = obj.variables.Vbeta(i);
                result{i} = obj.make_absolute_path(volume.fname);
            end
        end
        
        function result = get.regression_residual_sum_of_squares_file(obj)
            
            result = '';
            
            if ~isfield(obj.variables, 'VResMS') || ~isstruct(obj.variables.VResMS)
                return
            end
            
            if ~isfield(obj.variables.VResMS, 'fname') || ~ischar(obj.variables.VResMS.fname)
                return
            end
            
            result = obj.make_absolute_path(obj.variables.VResMS.fname);
        end
        
        function result = get.resels_per_voxel_file(obj)
            
            result = '';
            
            if ~isfield(obj.variables, 'xVol') || ~isstruct(obj.variables.xVol)
                return
            end
            
            if ~isfield(obj.variables.xVol, 'VRpv') || ~isstruct(obj.variables.xVol.VRpv)
                return
            end
            
            if ~isfield(obj.variables.xVol.VRpv, 'fname') || ~ischar(obj.variables.xVol.VRpv.fname)
                return
            end
            
            result = obj.make_absolute_path(obj.variables.xVol.VRpv.fname);
        end
        
        
        function result = get.contrast_records(obj)
            
            result = [];
            
            if ~isfield(obj.variables, 'xCon') || ~isstruct(obj.variables.xCon)
                return
            end
            
            result = obj.variables.xCon;
        end
        
        
        function result = get.N_contrasts(obj)
            result = numel(obj.contrast_names);
        end
        
        function result = get.contrast_names(obj)
            
            [select, expected_fields] = geospm.spm.SPMSession.select_unique_contrast_function();
            expected_fields{end + 1} = 'name';
            result = obj.select_and_map_contrast_records(select, @(record, ~) record.name, expected_fields);
        end
        
        function result = get.contrast_files(obj)
            [select, expected_fields] = geospm.spm.SPMSession.select_unique_contrast_function();
            result = obj.select_and_map_contrast_records(select, @(record, ~) obj.make_absolute_path(record.Vcon.fname), expected_fields);
        end
        
        function result = get.contrast_definitions(obj)
            
            [select, expected_fields] = geospm.spm.SPMSession.select_unique_contrast_function();
            expected_fields{end + 1} = 'c';
            result = obj.select_and_map_contrast_records(select, @(record, ~) record.c, expected_fields);
        end
        
        
        function result = get.contrast_statistics(obj)
            
            unique_stats = containers.Map('KeyType', 'char', 'ValueType', 'logical');
            result = obj.select_and_map_contrast_records(...
                @(record, ~) geospm.spm.SPMSession.insert_unique_key(unique_stats, record.STAT, 1), ...
                @(record, ~) record.STAT, {'STAT'});
        end
        
        
        function result = get.contrast_map_files(obj)
            
            [select, expected_fields] = geospm.spm.SPMSession.select_unique_contrast_function();
            result = obj.select_and_map_contrast_records(...
                select, ...
                @(record, ~) obj.make_absolute_path(record.Vspm.fname), [expected_fields, {'Vspm'}]);
        end
        
        
        function result = get.contrast_map_statistics(obj)
            
            [select, expected_fields] = geospm.spm.SPMSession.select_unique_contrast_function();
            result = obj.select_and_map_contrast_records(...
                select, ...
                @(record, ~) record.STAT, [expected_fields, {'STAT'}]);
        end
        
        function delete_contrasts(obj)
            
            contrast_file_paths = obj.contrast_files;
            map_file_paths = obj.contrast_map_files;
            spm_path = obj.path;
            [spm_directory, spm_name, spm_ext] = fileparts(spm_path);
            spm_path_old = fullfile(spm_directory, [spm_name '_' char(obj.now()) spm_ext]);
            
            obj.variables_ = rmfield(obj.variables, 'xCon');
            obj.variables_.xCon = [];
            
            movefile(spm_path, spm_path_old);
            
            SPM = obj.variables_;
            save(spm_path, 'SPM');
            
            obj.variables_ = [];
            
            for index=1:numel(contrast_file_paths)
                file_path = contrast_file_paths{index};
                hdng.utilities.delete(false, file_path);
            end
            
            for index=1:numel(map_file_paths)
                file_path = map_file_paths{index};
                hdng.utilities.delete(false, file_path);
            end
            
            hdng.utilities.delete(true, spm_path_old);
        end
        
        function result = select_and_map_contrast_records(obj, select_function, mapping_function, expected_record_fields)
            
            if ~isa(select_function, 'function_handle')
                error('SPMSession.select_contrast_records(): Argument ''select_function'' must be a function handle.');
            end
            
            if ~isa(mapping_function, 'function_handle')
                error('SPMSession.select_contrast_records(): Argument ''mapping_function'' must be a function handle.');
            end
            
            if ~exist('expected_record_fields', 'var')
                expected_record_fields = {};
            end
            
            records = obj.contrast_records;
            
            for i=1:numel(expected_record_fields)
                name = expected_record_fields{i};
                
                if ~isfield(records, name)
                    error(['SPMSession.select_contrast_records(): Contrast records are missing field ''' name '''.']);
                end
            end
            
            result = cell(numel(records), 1);
            N_results = 0;
            
            for i=1:numel(records)
                
                record = records(i);
                
                if select_function(record, i)
                    N_results = N_results + 1;
                    result{N_results} = mapping_function(record, i);
                end
            end
            
            result = result(1:N_results);
        end
        
        function result = contrast_names_for_statistic(obj, statistic)
            
            [select, expected_fields] = geospm.spm.SPMSession.select_unique_contrast_function(statistic);
            expected_fields{end + 1} = 'name';
            result = obj.select_and_map_contrast_records(select, @(record, ~) record.name, expected_fields);
        end
        
        function result = contrast_indices_for_statistic(obj, statistic)
            
            [select, expected_fields] = geospm.spm.SPMSession.select_unique_contrast_function(statistic);
            result = obj.select_and_map_contrast_records(select, @(record, index) index, expected_fields);
        end
        
        
        function result = contrast_indices_for_contrast_paths(obj, contrast_paths)
            
            contrast_path_map = containers.Map('KeyType', 'char', 'ValueType', 'int64');
            contrasts = obj.contrast_files;
            
            for index=1:numel(contrasts)
                contrast_path = contrasts{index};
                contrast_path_map(contrast_path) = index;
            end
            
            result = zeros(numel(contrast_paths), 1);
            
            for index=1:numel(contrast_paths)
                contrast_path = contrast_paths{index};
                contrast_path = obj.make_absolute_path(contrast_path);
                
                if isKey(contrast_path_map, contrast_path)
                    contrast_index = contrast_path_map(contrast_path);
                else
                    contrast_index = 0;
                end
                
                result(index) = contrast_index;
            end
        end
        
        function result = contrast_files_for_statistic(obj, statistic)
            
            [select, expected_fields] = geospm.spm.SPMSession.select_unique_contrast_function(statistic);
            result = obj.select_and_map_contrast_records(select, @(record, ~) obj.make_absolute_path(record.Vcon.fname), expected_fields);
        end
        
        function result = contrast_definitions_for_statistic(obj, statistic)
            
            [select, expected_fields] = geospm.spm.SPMSession.select_unique_contrast_function(statistic);
            expected_fields{end + 1} = 'c';
            result = obj.select_and_map_contrast_records(select, @(record, ~) record.c, expected_fields);
        end
        
        function result = statistic_map_files_for(obj, statistic)
            
            [select, expected_fields] = geospm.spm.SPMSession.select_unique_contrast_function(statistic);
            expected_fields{end + 1} = 'Vspm';
            result = obj.select_and_map_contrast_records(select, @(record, ~) obj.make_absolute_path(record.Vspm.fname), expected_fields);
        end
        
        function [did_match_all, result, unmatched_contrasts, unmatched_associated] = cluster_csv_files_for(obj, statistic, directory)
            
            if ~exist('directory', 'var')
                directory = obj.directory;
            end
            
            [did_match_all, result, unmatched_contrasts, unmatched_associated] = ...
                obj.files_associated_with_statistic_for(statistic, obj.cluster_csv_file_pattern, directory);
        end
        
        function [did_match_all, result, unmatched_contrasts, unmatched_associated] = statistic_threshold_files_for(obj, statistic, directory)
            
            if ~exist('directory', 'var')
                directory = obj.directory;
            end
            
            name_pattern = ['^spm' statistic '_([0-9]+)_mask\.nii$'];
            [did_match_all, result, unmatched_contrasts, unmatched_associated] = ...
                obj.files_associated_with_statistic_for(statistic, name_pattern, directory);
        end
        
        function [did_match_all, result, unmatched_contrasts, unmatched_associated] = statistic_set_csv_files_for(obj, statistic, directory)
            
            if ~exist('directory', 'var')
                directory = obj.directory;
            end
            
            name_pattern = ['^spm' statistic '_set_p_values_([0-9]+)\.csv$'];
            [did_match_all, result, unmatched_contrasts, unmatched_associated] = ...
                obj.files_associated_with_statistic_for(statistic, name_pattern, directory);
        end
        
        function [did_match_all, result, unmatched_contrasts, unmatched_associated] = statistic_cluster_csv_files_for(obj, statistic, directory)
            
            if ~exist('directory', 'var')
                directory = obj.directory;
            end
            
            name_pattern = ['^spm' statistic '_cluster_p_values_([0-9]+)\.csv$'];
            [did_match_all, result, unmatched_contrasts, unmatched_associated] = ...
                obj.files_associated_with_statistic_for(statistic, name_pattern, directory);
        end
        
        function [did_match_all, result, unmatched_contrasts, unmatched_associated] = statistic_peak_csv_files_for(obj, statistic, directory)
            
            if ~exist('directory', 'var')
                directory = obj.directory;
            end
            
            name_pattern = ['^spm' statistic '_peak_p_values_([0-9]+)_z([0-9]+)\.csv$'];
            [did_match_all, result, unmatched_contrasts, unmatched_associated] = ...
                obj.files_associated_with_statistic_for(statistic, name_pattern, directory);
        end
        
        
        function [result, matched_statistics] = match_beta_coeff_threshold_files(~, directory, N_real_contrasts)
            
            result = struct();
            
            name_pattern = '^beta_([0-9]+)_mask\.nii$';
            [file_paths, file_tokens] = hdng.utilities.scan_files(directory, name_pattern);
            
            result.did_match_all_files = true;
            result.matched_files = file_paths;
            result.matched_contrasts = zeros(numel(file_paths), 1);
            result.unmatched_files = {};
            result.unmatched_contrasts = [];
            
            for i=1:numel(file_paths)
                file_token = file_tokens{i};
                result.matched_contrasts(i) = N_real_contrasts + str2double(file_token{1});
            end
            
            matched_statistics = {'beta_coeff'};
        end
        
        function [match_result, matched_statistics] = match_pseudo_statistic_threshold_files(obj, statistics, directory)
            
            if ~exist('directory', 'var')
                directory = obj.directory;
            end
            
            name_pattern_for = @(stat) ['^' stat '_([0-9]+)_mask\.nii$'];
            
            [match_result, matched_statistics] = obj.files_associated_with_statistics_for(statistics, name_pattern_for, directory);
        end
        
        function [match_result, matched_statistics] = match_statistic_threshold_files(obj, statistic, directory, prefix)
            
            if ~exist('directory', 'var')
                directory = obj.directory;
            end
            
            if ~exist('prefix', 'var')
                prefix = 'spm';
            end
            
            if isempty(statistic)
                statistics = obj.contrast_statistics;
            else
                statistics = { statistic };
            end
            
            name_pattern_for = @(stat) ['^' prefix stat '_([0-9]+)_mask\.nii$'];
            
            [match_result, matched_statistics] = obj.files_associated_with_statistics_for(statistics, name_pattern_for, directory);
        end
        
        
        function [matched_files, matched_pairs, matched_statistics] = match_statistic_paired_threshold_files(obj, statistic, directory)
            
            if ~exist('directory', 'var')
                directory = obj.directory;
            end
            
            if isempty(statistic)
                statistics = obj.contrast_statistics;
            else
                statistics = { statistic };
            end
            
            matched_statistics = [];
            file_table = [];
            
            for index=1:numel(statistics)
                stat = statistics{index};
                
                name_pattern = ['^spm' stat '_([0-9]+)_([0-9]+)_mask\.nii$'];

                %Scan the directory for files matching the name pattern
                [file_paths, file_tokens] = hdng.utilities.scan_files(directory, name_pattern);
                
                left_numbers = cellfun(@(x) {str2double(x{1}{1})}, file_tokens, 'UniformOutput', 1);
                right_numbers = cellfun(@(x) {str2double(x{1}{2})}, file_tokens, 'UniformOutput', 1);
                
                if ~isempty(file_paths)
                    matched_statistics = [matched_statistics; {stat}]; %#ok<AGROW>
                    file_table = [file_table; [file_paths, left_numbers, right_numbers]]; %#ok<AGROW>
                end
                
            end
            
            matched_files = [];
            matched_pairs = [];

            if size(file_table, 1) > 0
                file_table = sortrows(file_table, [2, 3]);
                matched_files = file_table(:, 1);
                matched_pairs = cell2mat(file_table(:, 2:3));
            end
        end
        
        
        function [match_result, matched_statistics] = match_statistic_set_csv_files(obj, statistic, directory)
            
            if ~exist('directory', 'var')
                directory = obj.directory;
            end
            
            if isempty(statistic)
                statistics = obj.contrast_statistics;
            else
                statistics = { statistic };
            end
            
            name_pattern_for = @(stat) ['^spm' stat '_set_p_values_([0-9]+)\.csv$'];
            [match_result, matched_statistics] = obj.files_associated_with_statistics_for(statistics, name_pattern_for, directory);
        end
        
        function [match_result, matched_statistics] = match_statistic_cluster_csv_files(obj, statistic, directory)
            
            if ~exist('directory', 'var')
                directory = obj.directory;
            end
            
            if isempty(statistic)
                statistics = obj.contrast_statistics;
            else
                statistics = { statistic };
            end
            
            name_pattern_for = @(stat) ['^spm' stat '_cluster_p_values_([0-9]+)\.csv$'];
            [match_result, matched_statistics] = obj.files_associated_with_statistics_for(statistics, name_pattern_for, directory);
        end
        
        function [match_result, matched_statistics] = match_statistic_peak_csv_files(obj, statistic, directory)
            
            if ~exist('directory', 'var')
                directory = obj.directory;
            end
            
            if isempty(statistic)
                statistics = obj.contrast_statistics;
            else
                statistics = { statistic };
            end
            
            name_pattern_for = @(stat) ['^spm' stat '_peak_p_values_([0-9]+)\.csv$'];
            [match_result, matched_statistics] = obj.files_associated_with_statistics_for(statistics, name_pattern_for, directory);
        end
        
        
        function [match_result, matched_statistics] = files_associated_with_statistics_for(obj, statistics, name_pattern_for_statistic, target_directory)
            
            match_result = obj.create_file_match_struct();
            matched_statistics = {};
            
            for index=1:numel(statistics)
                
                statistic = statistics{index};
                name_pattern = name_pattern_for_statistic(statistic);
                
                stat_result = obj.files_associated_with_statistic_for_v2(statistic, name_pattern, target_directory);
                
                if ~isempty(stat_result.matched_files)
                    matched_statistics = [matched_statistics; {statistic}]; %#ok<AGROW>
                end
                
                match_result = obj.disjoint_union_of_file_matches(match_result, stat_result);
            end
        end
        
        
        function result = create_file_match_struct(~)
            result = struct();
            
            result.did_match_all_files = true;
            
            result.matched_files = {};
            result.matched_contrasts = [];
            
            result.unmatched_files = {};
            result.unmatched_contrasts = [];
        end
        
        
        function result = disjoint_union_of_file_matches(obj, match1, match2)
            result = obj.create_file_match_struct();
            
            result.matched_files = [match1.matched_files; match2.matched_files];
            result.unmatched_files = [match1.unmatched_files; match2.unmatched_files];
            
            result.matched_contrasts = [match1.matched_contrasts; match2.matched_contrasts];
            result.unmatched_contrasts = [match1.unmatched_contrasts; match2.unmatched_contrasts];
            
            result.did_match_all_files = isempty(result.unmatched_files);
        end
        
        function result = files_associated_with_statistic_for_v2(obj, statistic, name_pattern, target_directory)
            
            matched_contrasts = [];
            unmatched_contrasts = [];
            unmatched_files = {};
            
            file_map = containers.Map('KeyType', 'double', 'ValueType', 'any');
            
            %Scan the directory for files matching the name pattern
            [file_paths, file_tokens] = hdng.utilities.scan_files(target_directory, name_pattern);
            
            %For each file, extract the numeric token uniquely specifying the
            %contrast
            file_tokens = cellfun(@(x) x{1}, file_tokens, 'UniformOutput', 1);
            %Map the file paths by the value of their numeric token
            obj.map_files_by_number(file_paths, file_tokens, file_map);
            
            target_file_paths = file_paths;
            
            N_results = 0;
            matched_files = cell(numel(file_paths), 1);
            
            %Get the statistic map volumes associated with the specified statistic
            file_paths = obj.statistic_map_files_for(statistic);
            
            [file_paths, file_tokens] = hdng.utilities.match_file_paths_by_name(file_paths, ['^spm' statistic '_([0-9]+)\.nii$']);
            
            %For each file, extract the numeric token uniquely specifying the
            %contrast
            file_tokens = cellfun(@(x) x{1}, file_tokens, 'UniformOutput', 1);
            %Map the file paths by the value of their numeric token
            obj.map_files_by_number(file_paths, file_tokens, file_map);
            
            %At this stage file_map should have a key for each contrast of
            %the specified statistic, and the entry for each key should
            %hold two files: One file from the target directory matching
            %the name pattern, and one file specifying the corresponding
            %statistic map, where both files are linked to the same
            %contrast. The first file is in the target_directory,
            % the second file is in the session output directory.
            
            contrast_indices = keys(file_map);
            contrast_indices = sortrows(contrast_indices(:));
            
            for i=1:numel(contrast_indices)
                contrast_index = contrast_indices{i};
                entry = file_map(contrast_index);
                k = numel(entry);
                
                if k == 2
                    
                    N_results = N_results + 1;
                    
                    matched_files{N_results, 1} = entry{1};
                    matched_contrasts(end + 1) = contrast_index; %#ok<AGROW>
                    
                else % k == 1
                    
                    [entry_1_directory, entry_1, ext] = fileparts(entry{1}); entry_1 = [entry_1 ext]; %#ok<AGROW>
                    is_associated_1 = ~isempty(regexp(entry_1, name_pattern, 'start'));
                    
                    if is_associated_1 && strcmp(entry_1_directory, target_directory)
                        unmatched_files{end + 1} = entry{1}; %#ok<AGROW>
                    else
                        unmatched_contrasts(end + 1) = contrast_index; %#ok<AGROW>
                    end
                end
            end
            
            result = obj.create_file_match_struct();
            
            result.did_match_all_files = N_results == numel(target_file_paths);
            result.matched_files = matched_files(1:N_results);
            result.unmatched_files = unmatched_files(:);
            result.matched_contrasts = matched_contrasts(:);
            
            result.unmatched_contrasts = unmatched_contrasts(:);
        end
        
        
        function [did_match_all, result, unmatched_contrasts, unmatched_associated] = files_associated_with_statistic_for(obj, statistic, name_pattern, target_directory)
            
            unmatched_contrasts = {};
            unmatched_associated = {};
            
            file_map = containers.Map('KeyType', 'double', 'ValueType', 'any');
            
            %Scan the directory for files matching the name pattern
            [file_paths, file_tokens] = hdng.utilities.scan_files(target_directory, name_pattern);
            
            %For each file, extract the numeric token uniquely specifying the
            %contrast
            file_tokens = cellfun(@(x) x{1}, file_tokens, 'UniformOutput', 1);
            %Map the file paths by the value of their numeric token
            obj.map_files_by_number(file_paths, file_tokens, file_map);
            
            N_results = 0;
            result = cell(numel(file_paths), 1);
            
            %Get the statistic map volumes associated with the specified statistic
            file_paths = obj.statistic_map_files_for(statistic);
            
            [file_paths, file_tokens] = hdng.utilities.match_file_paths_by_name(file_paths, ['^spm' statistic '_([0-9]+)\.nii$']);
            
            %For each file, extract the numeric token uniquely specifying the
            %contrast
            file_tokens = cellfun(@(x) x{1}, file_tokens, 'UniformOutput', 1);
            %Map the file paths by the value of their numeric token
            obj.map_files_by_number(file_paths, file_tokens, file_map);
            
            %At this stage file_map should have a key for each contrast of
            %the specified statistic, and the entry for each key should
            %hold two files: One file from the target directory matching
            %the name pattern, and one file specifying the corresponding
            %statistic map, where both files are linked to the same
            %contrast.
            
            file_numbers = keys(file_map);
            
            for i=1:numel(file_numbers)
                file_number = file_numbers{i};
                entry = file_map(file_number);
                k = numel(entry);
                
                if k == 2
                    % We need to ensure that for each key we identify the
                    % unique entry matching the name pattern
                    [~, entry_1, ext] = fileparts(entry{1}); entry_1 = [entry_1 ext]; %#ok<AGROW>
                    [~, entry_2, ext] = fileparts(entry{2}); entry_2 = [entry_2 ext]; %#ok<AGROW>
                    
                    is_associated_1 = ~isempty(regexp(entry_1, name_pattern, 'start'));
                    is_associated_2 = ~isempty(regexp(entry_2, name_pattern, 'start'));
                    
                    if is_associated_1 == is_associated_2

                        if is_associated_1
                            unmatched_associated{end + 1} = entry{1}; %#ok<AGROW>
                            unmatched_associated{end + 1} = entry{2}; %#ok<AGROW>
                        else
                            unmatched_contrasts{end + 1} = entry{1}; %#ok<AGROW>
                            unmatched_contrasts{end + 1} = entry{2}; %#ok<AGROW>
                        end
                        
                        continue
                    end
                    
                    N_results = N_results + 1;
                    
                    if is_associated_1
                        result{N_results, 1} = entry{1};
                    else
                        result{N_results, 1} = entry{2};
                    end
                    
                else % k == 1
                    
                    [~, entry_1, ext] = fileparts(entry{1}); entry_1 = [entry_1 ext]; %#ok<AGROW>
                    is_associated_1 = ~isempty(regexp(entry_1, name_pattern, 'start'));
                    
                    if is_associated_1
                        unmatched_associated{end + 1} = entry{1}; %#ok<AGROW>
                    else
                        unmatched_contrasts{end + 1} = entry{1}; %#ok<AGROW>
                    end
                end
            end
            
            did_match_all = N_results == numel(file_paths);
            result = result(1:N_results);
        end
        
        function result = make_absolute_path(obj, path)
            
            [parent, ~, ~] = fileparts(path);
            
            if numel(parent) == 0
                result = fullfile(obj.directory, path);
            else
                result = path;
            end
        end
        
        
        function result = make_relative_path(obj, local_path)
            
            prefix = obj.directory;
            
            if startsWith(local_path, prefix)
                result = local_path(numel(prefix)+numel(filesep)+1:end);
            else
                result = local_path;
            end
        end
    end
    
    methods (Static, Access=private)
        
        function result = now()
            result = datetime('now', 'TimeZone', 'local', 'Format', 'yyyy_MM_dd_HH.mm.ss.SSS');
        end
        
        function result = insert_unique_key(map, key, value)
            
            if isKey(map, key)
                result = false;
                return;
            end
            
            result = true;
            map(key) = value; %#ok<NASGU>
        end
        
        function [result, expected_fields] = select_unique_contrast_function(optional_statistic)
        
            if ~exist('optional_statistic', 'var')
                optional_statistic = '';
            end
            
            state = struct();
            state.statistic = optional_statistic;
            state.unique_files = containers.Map('KeyType', 'char', 'ValueType', 'logical');
            
            expected_fields = {'Vcon'};
            result = @(record, ~) geospm.spm.SPMSession.select_contrast_record(record, state);
        end
        
        function result = select_contrast_record(record, state)

            result = false;
            
            if numel(state.statistic) > 0 && ~strcmp(record.STAT, state.statistic)
                return;
            end
            
            if ~isstruct(record.Vcon) || ~isfield(record.Vcon, 'fname') || ~ischar(record.Vcon.fname)
                warning('SPMSession.select_contrast_record(): Contrast record field Vcon is either not a struct or doesn''t have a char field ''fname''.');
                return;
            end
            
            file_name = record.Vcon.fname;

            if ~isKey(state.unique_files, file_name)
                state.unique_files(file_name) = true;
                result = true;
                return;
            end
        end
        
        function map_files_by_number(file_paths, file_numbers, file_map)
            
            for i=1:numel(file_paths)
                
                file_path = file_paths{i};
                file_number = file_numbers{i};
                
                if ischar(file_number)
                    file_number = str2double(file_number);
                end
                
                if ~isKey(file_map, file_number)
                    entry = cell(0, 1);
                else
                    entry = file_map(file_number);
                end
                
                entry{end + 1} = file_path; %#ok<AGROW>
                file_map(file_number) = entry;
            end
        end
    end
end
