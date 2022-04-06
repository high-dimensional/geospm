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

classdef SPMInterface < matlab.mixin.Copyable
    %SPMInterface Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        release
        version
        max_memory
    end
    
    
    properties (Dependent, Transient)
        version_string
    end
    
    methods
        
        function obj = SPMInterface()
            
            [obj.version, obj.release] = spm('Ver');
            obj.max_memory = 2^31;
            
            spm('defaults','fmri');
            
            %This has the effect of initialising all SPM toolboxes,
            %which means the SyntheticVolumeGenerator class in the 
            %synthetic volumes toolbox will be available in the Matlab path
            
            spm_jobman('initcfg');
            
            try
                info = spm_synth_vol_get('Ver');

                fprintf('Found %s v%s (%s), %s.\n', ...
                        info.Name, info.Version, info.Release, info.Date);
            catch
                error(['SPMInterface(): The synthetic ' ... 
                           'volumes toolbox is missing or did not load.']);
            end
        end
        
        function result = get.version_string(obj)
            result = [obj.release ' (' obj.version ')'];
        end
        
        function output_list = run_batch_jobs(obj, batches)
            
            saved_wd = pwd;
            
            %Prevent SPM from polluting the workspace
            %We save all variables in the base workspace prior to 
            %invoking SPM
            
            base_variable_names = evalin('base', 'who');
            
            if numel(base_variable_names) > 0
                base_expr = join(base_variable_names, ', ');
                base_expr = base_expr{1};
                base_expr = ['{' base_expr '}'];
                base_variables = evalin('base', base_expr);
            else
                base_variables = {};
            end
            
            %Set SPM to cmdline mode
            saved_cmdline = spm_get_defaults('cmdline');
            spm_get_defaults('cmdline',true);
            
            saved_maxmem = spm_get_defaults('stats.maxmem');
            spm_get_defaults('stats.maxmem', obj.max_memory);
            
            [output_list, ~] = spm_jobman('run', batches);
            
            spm_get_defaults('stats.maxmem', saved_maxmem);
            spm_get_defaults('cmdline', saved_cmdline);
            
            %Clear all variables in the base workspace
            evalin('base', 'clear');
            
            %Restore all previously saved variables in the base workspace
            
            for i=1:numel(base_variables)
                assignin('base', base_variable_names{i}, base_variables{i});
            end
            
            cd(saved_wd);
        end
        
        function result = define_spmmat_dependency(~, batch_index)
            
            result = cfg_dep( ...
                'SPM.mat File', ...
                substruct('.', 'val', '{}', {batch_index}, ...
                          '.', 'val', '{}', {1}, ...
                          '.', 'val', '{}', {1}), ...
                substruct('.', 'spmmat'));
            
        end
        
        function result = define_spmmat_path(~, path)
            
            result = { path };
        end
        
        function result = create_factorial_design_job(obj, ...
                            observations, ...
                            variable_names, ...
                            output_directory, ...
                            volume_paths, ...
                            explicit_mask_path, ...
                            do_add_intercept )
            
            N = size(observations, 1);
            P = size(observations, 2);
            
            S = {};
            S.dir = {output_directory};
            S.des.mreg.scans = (volume_paths);
            
            %Do not automatically include a constant term:
            S.des.mreg.incint = 0; %1;
            
            for i = 1:P
                S.des.mreg.mcov(i).c = observations(:,i);
                S.des.mreg.mcov(i).cname = variable_names{i};
                S.des.mreg.mcov(i).iCC = 5;
            end
            
            
            if do_add_intercept
                
                intercept = struct();
                intercept.c = ones(N, 1);
                intercept.cname = 'constant';
                intercept.iCC = 5;
                
                S.des.mreg.mcov = [intercept S.des.mreg.mcov];
            end
            
            S.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
            S.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
            S.masking.tm.tm_none = 1;
            S.masking.im = 1; %No implicit masking if 0
            S.masking.em = { explicit_mask_path };
            S.globalc.g_omit = 1;
            S.globalm.gmsca.gmsca_no = 1;
            S.globalm.glonorm = 1;
            
            result = obj.create_batch_job();
            result.spm.stats.factorial_design = S;
        end
       
        
        function result = create_fmri_model_estimation_job(obj, spmmat_dep)
            
            result = obj.create_batch_job();
            
            result.spm.stats.fmri_est.spmmat(1) = spmmat_dep;
            
            result.spm.stats.fmri_est.write_residuals = 0;
            result.spm.stats.fmri_est.method.Classical = 1;
        end
        
        function result = create_f_contrasts_job(obj, ...
                            spmmat_dep, ...
                            contrasts, ...
                            contrast_names, ...
                            do_add_intercept )
            
            N_contrasts = numel(contrasts);
            N_variables = size(contrasts{1}, 2);
            
            S = {};
            
            S.spmmat = spmmat_dep;
            
            for i=1:N_contrasts
                S.consess{i}.fcon.name = contrast_names{i};
                S.consess{i}.fcon.weights = contrasts{i};
                S.consess{i}.fcon.sessrep = 'none';
            end
            
            if do_add_intercept
                
                for i=1:N_contrasts
                    S.consess{i}.fcon.weights = [0 S.consess{i}.fcon.weights];
                end
                
                intercept = struct();
                intercept.fcon.name = 'intercept';
                intercept.fcon.weights = [1 zeros(1, N_variables)];
                intercept.fcon.sessrep = 'none';
                
                S.consess = [{intercept} S.consess];
            end
            
            S.delete = 0;
           
            result = obj.create_batch_job();
            result.spm.stats.con = S;
        end
        
        
        function result = create_t_contrasts_job(obj, ...
                            spmmat_dep, ...
                            contrasts, ...
                            contrast_names, ...
                            do_add_intercept )
            
            N_contrasts = numel(contrasts);
            N_variables = size(contrasts{1}, 2);
            
            S = {};
            
            S.spmmat = spmmat_dep;
            
            for i=1:N_contrasts
                S.consess{i}.tcon.name = contrast_names{i};
                S.consess{i}.tcon.weights = contrasts{i};
                S.consess{i}.tcon.sessrep = 'none';
            end
            
            if do_add_intercept
                
                for i=1:N_contrasts
                    S.consess{i}.tcon.weights = [0 S.consess{i}.tcon.weights];
                end
                
                intercept = struct();
                intercept.tcon.name = 'intercept';
                intercept.tcon.weights = [1 zeros(1, N_variables)];
                intercept.tcon.sessrep = 'none';
                
                S.consess = [{intercept} S.consess];
            end
            
            S.delete = 0;
           
            result = obj.create_batch_job();
            result.spm.stats.con = S;
        end
        
        function result = create_results_job(obj, spmmat_dep, contrasts, threshold, threshold_type, binary_basename, tspm_basename, export_csv)
            
            if ~exist('contrasts', 'var')
                contrasts = Inf;
            end
            
            if ~exist('threshold', 'var')
                threshold = 0.05;
            end
            
            if ~exist('threshold_type', 'var')
                threshold_type = 'FWE';
            end
            
            if ~exist('export_csv', 'var')
                export_csv = false;
            end
            
            S = {};
            
            S.spmmat = spmmat_dep;
            
            S.conspec.titlestr = '';
            S.conspec.contrasts = contrasts;
            S.conspec.threshdesc = threshold_type;
            S.conspec.thresh = threshold;
            S.conspec.extent = 0;
            S.conspec.conjunction = 1;
            S.conspec.mask.none = 1;
            S.units = 1;
            
            S.export = cell(0,1);
            
            if export_csv
                S.export{end + 1}.csv = true;
            end
            
            if exist('binary_basename', 'var') && ~isempty(binary_basename)
                S.export{end + 1}.binary = struct();
                S.export{end}.binary.basename = binary_basename;
            end
            
            if exist('tspm_basename', 'var') && ~isempty(tspm_basename)
                S.export{end + 1}.tspm = struct();
                S.export{end}.tspm.basename = tspm_basename;
            end
            
            result = obj.create_batch_job();
            result.spm.stats.results = S;
        end
        
    end
    
    methods (Access=private)
        
        function result = create_batch_job(~)
            
            result = struct();
        end
    end
end
