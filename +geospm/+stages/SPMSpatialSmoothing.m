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

 classdef SPMSpatialSmoothing < geospm.stages.SpatialAnalysisStage
    %SPMSpatialSmoothing Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        grid_spatial_index_requirement
        
        volume_generator_class_name

        write_density
        write_volumes
    end
    
    properties (SetAccess=immutable)
        precision % character array ? Numeric precision to be used, either 'single' or 'double'.
    end
    
    properties (Dependent, Transient)
        spm_precision % character array ? The SPM variant of this session's Matlab precision identifier
    end
    
    
    methods
        
        function obj = SPMSpatialSmoothing(analysis, options, varargin)
            
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
            
            if ~isfield(options, 'precision')
                options.precision = 'double';
            end
            
            if ~isfield(options, 'smoothing_method')
                options.smoothing_method = 'default';
            end
            
            options.smoothing_method = geospm.spm.configure_smoothing_method(options.smoothing_method);
            
            if ~isfield(options, 'smoothing_levels')
                options.smoothing_levels = 20;
            end
            
            if ~isfield(options, 'smoothing_levels_p_value')
                options.smoothing_levels_p_value = 0.95;
            end
            
            if ~isfield(options, 'smoothing_levels_as_z_dimension')
                options.smoothing_levels_as_z_dimension = true;
            end
            
            if ~isfield(options, 'volume_generator_class_name')
                options.volume_generator_class_name = 'geospm.spm.SpatialIndexRenderer';
            end
            
            if ~isfield(options, 'grid_spatial_index_requirement')
                options.grid_spatial_index_requirement = 'grid_spatial_index';
            end
            
            if ~isfield(options, 'write_density')
                options.write_density = false;
            end
            
            if ~isfield(options, 'write_volumes')
                options.write_volumes = false;
            end

            obj.volume_generator_class_name = options.volume_generator_class_name;
            obj.grid_spatial_index_requirement = options.grid_spatial_index_requirement;
            obj.write_density = options.write_density;
            obj.write_volumes = options.write_volumes;
            
            obj.precision = options.precision;
            
            obj.define_requirement('directory');
            obj.define_requirement(obj.grid_spatial_index_requirement);
            
            obj.define_requirement('smoothing_method', ...
                struct(), 'is_optional', true, ...
                'default_value', options.smoothing_method);
            
            obj.define_requirement('smoothing_levels_p_value', ...
                struct(), 'is_optional', true, ...
                'default_value', options.smoothing_levels_p_value);
            
            obj.define_requirement('smoothing_levels', ...
                struct(), 'is_optional', true, ...
                'default_value', options.smoothing_levels);
            
            obj.define_requirement('smoothing_levels_as_z_dimension', ...
                struct(), 'is_optional', true, ...
                'default_value', options.smoothing_levels_as_z_dimension);
            
            obj.define_product('volume_generator');
            obj.define_product('volume_paths');
            obj.define_product('volume_mask_path');
            obj.define_product('volume_precision');
            obj.define_product('sample_density');
        end
        
        function result = get.spm_precision(obj)
            
            if strcmp(obj.precision, 'single')
                result = 'float32';
            elseif strcmp(obj.precision, 'double')
                result = 'float64';
            else
                error(['geospm.SpatialAnalysis.get.spm_precision(): Unsupported precision ''' obj.precision '''.']);
            end
        end
        
        function result = run(obj, arguments)
            
            % Either render all samples as on-disk volumes, or generate synthetic
            % file paths which can be used to render volumes on the fly.
            
            grid_spatial_index = arguments.(obj.grid_spatial_index_requirement);
            
            volume_generator = obj.create_volume_generator(...
                arguments.directory, ...
                grid_spatial_index, ...
                obj.precision, ...
                arguments.smoothing_method, ...
                arguments.smoothing_levels, ...
                arguments.smoothing_levels_p_value, ...
                arguments.smoothing_levels_as_z_dimension);
            
            index_number = volume_generator.register_spatial_index(grid_spatial_index);
            volume_paths = volume_generator.generate_volume_paths(index_number);

            density = [];
            volume_mask_path = '';

            if obj.write_density
                tic;
                [density, volume_mask_path] = volume_generator.compute_volume_density(index_number);
                elapsedSecs = toc;
                fprintf('Density computation took %.2f seconds for %d volumes.\n', elapsedSecs, grid_spatial_index.S);
                density_path = fullfile(arguments.directory, 'density.nii');
                geospm.utilities.write_nifti(density, density_path);
            end

            result = struct();
            result.volume_generator = volume_generator;
            result.volume_paths = volume_paths;
            result.volume_mask_path = volume_mask_path;
            result.volume_precision = obj.spm_precision;
            result.sample_density = density;
        end
    end
    
    methods (Access=protected)
        
        function result = create_volume_generator(obj, ...
                directory, ...
                grid_spatial_index, ...
                precision, ...
                smoothing_method, ...
                smoothing_levels, ...
                smoothing_levels_p_value, ...
                smoothing_levels_as_z_dimension)
            
            volume_directory = fullfile(directory, 'spm_input');
            
            [dirstatus, dirmsg] = mkdir(volume_directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            overwrite_existing_volumes = false;

            %We need to make sure the SyntheticVolumeGenerator base class 
            %is on the Matlab path, so an SPM interface instance needs 
            %to exist:
            
            geospm.spm.SPMJobList.access_spm_interface();
            
            %smoothing_levels are specified in data units
            smoothing_scale = grid_spatial_index.grid.cell_size;

            if smoothing_levels_as_z_dimension
                smoothing_scale = [smoothing_scale(1:2) smoothing_scale(1)];
            end
            
            if smoothing_scale(1) ~= smoothing_scale(2) || smoothing_scale(1) ~= smoothing_scale(3)
                warning('Grid axes are scaled differently: Taking the maximum value as smoothing scale.');
            end
            
            smoothing_levels = smoothing_levels ./ max(smoothing_scale);
            
            volume_generator_class = str2func(obj.volume_generator_class_name);

            result = volume_generator_class( ...
                    volume_directory, ...
                    grid_spatial_index.resolution, ...
                    precision, ...
                    smoothing_method, ...
                    smoothing_levels, ...
                    smoothing_levels_p_value, ...
                    smoothing_levels_as_z_dimension, ...
                    obj.write_volumes, ...
                    overwrite_existing_volumes);
        end
        
    end
end
