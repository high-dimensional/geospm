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

classdef KernelVolumeGenerator < SyntheticVolumeGenerator
    %KernelVolumeGenerator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        global_mask
        apply_global_mask_inline
    end
    
    properties (GetAccess=public, SetAccess=private)
        
        window_resolution
        precision
        
        smoothing_method
        
        smoothing_levels
        smoothing_levels_p_value
        smoothing_levels_as_z_dimension
        
        peak_values
        
        debug
        
        do_write_volumes
        overwrite_existing_volumes
    end
        
    properties (Transient, Dependent)
        spm_precision
        session_volume_directory
    end
    
    properties (GetAccess=private, SetAccess=private)
        
        have_smooth_map
        smooth_map
        
        smooth_sample
    end
    
    methods
        
        function obj = KernelVolumeGenerator(...
                          session_volume_directory, ...
                          window_resolution, ...
                          precision, ...
                          smoothing_method, ...
                          smoothing_levels, ...
                          smoothing_levels_p_value, ...
                          smoothing_levels_as_z_dimension, ...
                          do_write_volumes, ...
                          overwrite_existing_volumes)
            
            if ~smoothing_levels_as_z_dimension && numel(smoothing_levels) ~= 3
                error('geospm.spm.KernelVolumeGenerator(): ''smoothing_levels_as_z_dimension'' is false but number of smoothing levels does not equal 3.');
            elseif smoothing_levels_as_z_dimension && isempty(smoothing_levels)
                error('geospm.spm.KernelVolumeGenerator(): ''smoothing_levels_as_z_dimension'' is true but no smoothing levels were specified.');
            end
            
            if smoothing_levels_as_z_dimension && window_resolution(3) ~= 1
                error('geospm.spm.KernelVolumeGenerator(): ''smoothing_levels_as_z_dimension'' is true but z window resolution does not equal 1.');
            end

            if smoothing_levels_p_value <= 0.0 || smoothing_levels_p_value >= 1.0
                error('geospm.spm.KernelVolumeGenerator.ctor(): ''smoothing_levels_p_value'' is not in (0, 1.0): %f', options.smoothing_levels_p_value);
            end
            
            obj = obj@SyntheticVolumeGenerator(session_volume_directory);
            
            obj.global_mask = [];
            obj.apply_global_mask_inline = false;
            obj.window_resolution = window_resolution;
            obj.precision = precision;
            
            obj.smooth_sample = @(sample_location, map_size) [];
            obj.smoothing_method = geospm.spm.configure_smoothing_method(smoothing_method);
            
            switch obj.smoothing_method.type
                
                case 'default'
                    obj.smooth_sample = @(sample_location, map_size) obj.smooth_sample_default(sample_location, map_size, obj.smoothing_method.parameters);
                
                otherwise
                    error('geospm.spm.KernelVolumeGenerator.ctor(): Unknown smoothing_method ''%s''.', obj.smoothing_method.type);
            end
            
            obj.smoothing_levels = smoothing_levels;
            obj.smoothing_levels_p_value = smoothing_levels_p_value;
            obj.smoothing_levels_as_z_dimension = smoothing_levels_as_z_dimension;
            
            smooth_map_size = obj.window_resolution * 2 - 1;
            sample_location = obj.window_resolution;
            
            obj.smooth_map = obj.smooth_sample(sample_location, smooth_map_size);
            obj.have_smooth_map = true;
            
            if obj.smoothing_levels_as_z_dimension
                obj.peak_values = reshape(max(obj.smooth_map, [], [1, 2]), size(obj.smooth_map, 3), 1);
            else
                obj.peak_values = repmat(max(obj.smooth_map(:)), size(obj.smooth_map, 3), 1);
            end
            
            obj.debug = obj.smoothing_method.diagnostics.active;
            
            if  obj.have_smooth_map && obj.debug
                obj.save_smooth_map();
                obj.debug = false;
            end
            
            obj.do_write_volumes = do_write_volumes;
            obj.overwrite_existing_volumes = overwrite_existing_volumes;
        end
        
        function result = get.spm_precision(obj)
            
            if strcmp(obj.precision, 'single')
                result = 'float32';
            elseif strcmp(obj.precision, 'double')
                result = 'float64';
            else
                error(['geospm.KernelVolumeGenerator.get.spm_precision(): Unsupported precision ''' obj.precision '''.']);
            end
        end
        
        function result = get.session_volume_directory(obj)
            result = obj.session_key;
        end
        
        function save_smooth_map(obj)
            
            debug_path = fullfile(obj.session_volume_directory, 'debug');

            [dirstatus, dirmsg] = mkdir(debug_path);
            if dirstatus ~= 1; error(dirmsg); end

            file_path = fullfile(debug_path, 'smooth_map.nii');
            obj.save_volume(file_path, obj.smooth_map);
            
            values = obj.smooth_map;
            nonzero_mask = obj.smooth_map > eps;
            p_value = obj.smoothing_levels_p_value;

            file_path = fullfile(debug_path, 'smooth_map.mat');
            save(file_path, 'nonzero_mask', 'values', 'p_value');
        end
        
        function result = volume_size(obj, ~)
            
            n_smoothing_levels = length(obj.smoothing_levels);
            
            % this must be double, otherwise spm_spm.m fails when invoking
            % smp_slice_vol on the mask which has the dimensions derived
            % from this.
            
            if obj.smoothing_levels_as_z_dimension
                result = cast([obj.window_resolution(1:2), n_smoothing_levels], 'double');
            else
                result = cast(obj.window_resolution, 'double');
            end
        end
        
        function [location, identifier] = parse_specifier(~, specifier)
            
            [~, id, ~] = fileparts(specifier);
            
            index_xyz = split(id, ';');
            
            if numel(index_xyz) == 1
                identifier = id;
                location = [];
            else
                identifier = index_xyz{1};
                location = [str2double(index_xyz{2}), ...
                            str2double(index_xyz{3}), ...
                            str2double(index_xyz{4})];
            end
        end
        
        
        function V_data = synthesize(obj, specifier)
            
            [sample_location, identifier] = obj.parse_specifier(specifier);
            
            if isempty(sample_location)
                
                switch identifier
                    case 'global_mask'
                        V_data = obj.global_mask;
                        
                    otherwise
                        error('geospm.KernelVolumeGenerator.synthesize(): Undefined volume ''%s''.', identifier);
                end
                
                return;
            end
            
            if obj.have_smooth_map
                
                %If sample_location is (1, 1), then range_start is window_resolution
                %If sample_location is window_resolution, then range_start is 1
                
                range_start = obj.window_resolution - sample_location + 1;
                range_end = range_start + obj.window_resolution - 1;
                
                if obj.smoothing_levels_as_z_dimension
                    range_start(3) = 1;
                    range_end(3) = size(obj.smooth_map, 3);
                end
                
                V_data = obj.smooth_map(range_start(1):range_end(1), ...
                                        range_start(2):range_end(2), ...
                                        range_start(3):range_end(3));
                
            else
                
                V_data = obj.smooth_sample(sample_location, obj.window_resolution);
            end
            
            if obj.apply_global_mask_inline
                V_data(~obj.global_mask) = NaN;
            end
            
            if obj.debug
                
                file_path = fullfile(obj.session_volume_directory, 'debug', [identifier '.nii']);
                obj.save_volume(file_path, V_data);
            end
        end
        
        function [volume_paths, density, global_mask_path] = smooth_samples(obj, indices, x, y, z)
            
            N_volumes = numel(indices);
            
            volume_paths = cell(N_volumes, 1);
            density = zeros(obj.volume_size);
            global_mask_path = obj.format_global_mask_path();
            
            for i=1:N_volumes

                spatial_data_index = indices(i);
                synthetic_path = obj.format_synthetic_volume_path(spatial_data_index, x(i), y(i), z(i));
                
                synthetic_sample = obj.synthesize(synthetic_path);   
                density = density + synthetic_sample;
                
                if obj.do_write_volumes
                    
                    [session_path, id, ~] = fileparts(synthetic_path);
                    file_path = fullfile(session_path, [id '.nii']);
                    
                    V = obj.blank_spm_volume();
                    V.fname = file_path;

                    if obj.overwrite_existing_volumes || exist(file_path, 'file') == 0
                        dim = ones(1, 3);
                        unsafe_size = size(synthetic_sample);
                        dim(1:numel(unsafe_size)) = unsafe_size;
                        V.dim = dim;
                        spm_write_vol(V, synthetic_sample);
                    end
                else
                    file_path = synthetic_path;
                end

                volume_paths{i} = file_path;
            end
        end
        
        function save_volume(obj, file_path, data)
            
            V = obj.blank_spm_volume();
            V.fname = file_path;

            dim = ones(1, 3);
            unsafe_size = size(data);
            dim(1:numel(unsafe_size)) = unsafe_size;
            V.dim = dim;
            spm_write_vol(V, data);
        end
        
    end
    
    methods (Access=protected)
        
        function result = format_synthetic_volume_id(~, index, x, y, z)
            
            result = [num2str(index, '%08d') ...
                      ';' num2str(x, '%06d') ...
                      ';' num2str(y, '%06d') ...
                      ';' num2str(z, '%06d')];
        end
        
        function result = format_synthetic_volume_path(obj, index, x, y, z)
            
            id = obj.format_synthetic_volume_id(index, x, y, z);
            result = fullfile(obj.session_volume_directory, [id '.synth']);
        end
        
        function result = format_global_mask_path(obj)
            result = fullfile(obj.session_volume_directory, 'global_mask.synth');
        end
        
        function result = blank_spm_volume(obj)
            
            result = struct();
            
            result.dt = [spm_type(obj.spm_precision) 0];
            result.mat = eye(4);
            result.pinfo = [1 0 0]';
        end
        
        function V_data = smooth_sample_default(obj, sample_location, map_size, parameters)
            
            N_smoothing_levels = numel(obj.smoothing_levels);
            
            if ~isfield(parameters, 'gaussian_method')
                gaussian_method = [];
            else
                gaussian_method = parameters.gaussian_method;
            end
            
            parameters = rmfield(parameters, 'gaussian_method');
            
            smoothing_stddevs = geospm.utilities.stddev_from_p_diameter(obj.smoothing_levels_p_value, obj.smoothing_levels, 2);
            smoothing_variances = smoothing_stddevs .* smoothing_stddevs;
            
            if obj.smoothing_levels_as_z_dimension
            
                map_size = map_size(1:2);

                combined_smooth_map = zeros([map_size, N_smoothing_levels], obj.precision);

                for i=1:N_smoothing_levels
                    
                    level_smooth_data = geospm.utilities.discretise_gaussian(map_size, sample_location(1:2), eye(2) * smoothing_variances(i), gaussian_method, parameters);
                    combined_smooth_map(:,:,i) = level_smooth_data;
                end

                V_data = combined_smooth_map;
                
            else
                
                V_data = geospm.utilities.discretise_gaussian(map_size, sample_location(1:2), eye(3) .* smoothing_variances, gaussian_method, parameters);
            end
        end
    end
end
