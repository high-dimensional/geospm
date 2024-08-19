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

classdef BaseGenerator < SyntheticVolumeGenerator
    %BaseGenerator Summary of this class goes here
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
        smoothing_synthesis_variant
        
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
        smooth_map_cache_key
        
        smooth_sample
    end
    
    methods
        
        function obj = BaseGenerator(...
                          session_volume_directory, ...
                          varargin)


            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'window_resolution')
                error('Missing window_resolution argument.');
            end

            if ~isfield(options, 'precision')
                options.precision = 'double';
            end

            if ~isfield(options, 'smoothing_method')
                options.smoothing_method = 'default';
            end

            if ~isfield(options, 'smoothing_levels')
                error('Missing smoothing_levels argument.');
            end

            if ~isfield(options, 'smoothing_levels_p_value')
                options.smoothing_levels_p_value = 0.95;
            end

            if ~isfield(options, 'smoothing_levels_as_z_dimension')
                error('Missing smoothing_levels_as_z_dimension argument.');
            end

            if ~isfield(options, 'smoothing_synthesis_variant')
                options.smoothing_synthesis_variant = 'default';
            end

            if ~isfield(options, 'write_volumes')
                options.write_volumes = false;
            end

            if ~isfield(options, 'overwrite_existing_volumes')
                options.overwrite_existing_volumes = false;
            end
            
            window_resolution = options.window_resolution;
            precision = options.precision;
            smoothing_method = options.smoothing_method;
            smoothing_levels = options.smoothing_levels;
            smoothing_levels_p_value = options.smoothing_levels_p_value;
            smoothing_levels_as_z_dimension = options.smoothing_levels_as_z_dimension;
            smoothing_synthesis_variant = options.smoothing_synthesis_variant;
            do_write_volumes = options.write_volumes;
            overwrite_existing_volumes = options.overwrite_existing_volumes;


            
            if ~smoothing_levels_as_z_dimension && numel(smoothing_levels) ~= 3
                error('geospm.spm.BaseGenerator(): ''smoothing_levels_as_z_dimension'' is false but number of smoothing levels does not equal 3.');
            elseif smoothing_levels_as_z_dimension && isempty(smoothing_levels)
                error('geospm.spm.BaseGenerator(): ''smoothing_levels_as_z_dimension'' is true but no smoothing levels were specified.');
            end
            
            if smoothing_levels_as_z_dimension && window_resolution(3) ~= 1
                error('geospm.spm.BaseGenerator(): ''smoothing_levels_as_z_dimension'' is true but z window resolution does not equal 1.');
            end

            if smoothing_levels_p_value <= 0.0 || smoothing_levels_p_value >= 1.0
                error('geospm.spm.BaseGenerator.ctor(): ''smoothing_levels_p_value'' is not in (0, 1.0): %f', options.smoothing_levels_p_value);
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
                    error('geospm.spm.BaseGenerator.ctor(): Unknown smoothing_method ''%s''.', obj.smoothing_method.type);
            end
            
            obj.smoothing_levels = smoothing_levels;
            obj.smoothing_levels_p_value = smoothing_levels_p_value;
            obj.smoothing_levels_as_z_dimension = smoothing_levels_as_z_dimension;
            obj.smoothing_synthesis_variant = smoothing_synthesis_variant;
            
            smooth_map_size = obj.window_resolution * 2 - 1;
            sample_location = obj.window_resolution;
            
            [obj.smooth_map, obj.smooth_map_cache_key] = obj.smooth_sample(sample_location, smooth_map_size);
            obj.have_smooth_map = true;
            
            if obj.smoothing_levels_as_z_dimension
                obj.peak_values = reshape(max(obj.smooth_map, [], [1, 2]), size(obj.smooth_map, 3), 1);
            else
                obj.peak_values = max(obj.smooth_map(:)); %repmat(max(obj.smooth_map(:)), size(obj.smooth_map, 3), 1);
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
                error(['geospm.BaseGenerator.get.spm_precision(): Unsupported precision ''' obj.precision '''.']);
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

        function V_data = synthesize_by_convolution(obj, specifier)
            
            if obj.smoothing_levels_as_z_dimension
                
                V_data = zeros(obj.volume_size());

                for index=1:size(obj.smooth_map, 3)

                    V_data(:, :, index) = specifier.spatial_index.convolve_segment( ...
                        specifier.segment_number, ...
                        [1, 1, 1], [obj.window_resolution(1:2), 1] + [1, 1, 1], ...
                        obj.smooth_map(:, :, index), [obj.smooth_map_cache_key, ':' num2str(index)]);
                end
            else

                V_data = specifier.spatial_index.convolve_segment( ...
                    specifier.segment_number, ...
                    [1, 1, 1], obj.window_resolution + [1, 1, 1], ...
                    obj.smooth_map, obj.smooth_map_cache_key);
            end
        end

        %{
        function V_data = synthesize_by_addition(obj, specifier)
            

            [x, y, z] = specifier.spatial_index.xyz_coordinates_for_segment(specifier.segment_number);


            V_data = [];
            N_locations = size(x, 1);

            for index=1:N_locations

                S_data = obj.render_volume([x(index), y(index), z(index)]);

                if isempty(V_data)
                    V_data = S_data;
                else
                    V_data = V_data + S_data;
                end
            end
        end
        %}

        function V_data = synthesize(obj, specifier)
            
            specifier = obj.parse_specifier(specifier);
            
            switch specifier.type

                case 'directive'
                    switch specifier.directive
                        case 'global_mask'
                            V_data = obj.global_mask;
                            
                        otherwise
                            error('Undefined volume ''%s''.', specifier.directive);
                    end
                    
                    return;

                case 'segment'
                    
                    switch obj.smoothing_synthesis_variant
                        case {'default', 'convolution'}
                            V_data = obj.synthesize_by_convolution(specifier);

                        %{
                        case 'addition'
                            V_data = obj.synthesize_by_addition(specifier);
                        %}
                        
                        otherwise
                            error('Unknown synthesis variant: %s', obj.synthesis_variant);
                    end
                    
                    if obj.apply_global_mask_inline
                        V_data(~obj.global_mask) = NaN;
                    end
                    
                    if obj.debug
                        
                        file_path = fullfile(obj.session_volume_directory, 'debug', [specifier.text '.nii']);
                        obj.save_volume(file_path, V_data);
                    end

                otherwise
                    error('Unknown specifier type ''%s''.', specifier.type);
            end

        end

        function result = parse_specifier(obj, specifier) %#ok<STOUT>
            error(['BaseGenerator.parse_specifier() must be ', ...
                   'implemented by a subclass [session_key="%s", ', ...
                   'specifier="%s"].'
                   ], obj.session_key, specifier);
        end
        
    end
    
    methods (Access=protected)
        
        %{
        function V_data = render_volume(obj, sample_location)
            
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
        end
        %}

        function save_volume(obj, file_path, data)
            
            V = obj.blank_spm_volume();
            V.fname = file_path;

            dim = ones(1, 3);
            unsafe_size = size(data);
            dim(1:numel(unsafe_size)) = unsafe_size;
            V.dim = dim;
            spm_write_vol(V, data);
        end

        function result = blank_spm_volume(obj)
            
            result = struct();
            
            result.dt = [spm_type(obj.spm_precision) 0];
            result.mat = eye(4);
            result.pinfo = [1 0 0]';
        end

        
        function result = format_global_mask_path(obj)
            result = fullfile(obj.session_volume_directory, 'global_mask.synth');
        end
        
        function [V_data, cache_key] = smooth_sample_default(obj, sample_location, map_size, parameters)
            
            N_smoothing_levels = numel(obj.smoothing_levels);
            
            if ~isfield(parameters, 'gaussian_method')
                gaussian_method = [];
            else
                gaussian_method = parameters.gaussian_method;
            end
            
            parameters = rmfield(parameters, 'gaussian_method');
            
            cache_key = sprintf('%s;', gaussian_method);

            spatial_dims = 2 + ~obj.smoothing_levels_as_z_dimension;
            smoothing_stddevs = geospm.utilities.stddev_from_p_diameter(obj.smoothing_levels_p_value, obj.smoothing_levels, spatial_dims);
            smoothing_variances = smoothing_stddevs .* smoothing_stddevs;

            for i=1:numel(smoothing_variances)
                cache_key = [cache_key sprintf('%.2f;', smoothing_variances(i))]; %#ok<AGROW>
            end
            
            if obj.smoothing_levels_as_z_dimension
            
                map_size = map_size(1:2);

                combined_smooth_map = zeros([map_size, N_smoothing_levels], obj.precision);

                for i=1:N_smoothing_levels
                    
                    level_smooth_data = geospm.utilities.discretise_gaussian(map_size, sample_location(1:2), eye(2) * smoothing_variances(i), gaussian_method, parameters);
                    combined_smooth_map(:,:,i) = level_smooth_data;
                end

                V_data = combined_smooth_map;
                
            else
                
                V_data = geospm.utilities.discretise_gaussian(map_size, sample_location, eye(3) .* smoothing_variances, gaussian_method, parameters);
            end
        end
    end
end
