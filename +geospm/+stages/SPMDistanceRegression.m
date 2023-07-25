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

classdef SPMDistanceRegression < geospm.stages.SpatialAnalysisStage
    
    properties
        apply_volume_mask
        write_volume_mask
        volume_mask_factor

        optional_mask
    end
    
    properties (SetAccess=immutable)
        
        precision % character array ? Numeric precision to be used, either 'single' or 'double'.
        output_directory_name
    end
    
    properties (Dependent, Transient)
        spm_precision % character array ? The SPM variant of this session's Matlab precision identifier
    end
    
    methods
        
        function obj = SPMDistanceRegression(analysis, options, varargin)
            %Create a SPMDistanceRegression object.
            %
            % options - A structure of options. 
            % varargin - An arbitrary number of Name, Value pairs specifying
            % additional options.
            %
            %
            
            obj = obj@geospm.stages.SpatialAnalysisStage(analysis);
            
            if ~exist('options', 'var') || isempty(options)
                options = struct();
            end
            
            additional_options = hdng.utilities.parse_struct_from_varargin(varargin{:});
           
            names = fieldnames(additional_options);
            
            for i=1:numel(names)
                name = names{i};
                options.(name) = additional_options.(name);
            end
            
            obj.define_requirement('directory');
            obj.define_requirement('grid_data');
            
            obj.define_requirement('volume_generator');
            obj.define_requirement('volume_paths');
            obj.define_requirement('volume_mask_path');
            obj.define_requirement('volume_precision');
            obj.define_requirement('sample_density');
            
            obj.define_requirement('regression_probes', ...
                struct(), 'is_optional', true, 'default_value', []);
            
            obj.define_requirement('regression_spmmat_path', ...
                struct(), 'is_optional', true, 'default_value', '');
            
            obj.define_requirement('regression_run_computation', ...
                struct(), 'is_optional', true, 'default_value', true);
            
            contrasts_default = struct();
            contrasts_default.statistic = 'T';
            contrasts_default.contrasts = {};
            contrasts_default.contrast_names = {};
            
            obj.define_requirement('contrasts', ...
                struct(), 'is_optional', true, 'default_value', {contrasts_default});
            
            obj.define_requirement('regression_add_intercept', ...
                struct(), 'is_optional', true, 'default_value', false);
            
            obj.define_product('spm_job_list');
            obj.define_product('spm_output_directory');
            obj.define_product('regression_probe_file');
            obj.define_product('volume_mask');
            obj.define_product('volume_mask_file');
            
            obj.output_directory_name = 'spm_output';
            obj.apply_volume_mask = true;
            obj.write_volume_mask = true;
            obj.volume_mask_factor = 10.0;
            obj.optional_mask = [];
        end
        
        function [observations, variable_names] = encode_grid_data(~, grid_data, encoding)
            
            if ~exist('encoding', 'var')
                encoding = struct('type', 'default');
            end
            
            switch encoding.type
                case 'default'
                    
                    observations = grid_data.observations;
                    variable_names = grid_data.variable_names;
                    
                otherwise
                    error('SPMDistanceRegression: Unknown encoding ''%s''', encoding);
            end
        end
        
        
        function result = run(obj, arguments)
            
            spm_job_list = {};
            
            factorial_design_job = geospm.spm.SPMJobList.create_spm_job_entry('factorial_design');
            
            [factorial_design_job.observations, ...
             factorial_design_job.variable_names] = ...
                obj.encode_grid_data(arguments.grid_data);
            
            factorial_design_job.volume_paths = arguments.volume_paths;
            factorial_design_job.do_add_intercept = arguments.regression_add_intercept;
            
            if isempty(arguments.regression_spmmat_path)
                spm_job_list{end + 1} = factorial_design_job;

                model_estimation_job = geospm.spm.SPMJobList.create_spm_job_entry('fmri_model_estimation');
                spm_job_list{end + 1} = model_estimation_job;
            else
                session = geospm.spm.SPMSession(arguments.regression_spmmat_path);
                session.delete_contrasts();
            end
            
            for index=1:numel(arguments.contrasts)
                contrasts_job = arguments.contrasts{index};
                identifier = [lower(contrasts_job.statistic) '_contrasts'];
                contrasts_job = geospm.spm.SPMJobList.create_spm_job_entry(identifier, contrasts_job);
                contrasts_job.do_add_intercept = factorial_design_job.do_add_intercept;
                
                if ~isempty(arguments.regression_spmmat_path)
                    contrasts_job.spmmat_path = arguments.regression_spmmat_path;
                end
                
                spm_job_list{end + 1} = contrasts_job; %#ok<AGROW>
            end

            output_directory = fullfile(arguments.directory, obj.output_directory_name);
            
            computation = geospm.spm.SPMJobList(...
                            output_directory, ...
                            arguments.volume_precision, ...
                            spm_job_list);
            
            volume_samples_file = '';
            volume_generator = arguments.volume_generator;
            
            SyntheticVolumeGenerator.add(volume_generator, ...
                                         volume_generator.session_key);
            
            svd_global_mask = volume_generator.global_mask;
            
            try
                
                if obj.apply_volume_mask
                    global_mask = obj.compute_global_density_mask( ...
                        volume_generator, ...
                        arguments.sample_density);
                else
                    global_mask = [];
                end
                
                if ~isempty(obj.optional_mask)
                    if isempty(global_mask)
                        global_mask = obj.optional_mask;
                    else
                        global_mask = global_mask & obj.optional_mask;
                    end
                end

                if arguments.regression_run_computation
                    
                    volume_generator.global_mask = global_mask;
                    volume_generator.apply_global_mask_inline = ~isempty(global_mask);
    
                    computation.run();
                end
                
                if ~isempty(arguments.regression_probes)
                    
                    probe_locations = arguments.regression_probes.uvw(:, 1:2);
                    smoothing_levels = volume_generator.smoothing_levels;
                    
                    volume_samples_file = obj.probe_volumes(arguments.volume_paths, ...
                        arguments.regression_probes.categories, probe_locations, ...
                        smoothing_levels, arguments.directory);
                end
                
            catch exception

                SyntheticVolumeGenerator.remove(volume_generator.session_key);
                volume_generator.global_mask = svd_global_mask;
                rethrow(exception);
            end
            
            SyntheticVolumeGenerator.remove(volume_generator.session_key);
            volume_generator.global_mask = svd_global_mask;
            
            
            if isempty(global_mask)
                global_mask = ones(size(arguments.sample_density), 'logical');
            end
            
            global_mask_path = '';
            
            if obj.write_volume_mask
                
                global_mask_path = fullfile(arguments.directory, 'global_mask.nii');
                geospm.utilities.write_nifti(global_mask, global_mask_path);
            end
            
            result = struct();
            result.spm_job_list = computation;
            result.spm_output_directory = computation.directory;
            result.regression_probe_file = volume_samples_file;
            result.volume_mask = global_mask;
            result.volume_mask_file = global_mask_path;
        end
        
        function file_path = probe_volumes(obj, volume_paths, probe_ids, probe_locations, smoothing_levels, output_directory)
            
            N_smoothing_levels = numel(smoothing_levels);
            
            probe_smoothing_level = ...
                repelem((1:N_smoothing_levels), size(probe_locations, 1))';
            
            voxel_coordinates = [repmat(probe_locations, N_smoothing_levels, 1), ...
                                 probe_smoothing_level];
            
            volume_values = obj.read_voxels(volume_paths, voxel_coordinates);
            
            file_path = fullfile(output_directory, 'regression_probe.mat');
            
            sample_location = voxel_coordinates;
            sample_probe_id = repmat(probe_ids, N_smoothing_levels, 1);
            
            save(file_path, 'sample_probe_id', 'sample_location', ...
                    'volume_values', 'smoothing_levels');
        end
        
        function voxel_values = read_voxels(~, volume_paths, voxel_coordinates)
            
            V = spm_data_hdr_read(char(volume_paths));
            
            voxel_indices = sub2ind(V(1).dim, voxel_coordinates(:,1), voxel_coordinates(:,2), voxel_coordinates(:,3));
            voxel_values = zeros(numel(V), numel(voxel_indices));
            
            for i=1:numel(V)
            
                Y_tmp = spm_data_read(V(i));
                Y_value = Y_tmp(voxel_indices);
                voxel_values(i,:) = Y_value(:);
            end
        end
    end
    
    methods (Access=protected)
        
        function global_mask = compute_global_density_mask(obj, ...
                volume_generator, sample_density)
            
            peak_values = volume_generator.peak_values;
            global_mask = zeros(size(sample_density), 'logical');
            
            if volume_generator.smoothing_levels_as_z_dimension
                
                for index=1:numel(peak_values)
                    p = peak_values(index);
                    selector = sample_density(:, :, index) >= obj.volume_mask_factor * p;
                    global_mask(:, :, index) = selector;
                end
                
            else
                global_mask = sample_density >= obj.volume_mask_factor * peak_values;
            end
        end
    end
    
end
