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

classdef DataEvaluator < geospm.validation.Evaluator
    
    %DataEvaluator Encapsulates a method of generating stages in a study.
    %
    
    properties
        grid_options
        
        report_generator
        
        
        set_model_grid
        default_coincident_observations_mode
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
        spatial_data_cache_
    end
    
    methods
        
        function obj = DataEvaluator()
            obj = obj@geospm.validation.Evaluator();
            
            obj.spatial_data_cache_ = hdng.utilities.Dictionary();
            
            obj.grid_options = struct();
            obj.grid_options.spatial_resolution_max = 200;
            
            attribute = obj.result_attributes.define('command_paths');
            attribute.description = 'Command Paths';
            
            attribute = obj.result_attributes.define('spm_output_directory');
            attribute.description = 'SPM Output Directory';
            
            attribute = obj.result_attributes.define('kriging_output_directory');
            attribute.description = 'Kriging Output Directory';
            
            obj.no_targets = true;
            
            obj.report_generator = [];
            
            obj.set_model_grid = true;
            obj.default_coincident_observations_mode = ...
                geospm.models.sampling.Subsampling.IDENTITY_MODE;
            
            attribute = obj.configuration_attributes.define(...
                geospm.validation.Constants.EXPERIMENT);
            attribute.description = 'Experiment';
            
            attribute = obj.configuration_attributes.define(...
                'experiment_label');
            attribute.description = 'Experiment Label';
            
            attribute = obj.configuration_attributes.define(...
                'group_label');
            attribute.description = 'Group Label';

            attribute = obj.configuration_attributes.define(...
                geospm.validation.Constants.SPATIAL_MODEL);
            attribute.description = 'Spatial Model';

            attribute = obj.configuration_attributes.define(...
                geospm.validation.Constants.SAMPLING_STRATEGY);
            attribute.description = 'Sampling Strategy';

            attribute = obj.configuration_attributes.define(...
                geospm.validation.Constants.DOMAIN_EXPRESSION);
            attribute.description = 'Domain Expression';
            
            attribute = obj.configuration_attributes.define(...
                geospm.validation.Constants.SMOOTHING_LEVELS);
            attribute.description = 'Smoothing Levels';
            
            attribute = obj.configuration_attributes.define(...
                geospm.validation.Constants.SMOOTHING_LEVELS_P_VALUE);
            attribute.description = 'Smoothing Levels P Value';
            
            attribute = obj.configuration_attributes.define(...
                geospm.validation.Constants.SMOOTHING_LEVELS_AS_Z_DIMENSION);
            attribute.description = 'Smoothing Levels as Z Dimension';
            
            attribute = obj.configuration_attributes.define(...
                geospm.validation.Constants.SMOOTHING_METHOD);
            attribute.description = 'Smoothing Method';

            attribute = obj.configuration_attributes.define(...
                'spm_regression_thresholds');
            attribute.description = 'SPM Thresholds';

            attribute = obj.configuration_attributes.define(...
                'spm_observation_transforms');
            attribute.description = 'SPM Observation Transforms';

            attribute = obj.configuration_attributes.define(...
                'spm_add_intercept');
            attribute.description = 'SPM Add Intercept';

            
            attribute = obj.configuration_attributes.define(...
                'kriging_thresholds');
            attribute.description = 'Kriging Thresholds';

            attribute = obj.configuration_attributes.define(...
                'image_layers');
            attribute.description = 'Image Layers';
        end
        
        function path = render_map_presentation_layer(~, directory, layer, context)
            
            [image, alpha] = geospm.utilities.generate_map_image(...
                context.spatial_index.crs, ...
                context.grid_min_location(1:2), ...
                context.grid_max_location(1:2), ...
                context.grid_spatial_resolution(1:2) * layer.pixel_density, ...
                layer.layer, ...
                layer.service_identifier);
            
            name = [layer.identifier '.png'];
            path = fullfile(directory, name);
            
            options = struct();

            if ~isempty(alpha)
                options.Alpha = alpha;
            end

            arguments = hdng.utilities.struct_to_name_value_sequence(options);
            
            imwrite(image, path, arguments{:});
        end
        
        function path = render_image_presentation_layer(~, directory, layer, ~)
            
            [~, ~, ext] = fileparts(layer.path);
            path = fullfile(directory, [layer.identifier ext]);
            copyfile(layer.path, path);
        end
        
        function path = render_image_field_presentation_layer(~, directory, layer, context) %#ok<INUSD>
            
            path = [];
            parts = split(layer.record_path, '.');

            if ~strcmp(parts{1}, 'results')
                return
            end

            value = context.results;

            for index=2:numel(parts)
                key = parts{index};

                if ~value.holds_key(key)
                    return
                end

                value = value(key);

                if isa(value, 'hdng.experiments.Value')
                    value = value.content;
                end
            end

            parts = split(layer.property_path, '.');

            for index=1:numel(parts)
                key = parts{index};
                value = value.(key);

                if isa(value, 'hdng.experiments.Value')
                    value = value.content;
                end
            end

            if ~isa(value, 'hdng.experiments.ImageReference')
                return
            end
            
            path = value.path;
        end
        
        function result = render_presentation_layers(obj, base_directory, context)
            
            directory = fullfile(base_directory, 'presentation');
            
            [dirstatus, dirmsg] = mkdir(directory);
            if dirstatus ~= 1; error(dirmsg); end

            result = cell(numel(obj.presentation_layers), 1);
            
            for i=1:numel(obj.presentation_layers)
                layer = obj.presentation_layers{i};
                
                switch layer.type
                    case 'image-file'
                        path = obj.render_image_presentation_layer(directory, layer, context);

                    case 'image-field'
                        path = obj.render_image_field_presentation_layer(directory, layer, context);
                    
                    case 'map'
                        path = obj.render_map_presentation_layer(directory, layer, context);

                    otherwise
                        continue
                end
                
                if startsWith(path, context.canonical_base_path)
                    path = path(numel(context.canonical_base_path)+numel(filesep)+1:end);
                end
                
                image_layer = geospm.validation.ImageLayer();
                image_layer.identifier = layer.identifier;
                image_layer.category = layer.category;
                image_layer.blend_mode = layer.blend_mode;
                image_layer.opacity = layer.opacity;
                image_layer.priority = layer.priority;
                image_layer.image = hdng.experiments.ImageReference(path, context.source_ref);

                result{i} = image_layer;
            end
        end
        
        function apply(obj, evaluation, options)
            
            configuration = evaluation.configuration;
            
            spatial_data_specifier = configuration('spatial_data_specifier');

            [spatial_data, spatial_index] = geospm.load_data_specifier(spatial_data_specifier, obj.spatial_data_cache_);
            
            grid_specifier = obj.grid_options;

            if isfield(spatial_data_specifier, 'min_location')
                grid_specifier.min_location = spatial_data_specifier.min_location;
            else
                grid_specifier.min_location = spatial_index.min_xyz;
            end

            if isfield(spatial_data_specifier, 'max_location')
                grid_specifier.max_location = spatial_data_specifier.max_location;
            else
                grid_specifier.max_location = spatial_index.max_xyz;
            end
            
            grid = geospm.create_grid(grid_specifier);
            
            [spatial_model, domain_expr] = obj.create_wrapper_model(spatial_data, spatial_index, grid.resolution, 'direct', false);
            
            sampling_strategy = geospm.models.sampling.Subsampling();
            
            if configuration.values.holds_key('coincident_observations_mode')
                coincident_observations_mode = configuration('coincident_observations_mode');
            else
                coincident_observations_mode = obj.default_coincident_observations_mode;
            end

            if ~isempty(coincident_observations_mode)
                sampling_strategy.coincident_observations_mode = coincident_observations_mode;
            end
            
            configuration.values(geospm.validation.Constants.SPATIAL_MODEL) = hdng.experiments.Value.from(spatial_model);
            configuration.values(geospm.validation.Constants.SAMPLING_STRATEGY) = hdng.experiments.Value.from(sampling_strategy);
            configuration.values(geospm.validation.Constants.DOMAIN_EXPRESSION) = hdng.experiments.Value.from(domain_expr, char(domain_expr), missing, 'builtin.missing');
            configuration.values('grid') = hdng.experiments.Value.from(grid);

            apply@geospm.validation.Evaluator(obj, evaluation, options);
            
            image_layers = {};

            if ~isempty(obj.presentation_layers)
            
                context = hdng.one_struct( ...
                    'spatial_data', spatial_data, ...
                    'spatial_index', spatial_index, ...
                    'grid_min_location', grid_specifier.min_location, ...
                    'grid_max_location', grid_specifier.max_location, ...
                    'grid_spatial_resolution', grid.resolution, ...
                    'source_ref', evaluation.source_ref, ...
                    'canonical_base_path', evaluation.canonical_base_path, ...
                    'results', evaluation.results);

                image_layers = obj.render_presentation_layers(evaluation.directory, context);
            end

            if ~isfield(spatial_data.attachments, 'group_label')
                spatial_data.attachments.group_label = configuration.values('experiment_label').label;
            end

            configuration.values('image_layers') = hdng.experiments.Value.from(image_layers, 'Image Layers');
            configuration.values('group_label') = hdng.experiments.Value.from(spatial_data.attachments.group_identifier, spatial_data.attachments.group_label);

            if ~isempty(obj.report_generator)
                obj.report_generator.gather(evaluation, obj.last_experiment);
            end
        end
        
    end
    
    methods (Access=protected)
        

        function domain = build_data_domain(~, spatial_data)
            
            domain = geospm.models.Domain();
            variable_names = spatial_data.variable_names;
            
            for i=1:numel(variable_names)
                name = variable_names{i};
                geospm.models.Variable(domain, name);
            end
        end
        
        function [result, domain_expr] = create_wrapper_model(obj, spatial_data, spatial_index, resolution, encoding, ignore_constant)
            
            result = struct();
            result.model = [];
            result.metadata = struct();
            
            domain = obj.build_data_domain(spatial_data);
            
            result.model = geospm.models.SpatialModel(domain, resolution);
            result.model.attachments.spatial_data = spatial_data;
            result.model.attachments.spatial_index = spatial_index;
            
            encodings = geospm.models.DomainEncodings();
            encoding_method = encodings.resolve_encoding_method(encoding);
            domain_expr = encoding_method(encodings, domain);
            
            if ignore_constant
                domain_expr.add_regression_intercept = false;
            end
        end
        
        function created_experiment(obj, experiment, evaluation, ~)
            
            if (obj.add_georeference_to_images || obj.set_model_grid) && isprop(experiment, 'model_grid')
                configuration = evaluation.configuration;
                grid = configuration('grid');
                experiment.model_grid = grid;
                %experiment.model_grid = experiment.sampling_strategy.grid;
            end
        end
    end
    
end
