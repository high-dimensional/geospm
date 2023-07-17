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

classdef SPMJobList < handle
    %SPMJobList Summary goes here.
    
    properties (GetAccess=public, SetAccess=private)
        
        directory % character array ? Directory path for storing output.
        
        spm_interface % handle ? Provides access to SPM.
        
        spm_precision % character array ? Numeric precision to be used, either 'single' or 'double'.
        spm_job_list % cell array ? Each element is a struct specifying an SPM job to run together with any other settings.
        
        batch_list %cell array ? Each element is a SPM batch structure.
        batch_indices % struct ? Each field specifies the index of its designated SPM job 
        batch_results
        
        started_at
        stopped_at
        runtime_duration
    end
    
    properties (GetAccess=protected, Dependent, Transient)
        available_spm_jobs
    end
    
    properties (GetAccess=private, SetAccess=private)
        available_spm_jobs_
        spm_jobs_by_identifier_
        did_run
    end
    
    methods
        
        function obj = SPMJobList(...
                         directory, ...
                         spm_precision, ...
                         spm_job_list)
            %Creates a SPMJobList object.
            %
            % The following jobs can be defined:
            %
            % 'factorial_design' Description of a data set as a factorial design. 
            %
            %  The following fields can be specified for a factorial design job:
            %
            %     'observations'    N x P matrix ? Each row of the matrix is an observation of P variables.
            %     'variable_names'  cell array [optional] ? Holds the name for each column of the observation matrix.
            %     'volume_paths'    cell array ? Holds a file path to the Y volume for each observation.
            %
            % 't_contrasts' A set of contrasts to be evaluated by a T statistic.
            %
            % The following fields can be specified for a t contrast job:
            %
            %     'contrasts' cell array [optional] ? A cell array of contrast row vectors. 
            %     'contrast_names' cell array [optional] ? A cell array of contrast names.
            %
            % 'f_contrasts' A set of contrasts to be evaluated by an F statistic.
            %
            % The following fields can be specified for an f contrast job:
            %
            %     'contrasts' cell array [optional] ? A cell array of contrast matrices. 
            %     'contrast_names' cell array [optional] ? A cell array of contrast names.
            %
            
            obj.directory = directory;
            
            obj.spm_precision = spm_precision;
            obj.spm_job_list = spm_job_list;
            
            obj.spm_interface = geospm.spm.SPMJobList.access_spm_interface();
            
            obj.available_spm_jobs_ = [];
            
            [obj.batch_list, obj.batch_indices] = obj.spm_batches_from_job_list();
            obj.batch_results = {};
            
            obj.did_run = false;
        end
        
        function result = get.available_spm_jobs(obj)
            
            if isempty(obj.available_spm_jobs_)
                obj.available_spm_jobs_ = obj.gather_available_spm_jobs();
            end
            
            result = obj.available_spm_jobs_;
        end
        
        function [did_exist, result, result_index] = entry_before(obj, identifier, entry)
            
            did_exist = false;
            result = [];
            result_index = 0;
            
            if ~isKey(obj.spm_jobs_by_identifier_, identifier)
                return
            end
            
            identifier_entry = obj.spm_jobs_by_identifier_(identifier);
            indices = identifier_entry.indices;
            
            for i=numel(indices):-1:1
                
                if indices(i) < entry.index
                    did_exist = true;
                    result = obj.spm_job_list{indices(i)};
                    result_index = indices(i);
                    return;
                end
            end
        end
        
        function [did_exist, result, result_index] = factorial_design_entry_before(obj, entry)
            [did_exist, result, result_index] = obj.entry_before('factorial_design', entry);
        end
        
        function [did_exist, result, result_index] = fmri_model_estimation_entry_before(obj, entry)
            [did_exist, result, result_index] = obj.entry_before('fmri_model_estimation', entry);
        end
        
        function [did_exist, result, result_index] = contrasts_entry_before(obj, entry)
            [t_did_exist, t_result, t_result_index] = obj.entry_before('t_contrasts', entry);
            
            [f_did_exist, f_result, f_result_index] = obj.entry_before('f_contrasts', entry);
            
            if t_did_exist && f_did_exist
                
                did_exist = true;
                    
                if t_result_index > f_result_index
                    result = t_result;
                    result_index = t_result_index;
                else
                    result = f_result;
                    result_index = f_result_index;
                end
            elseif ~t_did_exist && ~f_did_exist
                did_exist = false;
                result = [];
                result_index = 0;
            elseif t_did_exist
                did_exist = true;
                result = t_result;
                result_index = t_result_index;
            else
                did_exist = true;
                result = f_result;
                result_index = f_result_index;
            end
        end
        
        
        function result = batch_result_for_job(obj, identifier)
            
            if ~isfield(obj.batch_indices, identifier)
                error(['geospm.spm.SPMJobList.batch_result_for_job(): No batch entry for job ''' identifier ''' exists.']);
            end
            
            result = obj.batch_results{batch_index};
        end
        
        function run(obj)
            
            if obj.did_run
                error('geospm.spm.SPMJobList.run() cannot be called more than once.');
            end
            
            if exist(obj.directory, 'dir') == 0
                [dirstatus, dirmsg] = mkdir(obj.directory);
                if dirstatus ~= 1; error(dirmsg); end
            end
            
            obj.started_at = obj.now();
            
            obj.batch_results = obj.spm_interface.run_batch_jobs(obj.batch_list);
            
            obj.stopped_at = obj.now();
            obj.runtime_duration = seconds(obj.stopped_at - obj.started_at);
            
            obj.did_run = true;
        end
        
        function result = load_session(obj, session_file_name)

            if ~exist('session_file_name', 'var')
                session_file_name = 'SPM.mat';
            end

            result = geospm.spm.SPMSession(fullfile(obj.directory, session_file_name));
        end
    end
    
    methods (Access = private)
        
        function result = now(~)
            result = datetime('now', 'TimeZone', 'local', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
            
        end
        
        function [result, entry] = create_spm_batch(obj, entry)
            
            if ~isKey(obj.available_spm_jobs, entry.job_identifier)
                error(['geospm.spm.SPMJobList.create_spm_batch(): ''' entry.job_identifier ''' is not a known SPM job identifier.']);
            end

            method_name = obj.available_spm_jobs(entry.job_identifier);
            [result, entry] = obj.(method_name)(entry);
        end
        
        function [batches, indices] = spm_batches_from_job_list(obj)
            
            batches = cell(numel(obj.spm_job_list), 1);
            indices = struct();
            map = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.spm_jobs_by_identifier_ = map;
            
            for i=1:numel(obj.spm_job_list)
                entry = obj.spm_job_list{i};
                entry.index = i;
                [batches{i}, entry] = obj.create_spm_batch(entry);
                indices.(entry.job_identifier) = i;
                
                if ~isKey(map, entry.job_identifier)
                    map_entry = struct('indices', []);
                else
                    map_entry = map(entry.job_identifier);
                end
                
                map_entry.indices(end + 1) = i;
                map(entry.job_identifier) = map_entry;
            end
        end
        
        function map = gather_available_spm_jobs(obj)
            
            map = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            class_type = class(obj);
            mc = meta.class.fromName(class_type);
            
            N_methods = numel(mc.MethodList);
            
            for i=1:N_methods
                
                method = mc.MethodList(i);
                name = method.Name;
                
                if ~startsWith(name, 'create_') || ~endsWith(name, '_job')
                    continue;
                end
                
                identifier = name(8:end - 4);
                map(identifier) = name;
            end
        end
        
        function [result, entry] = create_factorial_design_job(obj, entry)
            
            if ~isfield(entry, 'observations')
                error('SPMJobList.create_factorial_design_job(): Missing required field ''observations'' in job specification.');
            end
            
            if ~isfield(entry, 'variable_names')
                
                entry.variable_names = {};
                
                N_variables = size(entry.observations, 2);
                
                for i=1:N_variables
                    entry.variable_names{end + 1} = ['variable_' num2str(i, '%d')];
                end
            end
            
            if numel(entry.variable_names) ~= size(entry.observations, 2)
                error('geospm.spm.SPMJobList.create_factorial_design_job(): Number of variable names does not match number of observation columns.');
            end
            
            if ~isfield(entry, 'volume_paths')
                error('geospm.spm.SPMJobList.create_factorial_design_job(): Missing required field ''volume_paths'' in job specification.');
            end
            
            if ~isfield(entry, 'explicit_mask_path')
                entry.explicit_mask_path = '';
            end
            
            if ~isfield(entry, 'do_add_intercept')
                entry.do_add_intercept = true;
            end
            
            result = obj.spm_interface.create_factorial_design_job( ...
                entry.observations, ...
                entry.variable_names, ...
                obj.directory, ...
                entry.volume_paths, ...
                entry.explicit_mask_path, ...
                entry.do_add_intercept );
        end
        
        function [result, entry] = create_fmri_model_estimation_job(obj, entry)
            
            [did_exist, ~, index] = obj.factorial_design_entry_before(entry);

            if ~did_exist
                error('geospm.spm.SPMJobList.create_fmri_model_estimation_job(): Cannot locate preceding factorial design dependency.');
            end
            
            dep = obj.spm_interface.define_spmmat_dependency(index);
            result = obj.spm_interface.create_fmri_model_estimation_job(dep);
        end
        
        function entry = canonicalise_contrasts(obj, entry)
            
            if ~isfield(entry, 'contrasts') || numel(entry.contrasts) == 0
                
                entry.contrasts = {};
                entry.contrast_names = {};
                
                [did_exist, factorial_design] = obj.factorial_design_entry_before(entry);

                if ~did_exist
                    error('geospm.spm.SPMJobList.canonicalise_contrasts(): Contrast computation requires ''factorial_design'' job.');
                end

                N_variables = numel(factorial_design.variable_names);
                
                for i=1:N_variables
                    
                    contrast = zeros(1, N_variables);
                    contrast(i) = 1;
                    entry.contrasts{end + 1} = contrast;
                    entry.contrast_names{end + 1} = [factorial_design.variable_names{i} '_contrast'];
                end
            end
            
            if ~isfield(entry, 'contrast_names')
                
                entry.contrast_names = {};
                
                N_contrast = numel(entry.contrasts);
                
                for i=1:N_contrast
                    entry.contrast_names{end + 1} = ['contrast_' num2str(i, '%d')];
                end
            end
            
            if ~isfield(entry, 'do_add_intercept')
                 entry.do_add_intercept = true;
            end
            
            if ~isfield(entry, 'spmmat_path')
                entry.spmmat_path = [];
            end
        end
        
        function [result, entry] = create_t_contrasts_job(obj, entry)
            
            entry = obj.canonicalise_contrasts(entry);
            
            if isempty(entry.spmmat_path)
                [did_exist, ~, index] = obj.fmri_model_estimation_entry_before(entry);

                if ~did_exist
                    error('geospm.spm.SPMJobList.create_t_contrasts_job(): Cannot locate preceding fmri model estimation dependency.');
                end

                dep = obj.spm_interface.define_spmmat_dependency(index);
            else
                dep = obj.spm_interface.define_spmmat_path(entry.spmmat_path);
            end
            
            result = obj.spm_interface.create_t_contrasts_job(...
                dep, entry.contrasts, entry.contrast_names, ...
                entry.do_add_intercept);
        end
        
        function [result, entry] = create_f_contrasts_job(obj, entry)
            
            entry = obj.canonicalise_contrasts(entry);
            
            if isempty(entry.spmmat_path)
                [did_exist, ~, index] = obj.fmri_model_estimation_entry_before(entry);

                if ~did_exist
                    error('geospm.spm.SPMJobList.create_f_contrasts_job(): Cannot locate preceding fmri model estimation dependency.');
                end

                dep = obj.spm_interface.define_spmmat_dependency(index);
            else
                dep = obj.spm_interface.define_spmmat_path(entry.spmmat_path);
            end
            
            result = obj.spm_interface.create_f_contrasts_job(...
                dep, entry.contrasts, entry.contrast_names, ...
                entry.do_add_intercept);
        end
        
        function [result, entry] = create_results_job(obj, entry)
            
            if ~isfield(entry, 'spmmat')
                [did_exist, ~, index] = obj.contrasts_entry_before(entry);

                if ~did_exist
                    error('geospm.spm.SPMJobList.create_results_job(): Cannot locate preceding contrast dependency.');
                end
                
                entry.spmmat = obj.spm_interface.define_spmmat_dependency(index);
            end
            
            if ~isfield(entry, 'contrasts')
                entry.contrasts = Inf;
            end
            
            if ~isfield(entry, 'threshold')
                entry.threshold = 0.05;
            end
            
            if ~isfield(entry, 'threshold_type')
                entry.threshold_type = 'FWE';
            end
            
            if ~isfield(entry, 'binary_basename')
                entry.binary_basename = '';
            end
            
            if ~isfield(entry, 'tspm_basename')
                entry.tspm_basename = '';
            end
            
            result = obj.spm_interface.create_results_job(entry.spmmat, ...
                        entry.contrasts, ...
                        entry.threshold, entry.threshold_type, ...
                        entry.binary_basename, entry.tspm_basename);
        end
    end
    
    methods (Static)
        
        function result = create_spm_job_entry(identifier, model)
            
            if ~exist('model', 'var')
                model = struct();
            end
            
            model.job_identifier = identifier;
            result = model;
        end

        function result = access_spm_interface()
            
            persistent spm_interface;
            
            if isempty(spm_interface)
                spm_interface = geospm.spm.SPMInterface();
            end
            
            result = spm_interface;
        end
    end
end
