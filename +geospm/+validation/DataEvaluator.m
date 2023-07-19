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
        
        geospm_arguments
        kriging_arguments
        report_generator
        
        adjust_variance
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
            
            obj.geospm_arguments = struct();
            
            obj.geospm_arguments.smoothing_levels = [10 20 30 50] * 100;
            obj.geospm_arguments.smoothing_levels_p_value = 0.95;
            obj.geospm_arguments.trace_thresholds = false;
            obj.geospm_arguments.spm_add_intercept = true;
            obj.geospm_arguments.spm_thresholds = { 'T[1,2]: p<0.05 (FWE)' };
            
            obj.kriging_arguments = struct();
            obj.kriging_arguments.max_kriging_distance = [];
            obj.kriging_arguments.kriging_kernel = { 'Mat' };
            obj.kriging_arguments.kriging_thresholds = { 'normal [1,2]: p < 0.05' };
            
            attribute = obj.result_attributes.define('command_paths');
            attribute.description = 'Command Paths';
            
            attribute = obj.result_attributes.define('spm_output_directory');
            attribute.description = 'SPM Output Directory';
            
            attribute = obj.result_attributes.define('kriging_output_directory');
            attribute.description = 'Kriging Output Directory';
            
            obj.no_targets = true;
            
            obj.report_generator = [];
            
            obj.adjust_variance = false;
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
        
            mapping_service = hdng.maps.MappingService.lookup(layer.service_identifier);

            image = mapping_service.generate( ...
                context.spatial_data.crs, ...
                context.grid_min_location, ...
                context.grid_max_location, ...
                context.grid_spatial_resolution(1:2) * layer.pixel_density, ...
                {layer.layer});
            
            name = [layer.identifier '.png'];
            path = fullfile(directory, name);

            imwrite(image{1}, path);
        end
        
        function path = render_image_presentation_layer(~, directory, layer, ~)
            
            [~, ~, ext] = fileparts(layer.path);
            path = fullfile(directory, [layer.identifier ext]);
            copyfile(layer.path, path);
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
                    
                    case 'map'
                        path = obj.render_map_presentation_layer(directory, layer, context);

                    otherwise
                        continue
                end
                
                
                path = path(numel(context.canonical_base_path)+numel(filesep)+1:end);
                
                image_layer = geospm.validation.ImageLayer();
                image_layer.identifier = layer.identifier;
                image_layer.category = layer.category;
                image_layer.blend_mode = layer.blend_mode;
                image_layer.image = hdng.experiments.ImageReference(path, context.source_ref);

                result{i} = image_layer;
            end
        end
        
        function apply(obj, evaluation, options)
            
            configuration = evaluation.configuration;
            
            method = configuration('method');
            
            if configuration.values.holds_key('coincident_observations_mode')
                coincident_observations_mode = configuration('coincident_observations_mode');
            else
                coincident_observations_mode = obj.default_coincident_observations_mode;
            end
            
            grid_options_copy = obj.grid_options;
            
            spatial_data_specifier = configuration('spatial_data_specifier');
            
            if isstruct(spatial_data_specifier)
            
                if isfield(spatial_data_specifier, 'min_location')
                    grid_options_copy.min_location = spatial_data_specifier.min_location;
                    spatial_data_specifier = rmfield(spatial_data_specifier, 'min_location');
                end

                if isfield(spatial_data_specifier, 'max_location')
                    grid_options_copy.max_location = spatial_data_specifier.max_location;
                    spatial_data_specifier = rmfield(spatial_data_specifier, 'max_location');
                end
                
                spatial_data = obj.load_spatial_data(spatial_data_specifier);
            
            elseif isa(spatial_data_specifier, 'geospm.NumericData')
                
                spatial_data = spatial_data_specifier;
            else
                error('Invalid value for ''spatial_data_specifier''. Expected struct or geospm.NumericData.');
            end
            
            if ~isfield(grid_options_copy, 'grid')
                grid_options_copy = geospm.auxiliary.parse_spatial_resolution(spatial_data, grid_options_copy);

                grid_options_copy.grid = geospm.Grid();

                grid_options_copy.grid.span_frame( ...
                    grid_options_copy.min_location, ...
                    grid_options_copy.max_location, ...
                    grid_options_copy.spatial_resolution);

                grid_min_location = grid_options_copy.min_location;
                grid_max_location = grid_options_copy.max_location;
                grid_spatial_resolution = grid_options_copy.spatial_resolution;
            else
                grid_options_copy.grid = grid_options_copy.grid.clone();
                grid_min_location = grid_options_copy.grid.origin(1:2);
                grid_max_location = grid_options_copy.grid.cell_size(1:2) .* grid_options_copy.grid.resolution(1:2);
                grid_spatial_resolution = grid_options_copy.grid.resolution;
            end
            
            spm_arguments_copy = obj.geospm_arguments;
            
            if ~isfield(spm_arguments_copy, 'spm_add_intercept')
            	spm_arguments_copy.spm_add_intercept = true;
            end
            
            [spatial_model, domain_expr] = obj.create_dummy_model(spatial_data, grid_options_copy.grid.resolution(1:2), 'direct', false);
            
            sampling_strategy = geospm.models.sampling.Subsampling(grid_options_copy.grid);
            
            if ~isempty(coincident_observations_mode)
                sampling_strategy.coincident_observations_mode = coincident_observations_mode;
            end
            
            if strcmp(method, 'SPM')
                
                settings = struct();
                settings.experiment_type = 'geospm.validation.experiments.SPMRegression';
                settings.description = 'SPM';
                settings.extra_variables = {};
                settings.extra_requirements = {
                    geospm.validation.Constants.DOMAIN_EXPRESSION, ...
                    geospm.validation.Constants.SMOOTHING_LEVELS, ...
                    geospm.validation.Constants.SMOOTHING_LEVELS_P_VALUE, ...
                    geospm.validation.Constants.SMOOTHING_METHOD, ...
                    'spm_regression_thresholds', ...
                    'spm_observation_transforms', ...
                    'spm_add_intercept'
                };
                
                if ~isfield(spm_arguments_copy, 'smoothing_levels')
                    spm_arguments_copy.smoothing_levels = [10 20 30 50];
                end

                if ~isfield(spm_arguments_copy, 'smoothing_levels_p_value')
                    spm_arguments_copy.smoothing_levels_p_value = 0.95;
                end

                if ~isfield(spm_arguments_copy, 'smoothing_method')
                    spm_arguments_copy.smoothing_method = 'default';
                end

                if ~isfield(spm_arguments_copy, 'spm_thresholds')
                    spm_arguments_copy.spm_thresholds = { 'T[1,2]: p<0.05 (FWE)' };
                end

                if ~isfield(spm_arguments_copy, 'spm_observation_transforms')
                    spm_arguments_copy.spm_observation_transforms = { geospm.stages.ObservationTransform.IDENTITY };
                end
                
                spm_arguments_copy.spm_thresholds = geospm.SignificanceTest.from_char(spm_arguments_copy.spm_thresholds);
                
                configuration.values(geospm.validation.Constants.SMOOTHING_LEVELS) = ...
                    hdng.experiments.Value.from(spm_arguments_copy.smoothing_levels);
                
                configuration.values(geospm.validation.Constants.SMOOTHING_LEVELS_P_VALUE) = ...
                    hdng.experiments.Value.from(spm_arguments_copy.smoothing_levels_p_value);
                
                configuration.values(geospm.validation.Constants.SMOOTHING_METHOD) = ...
                    hdng.experiments.Value.from(spm_arguments_copy.smoothing_method);
                
                configuration.values('spm_regression_thresholds') = ...
                    hdng.experiments.Value.from(spm_arguments_copy.spm_thresholds);
                
                configuration.values('spm_observation_transforms') = ...
                    hdng.experiments.Value.from(spm_arguments_copy.spm_observation_transforms{1});
                
                configuration.values('spm_add_intercept') = ...
                    hdng.experiments.Value.from(spm_arguments_copy.spm_add_intercept);
                
            elseif strcmp(method, 'Kriging')
                
                settings = struct();
                settings.experiment_type = 'geospm.validation.experiments.Kriging';
                settings.description = 'Kriging';
                settings.extra_variables = {};
                settings.extra_requirements = {
                    geospm.validation.Constants.DOMAIN_EXPRESSION, ...
                    'kriging_thresholds', ...
                    'variogram_function', ...
                    'add_nugget' };
                
                kriging_arguments_copy = obj.kriging_arguments;
                
                if ~isfield(kriging_arguments_copy, 'kriging_thresholds')
                    kriging_arguments_copy.kriging_thresholds = { 'normal [1,2]: p < 0.05' };
                end
                
                kriging_arguments_copy.kriging_thresholds = geospm.SignificanceTest.from_char(kriging_arguments_copy.kriging_thresholds);
                
                configuration.values('kriging_thresholds') = ...
                    hdng.experiments.Value.from(kriging_arguments_copy.kriging_thresholds);
                
            else
                error('DataEvaluator.apply(): Unknown method \"%s\".', method);
            end
            
            configuration.values(geospm.validation.Constants.EXPERIMENT) = hdng.experiments.Value.from(settings, settings.description);
            configuration.values(geospm.validation.Constants.SPATIAL_MODEL) = hdng.experiments.Value.from(spatial_model);
            configuration.values(geospm.validation.Constants.SAMPLING_STRATEGY) = hdng.experiments.Value.from(sampling_strategy);
            configuration.values(geospm.validation.Constants.DOMAIN_EXPRESSION) = hdng.experiments.Value.from(domain_expr, char(domain_expr), missing, 'builtin.missing');
            
            apply@geospm.validation.Evaluator(obj, evaluation, options);
            
            image_layers = {};

            if ~isempty(obj.presentation_layers)

                context = hdng.one_struct( ...
                    'spatial_data', spatial_data, ...
                    'grid_min_location', grid_min_location, ...
                    'grid_max_location', grid_max_location, ...
                    'grid_spatial_resolution', grid_spatial_resolution, ...
                    'source_ref', evaluation.source_ref, ...
                    'canonical_base_path', evaluation.canonical_base_path);

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
        
        function spatial_data = load_spatial_data(obj, specifier)

            file_path = specifier.file_path;
            
            if ~isfield(specifier, 'include')
                specifier.include = [];
            end
            
            if ~isfield(specifier, 'bool_variables')
                specifier.bool_variables = [];
            end
            
            if ~isfield(specifier, 'standardise')
                specifier.standardise = [];
            end
            
            if ~isfield(specifier, 'interactions')
                specifier.interactions = [];
            end
            
            if ~isfield(specifier, 'identifier')
                specifier.identifier = '';
            end
            
            if ~isfield(specifier, 'label')
                specifier.label = specifier.identifier;
            end
            
            if ~isfield(specifier, 'group_identifier')
                specifier.group_identifier = '';
            end
            
            if ~isfield(specifier, 'group_label')
                specifier.group_label = specifier.group_identifier;
            end
            
            if ~isfield(specifier, 'variable_labels')
                specifier.variable_labels = struct();
            end
            
            
            tmp = specifier;
            tmp = rmfield(tmp, 'file_path');
            tmp = rmfield(tmp, 'include');
            tmp = rmfield(tmp, 'bool_variables');
            tmp = rmfield(tmp, 'standardise');
            tmp = rmfield(tmp, 'interactions');
            tmp = rmfield(tmp, 'identifier');
            tmp = rmfield(tmp, 'label');
            tmp = rmfield(tmp, 'group_identifier');
            tmp = rmfield(tmp, 'group_label');
            tmp = rmfield(tmp, 'variable_labels');
            
            arguments = hdng.utilities.struct_to_name_value_sequence(tmp);
            
            if ~obj.spatial_data_cache_.holds_key(file_path)
                spatial_data = geospm.load_data(file_path, arguments{:}, 'mask_columns_with_missing_values', false, 'mask_rows_with_missing_values', false);
                obj.spatial_data_cache_(file_path) = spatial_data;
            else
                spatial_data = obj.spatial_data_cache_(file_path);
            end
            
            columns = [];
            
            if ~isempty(specifier.include)
                for i=1:numel(specifier.include)
                    name = specifier.include{i};
                    index = find(strcmp(name, spatial_data.variable_names));
                    columns = [columns, index]; %#ok<AGROW>
                end
            else
                columns = 1:spatial_data.P;
            end
            
            rows = ~any(isnan(spatial_data.observations(:, columns)), 2);
            spatial_data = spatial_data.select(rows, columns, ...
                @(args) obj.transform_spatial_data(args, specifier.standardise));
            
            if ~isempty(specifier.interactions)
                
                spatial_data = spatial_data.select(...
                    [], ...
                    [], ...
                    @(args) geospm.validation.DataEvaluator.add_interactions(args, specifier.interactions));
            end
            
            spatial_data.attachments.group_identifier = specifier.group_identifier;
            spatial_data.attachments.group_label = specifier.group_label;
            spatial_data.attachments.variable_labels = specifier.variable_labels;
        end
        
        function domain = build_data_domain(~, spatial_data)
            
            domain = geospm.models.Domain();
            variable_names = spatial_data.variable_names;
            
            for i=1:numel(variable_names)
                name = variable_names{i};
                geospm.models.Variable(domain, name);
            end
        end
        
        function [result, domain_expr] = create_dummy_model(obj, spatial_data, resolution, encoding, ignore_constant)
            
            result = struct();
            result.model = [];
            result.metadata = struct();
            
            domain = obj.build_data_domain(spatial_data);
            
            result.model = geospm.models.SpatialModel(domain, resolution);
            result.model.attachments.spatial_data = spatial_data;
            
            encodings = geospm.models.DomainEncodings();
            encoding_method = encodings.resolve_encoding_method(encoding);
            domain_expr = encoding_method(encodings, domain);
            
            if ignore_constant
                domain_expr.add_regression_intercept = false;
            end
        end
        
        function args = transform_spatial_data(~, args, standardise)
            args.check_for_nans = true;
            
            for i=1:numel(standardise)
                name = standardise{i};
                index = find(strcmp(name, args.variable_names), 1);
                
                if isempty(index)
                    continue;
                end
                
                values = args.observations(:, index);
                args.observations(:, index) = (values - mean(values, 'omitnan')) ./ std(values, 'omitnan');
            end
        end
        
        function created_experiment(obj, experiment)
            
            if isprop(experiment, 'adjust_variance')
                experiment.adjust_variance = obj.adjust_variance;
            end
            
            if (obj.add_georeference_to_images || obj.set_model_grid) && isprop(experiment, 'model_grid')
                experiment.model_grid = experiment.sampling_strategy.grid;
            end
        end
    end
    
    methods (Static, Access=public)
        
        function result = create_file_specifier(file_path, varargin)
            
            %{
                crs_identifier - coordinate reference identifier
                csv_delimiter - csv delimiter, defaults to comma
                eastings_label - char vector for eastings label
                northings_label - char vecgtor for northings label
                include - cell array of variable names
                bool_variables - cell array of boolean variable names
                standardise - cell array of variable names
                interactions - cell matrix of interactions
                min_location - [x, y] min location
                max_location - [x, y] max location
            %}
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'crs_identifier')
                options.crs_identifier = '';
            end
            
            if ~isfield(options, 'csv_delimiter')
                options.csv_delimiter = ',';
            end
            
            if ~isfield(options, 'eastings_label')
                options.eastings_label = 'easting';
            end
            
            if ~isfield(options, 'northings_label')
                options.northings_label = 'northing';
            end
            
            if ~isfield(options, 'include')
                options.include = {};
            end
            
            if ~isfield(options, 'bool_variables')
                options.bool_variables = {};
            end
            
            if ~isfield(options, 'standardise')
                options.standardise = {};
            end
            
            if ~isfield(options, 'interactions')
                options.interactions = {};
            end
            
            if ~isfield(options, 'min_location')
                options.min_location = [-Inf, -Inf];
            end
            
            if ~isfield(options, 'max_location')
                options.max_location = [Inf, Inf];
            end
            
            result.file_path = file_path;
            result.crs_identifier = options.crs_identifier;
            result.csv_delimiter = options.csv_delimiter;
            result.eastings_label = options.eastings_label;
            result.northings_label = options.northings_label;
            result.include = options.include;
            result.bool_variables = options.bool_variables;
            result.standardise = options.standardise;
            result.interactions = options.interactions;
            result.min_location = options.min_location;
            result.max_location = options.max_location;
        end

        function args = add_interactions(args, pairs)

            N = size(pairs, 1);
            P = size(args.observations, 2);

            observations = [args.observations, zeros(size(args.observations, 1), N)];

            for i=1:N
                var1 = pairs{i, 1};
                var2 = pairs{i, 2};

                index1 = find(strcmp(var1, args.variable_names), 1);
                index2 = find(strcmp(var2, args.variable_names), 1);

                if isempty(index1) || isempty(index2)
                    error('Couldn''t define interaction.');
                end

                observations(:, P + i) = args.observations(:, index1) .* args.observations(:, index2);
                args.variable_names = [args.variable_names, {[var1 '_x_' var2]}];
            end

            args.observations = observations;
        end

    end
    
end
