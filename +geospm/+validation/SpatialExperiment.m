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

classdef SpatialExperiment < handle
    %SpatialExperiment Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        
        NIFTI_KEEP = 'keep'
        NIFTI_COMPRESS = 'compress'
        NIFTI_DELETE = 'delete'
        
        REGULAR_MODE = 'regular'
        DEFERRED_MODE = 'deferred'
        RESUME_MODE = 'resume'
        LOAD_MODE = 'load'
        
    end
    
    properties
        
        seed
        rng
        
        model_seed
        
        directory
        canonical_base_path
        
        run_mode
        
        nifti_mode
        nifti_files
        
        model
        model_grid
        model_metadata
        
        sampling_strategy
        N_samples
        
        add_probes
        
        domain_expression
        expression_data_name
        
        model_data
        spatial_data_expression
        spatial_data
        
        do_write_spatial_data
        write_z_coordinate
        
        N_probe_samples
        probe_data
        
        no_targets
        load_targets
        
        colour_map_mode
        colour_map
        
        add_georeference_to_images
        
        results
        result_attributes
        
        diagnostics
    end
    
    properties (Dependent, Transient)
        
        directory_name
        directory_path
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    
    methods
        
        function obj = SpatialExperiment(...
                        seed, ...
                        directory, ...
                        run_mode, ...
                        nifti_mode, ...
                        model_and_metadata, ...
                        sampling_strategy, ...
                        N_samples, ...
                        domain_expression)
            
            obj.directory = directory;
            obj.canonical_base_path = directory;
            
            obj.run_mode = run_mode;
            
            if isempty(nifti_mode)
                nifti_mode = geospm.validation.SpatialExperiment.NIFTI_KEEP;
            end
            
            obj.nifti_mode = nifti_mode;
            obj.nifti_files = {};
            
            obj.seed = seed;
            obj.rng = RandStream.create('mt19937ar', 'Seed', obj.seed);
            obj.model_seed = cast(obj.rng.randi(2^31, 1), 'uint32');
            
            obj.model = model_and_metadata.model;
            obj.model_grid = [];
            
            if isfield(model_and_metadata, 'model_grid')
                obj.model_grid = model_and_metadata.model_grid;
            end
            
            if isempty(obj.model_grid)
                obj.model_grid = geospm.Grid();
                obj.model_grid.span_frame([1, 1, 0], [obj.model.spatial_resolution + 1 0], obj.model.spatial_resolution);
            end
            
            obj.model_metadata = model_and_metadata.metadata;
            
            obj.do_write_spatial_data = true;
            obj.write_z_coordinate = true;
            
            obj.sampling_strategy = sampling_strategy;
            
            obj.N_samples = N_samples;
            
            obj.add_probes = false;
            
            obj.domain_expression = domain_expression;
            obj.expression_data_name = 'experiment_data';
            
            obj.spatial_data_expression = domain_expression;
            
            obj.model_data = [];
            obj.spatial_data = [];
            
            obj.N_probe_samples = 500;
            obj.probe_data = [];
            
            obj.no_targets = false;
            obj.load_targets = false;
            
            obj.colour_map = hdng.colour_mapping.GenericColourMap.twilight_27();
            obj.colour_map_mode = hdng.colour_mapping.ColourMap.LAYER_MODE;
            
            obj.add_georeference_to_images = true;
            
            obj.results = hdng.utilities.Dictionary();
            obj.result_attributes = hdng.experiments.RecordAttributeMap();
            
            attribute = obj.result_attributes.define('terms');
            attribute.description = 'Model Terms';
            
            attribute = obj.result_attributes.define('model_samples');
            attribute.description = 'Model Samples';
            
            attribute = obj.result_attributes.define('files');
            attribute.description = 'Model Files';
            
            attribute = obj.result_attributes.define('command_paths');
            attribute.description = 'Command Paths';
            
            attribute = obj.result_attributes.define('duration');
            attribute.description = 'Computation Duration [secs]';
            
            obj.diagnostics = {};
        end
        
        function result = get.directory_name(obj)
            [~, name, ext] = fileparts(obj.directory);
            result = [name, ext];
        end
        
        function result = get.directory_path(obj)
            [result, ~, ~] = fileparts(obj.directory);
        end
        
        function result = canonical_path(obj, local_path)
            
            prefix = obj.canonical_base_path;
            
            if startsWith(local_path, prefix)
                result = local_path(numel(prefix)+numel(filesep)+1:end);
            else
                result = local_path;
            end
        end
        
        function result = absolute_path(obj, local_path)
            result = hdng.utilities.make_absolute_path(local_path, obj.canonical_base_path);
        end
        
        function log_diagnostic(obj, issue, action_taken)
            
            diagnostic = struct();
            diagnostic.issue = issue;
            diagnostic.action_taken = action_taken;
            
            obj.diagnostics = [obj.diagnostics; diagnostic];
        end
        
        function load(obj)
            
            if numel(obj.directory) == 0
                error('SpatialExperiment.load(): Missing directory.');
            end
            
            if ~exist(obj.directory, 'dir')
                error('SpatialExperiment.load(): No directory at path %s.', obj.directory);
            end
            
            
        
        end
        
        function run(obj)
            
            if numel(obj.directory) == 0
                obj.directory = fullfile(pwd, char(datetime('now', 'TimeZone', 'local', 'Format', 'yyyy_MM_dd_HH_mm_ss')));
            else
                
                if ~startsWith(obj.directory, filesep)
                    obj.directory = fullfile(pwd, obj.directory);
                end
            end
            
            [dirstatus, dirmsg] = mkdir(obj.directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            file_records = hdng.utilities.Dictionary();
            
            obj.model_data = obj.sampling_strategy.observe(obj.model, obj.N_samples, obj.model_seed);
            obj.write_model_files(file_records);
            
            if obj.add_probes
                obj.probe_data = obj.define_probes();
            end
            
            obj.compute_spatial_data();
            %obj.spatial_data.show_variogram();
            obj.write_spatial_data(file_records, ~obj.write_z_coordinate);
            
            terms = hdng.experiments.RecordArray();
            
            obj.results('terms') = hdng.experiments.Value.from(terms, 'No terms.');
            
            model_samples = geospm.validation.ModelSamples();
            model_samples.file = file_records('model_data.json').content;
            model_samples.image = file_records('model_data.png').content;
            obj.results('model_samples') = hdng.experiments.Value.from(model_samples);
            
            obj.results('files') = hdng.experiments.Value.from(file_records);
            obj.results('command_paths') = hdng.experiments.Value.empty_with_label('No command files.');
            obj.results('duration') = hdng.experiments.Value.from(0.0);
        end
        
        function cleanup(obj)
            obj.process_nifti_files(obj.nifti_files);
        end
        
        function result = define_probes(obj)
            
            K = obj.N_probe_samples;
            
            N = size(obj.model.probes, 1);
            
            % Create K * N samples in the unit circle
            samples = obj.rng.rand(K * N, 2);
            samples(:, 2) = sqrt(samples(:, 2));
            samples = samples(:, 2) .* [cos(2 * pi * samples(:, 1)), sin(2 * pi * samples(:, 1))];
            
            % Transform the K samples of each probe to match the probe's centre
            % and radius.
            
            for i=1:N
                
                probe = obj.model.probes(i, :);
                probe_xy = probe(1:2);
                probe_radius = probe(3);
                
                j = i - 1;
                
                samples((j * K + 1):(i * K), :) = samples((j * K + 1):(i * K), :) .* probe_radius + probe_xy;
            end
            
            result = geospm.SpatialData(samples(:, 1), samples(:, 2), zeros(K * N, 1), []);
            
            %Use the probe number as the category
            categories = repelem((1:N)', K);
            result.set_categories(categories);
            
            scatter_plot_path = fullfile(obj.directory, ['probes' '.eps']);
            result.write_as_eps(scatter_plot_path, [1, 1], obj.model.spatial_resolution + 1);
            
            scatter_plot_path = fullfile(obj.directory, ['probes' '.png']);
            result.write_as_png(scatter_plot_path, [1, 1], obj.model.spatial_resolution + 1);
        end
        
        function category_map = map_categories(obj)
            
            category_map = containers.Map('KeyType', 'int64', 'ValueType', 'any');
            
            for i=1:obj.spatial_data.N
                
                category = obj.spatial_data.categories(i);
                
                if ~isKey(category_map, category)
                    category_map(category) = obj.spatial_data.observations(i, :);
                end
            end
        end
        
        function result = select_unique_rows(~, matrix)
            
            
            result = containers.Map('KeyType', 'double', 'ValueType', 'any');
            
            for i=1:size(matrix, 1)
                
                row = matrix(i, :);
                
                if ~isKey(result, row)
                    selected_rows = all(matrix == row, 2);
                    result(row) = selected_rows;
                end
            end
        end
        
        function [means, deviations, category_map] = summarise_probes(obj, probe_file)
            
            if ~obj.add_probes
                return
            end
            
            probes = load(probe_file);
            
            N_probes = size(obj.model.probes, 1);
            N_smoothing_levels = numel(probes.smoothing_levels);
            
            %This codes assumes binary levels
            
            category_map = obj.map_categories();
            categories = keys(category_map);
            
            category_selectors = zeros(obj.spatial_data.N, numel(categories), 'logical');
            
            for k=1:numel(categories)
                category = categories{k};
                category_selectors(:, k) = obj.spatial_data.categories == category;
            end
            
            % The COLUMN layout for probes.volume_values is:
            %
            % level 1 probe 1 sample 1
            %         ...
            %         probe 1 sample k
            %         probe 2 sample 1
            %         ...
            %         probe 2 sample k
            %         ...
            % level 2 probe 1 sample 1
            %         ...
            %         probe 1 sample k
            %         probe 2 sample 1
            %         ...
            %         probe 2 sample k
            %         ...
            % ...
            
            means = zeros(N_probes, numel(categories), N_smoothing_levels);
            deviations = zeros(N_probes, numel(categories), N_smoothing_levels);
            sample_sizes = zeros(N_probes, numel(categories), N_smoothing_levels);
            
            for smoothing_level=1:N_smoothing_levels
                
                level_selector = probes.sample_location(:, 3) == smoothing_level;
                
                for probe=1:N_probes
                    
                    probe_selector = probes.sample_probe_id == probe;
                    sample_selector = level_selector & probe_selector;
                    
                    for k=1:numel(categories)
                        
                        samples = probes.volume_values(category_selectors(:, k), sample_selector);
                        
                        category_mean = mean(samples(:));
                        category_std = std(samples(:));
                        
                        means(probe, k, smoothing_level) = category_mean;
                        deviations(probe, k, smoothing_level) = category_std;
                        sample_sizes(probe, k, smoothing_level) = numel(samples);
                    end
                end
            end
            
            variable_terms = cell2mat(obj.variable_term_indices());
            variable_names = cell(1, numel(variable_terms));
            variable_order = zeros(1, numel(variable_terms));
            
            domain = obj.model.domain;
            
            for i=1:numel(variable_terms)
                index = variable_terms(i);
                term = obj.domain_expression.terms{index};
                variable_names{i} = term.variables{1};
                
                [did_find, variable] = domain.variable_for_name(variable_names{i});
                
                if ~did_find
                    error('Expected to find variable with name \"%s\" in domain.', variable_names{i});
                end
                
                variable_order(i) = variable.nth_variable;
            end
            
            variable_terms = variable_terms(variable_order);
            variable_names = variable_names(variable_order); %#ok<NASGU>
            
            conditions = zeros(numel(categories), numel(variable_terms));
            
            for k=1:numel(categories)
                category = categories{k};
                observation = category_map(category) > 0.5;
                conditions(k, :) = observation(variable_terms);
            end
            
            distributions = cell(N_probes, 1);
            
            for i=1:N_probes
                [masses, ~] = obj.model.joint_distribution.value_at(obj.model.probes(i, 1), obj.model.probes(i, 2));
                distributions{i} = masses; 
            end
            
            smoothing_levels = probes.smoothing_levels;
            
            file_path = fullfile(obj.directory, 'regression_probe_result.mat');
            save(file_path, 'means', 'deviations', 'sample_sizes', 'conditions', 'smoothing_levels', 'distributions');
            
            obj.graph_probes(means, deviations, conditions, smoothing_levels);
        end
        
        
        function graph_probes(obj, means, deviations, conditions, smoothing_levels) %#ok<INUSL>
            
            N_variables = obj.model.domain.N_variables;
            
            if N_variables ~= 2
                return;
            end
            
            N_probes = size(means, 1);
            N_conditions = size(means, 2);
            
            if N_conditions ~= size(conditions, 1)
                return;
            end
            
            line_conditions_map = obj.select_unique_rows(conditions(:, 2:end));
            line_conditions = keys(line_conditions_map);
            
            N_smoothing_levels = numel(smoothing_levels);
            
            domain = obj.model.domain;
            variable_names = domain.variable_names;
            
            colours = {
             '#FF6633', ...
             '#00CC66', ...
             '#00CCFF'
            };
            
            for smoothing_level=1:N_smoothing_levels
                
                f = figure;

                set(f, 'Units', 'points');
                set(f, 'Position', [100 100 400 1600]);
                
                for probe=1:N_probes
                    
                    subplot(N_probes, 1, probe);

                    line_handles = [];
                    line_labels = cell(1, numel(line_conditions));
                    
                    hold on;
                    
                    for k=1:numel(line_conditions)
                        line_condition = line_conditions{k};
                        selection = line_conditions_map(line_condition);
                        
                        X = conditions(selection, 1);
                        [X, order] = sort(X);
                        
                        Y = means(probe, selection, smoothing_level);
                        Y = Y(order);
                        
                        
                        line_handle = line(X, Y, 'Color', colours{k}, 'LineWidth', 3.0);
                        xticks(X);
                        scatter(X, Y, 36.0, 'filled', 'Marker', 'o', 'MarkerEdgeColor', colours{k}, 'MarkerFaceColor', 'white', 'LineWidth', 3.0);
                        
                        line_handles = [line_handles, line_handle]; %#ok<AGROW>
                        line_labels{k} = sprintf('%s = %d', variable_names{2}, line_condition);
                    end

                    hold off;
                    
                    xlabel(sprintf('%s Levels', variable_names{1}));
                    
                    ylabel('Mean Concentration');
                    title(sprintf('Probe %d', probe));
                    legend(line_handles, line_labels);
                end
                
                ax = gca;
                file_path = fullfile(obj.directory, sprintf('probe_plots_smoothing_level_%d.png', smoothing_level));
                saveas(ax, file_path, 'png');
                
                close(f);
            end
        end
        
        function result = variable_term_indices(obj)

            variable_map = containers.Map('KeyType', 'char', 'ValueType', 'logical');
            
            result = {};

            for i=1:obj.domain_expression.N_terms
                term = obj.domain_expression.terms{i};

                if numel(term.variables) ~= 1
                    continue
                end
                
                if isKey(variable_map, term.variables{1})
                    continue
                end
                
                variable_map(term.variables{1}) = true;
                
                result = [result, {i}]; %#ok<AGROW>
            end
        end
        
        function compute_spatial_data(obj)
            obj.spatial_data = obj.spatial_data_expression.compute_spatial_data(obj.model.domain, obj.model_data);
        end
        
        function write_spatial_data(obj, file_records, drop_z)
            
            if ~exist('drop_z', 'var')
                drop_z = ~obj.write_z_coordinate;
            end
            
            expression_data_path = fullfile(obj.directory, [obj.expression_data_name '.csv']);
            expression_data_options = struct('include_categories', false, 'include_labels', false, 'drop_z', drop_z);
            
            if obj.do_write_spatial_data && obj.should_write_files()
                obj.spatial_data.write_as_csv(expression_data_path, expression_data_options);
            end
                
            file = hdng.experiments.FileReference();
            file.path = obj.canonical_path(expression_data_path);
            file_records([obj.expression_data_name '.csv']) = hdng.experiments.Value.from(file); %#ok<NASGU>
        end
        
        function result = should_write_files(obj)
            result = ~strcmp(obj.run_mode, geospm.validation.SpatialExperiment.RESUME_MODE) ...
                        && ~strcmp(obj.run_mode, geospm.validation.SpatialExperiment.LOAD_MODE);
        end
        
        function write_model_files(obj, file_records)
            
            model_data_name = 'model_data';
            
            model_data_path = fullfile(obj.directory, [model_data_name '.json']);
            
            if obj.should_write_files()
                obj.model_data.write_as_json(model_data_path);
            end
            
            file = hdng.experiments.FileReference();
            file.path = obj.canonical_path(model_data_path);
            file_records('model_data.json') = hdng.experiments.Value.from(file);
            
            model_data_path = fullfile(obj.directory, [model_data_name '.csv']);
            
            if obj.should_write_files()
                obj.model_data.write_as_csv(model_data_path);
            end
            
            file = hdng.experiments.FileReference();
            file.path = obj.canonical_path(model_data_path);
            file_records('model_data.csv') = hdng.experiments.Value.from(file);
            
            scatter_plot_path = fullfile(obj.directory, [model_data_name '.eps']);
            
            if obj.should_write_files()
                obj.model_data.write_as_eps(scatter_plot_path, [1, 1], obj.model.spatial_resolution + 1);
            end
            
            file = hdng.experiments.FileReference();
            file.path = obj.canonical_path(scatter_plot_path);
            file_records('model_data.eps') = hdng.experiments.Value.from(file);
            
            scatter_plot_path = fullfile(obj.directory, [model_data_name '.png']);
            
            if obj.should_write_files()
                obj.model_data.write_as_png(scatter_plot_path, [1, 1], obj.model.spatial_resolution + 1);
            end
            
            file = hdng.experiments.ImageReference();
            file.path = obj.canonical_path(scatter_plot_path);
            file_records('model_data.png') = hdng.experiments.Value.from(file); %#ok<NASGU>
        end
        
        function targets = compute_targets(obj)
            targets = geospm.models.utilities.compute_model_targets(...
                obj.model, obj.domain_expression, 'min');
        end
        
        function result = write_targets(obj, add_regular_targets, add_inverted_targets)
            
            %The targets are summarised as a record array with the following
            %fields:
            %
            %   *term: name of the model term
            %
            %   target: path to target nifti
            %
            
            if ~exist('add_regular_targets', 'var')
                add_regular_targets = true;
            end
            
            if ~exist('add_inverted_targets', 'var')
                add_inverted_targets = false;
            end
            
            result = hdng.experiments.RecordArray();
            
            targets_directory = fullfile(obj.directory, 'targets');
            
            [dirstatus, dirmsg] = mkdir(targets_directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            is_rehearsal = strcmp(obj.run_mode, geospm.validation.SpatialExperiment.RESUME_MODE);
            
            if obj.no_targets
                
                term_names = obj.domain_expression.term_names;

                for index=1:numel(term_names)
                    term_name = term_names{index};
                    
                    target = hdng.utilities.Dictionary();
                    target('term') = hdng.experiments.Value.from(term_name);
                    target('target') = hdng.experiments.Value.empty_with_label('No target');

                    result.include_record(target);
                end
                
                return
            end
            
            if obj.load_targets
                
                term_names = obj.domain_expression.term_names;

                for index=1:numel(term_names)

                    term_name = term_names{index};
                    
                    path = fullfile(targets_directory, [term_name '.nii']);
                    path = obj.canonical_path(path);
                    
                    image_pattern = ['^' term_name '(\([^)]*\))?\.(png|tif)$'];
                    [image_paths, ~] = hdng.utilities.scan_files(targets_directory, image_pattern);
                    
                    if numel(image_paths) == 1
                        
                        volume = hdng.experiments.VolumeReference();
                        volume.scalars = hdng.experiments.ImageReference(path);

                        path = image_paths{1};
                        path = obj.canonical_path(path);
                        
                        volume.image = hdng.experiments.ImageReference(path);
                        volume = hdng.experiments.Value.from(volume);
                    else
                        volume = hdng.experiments.Value.empty_with_label('No target');
                    end
                    
                    target = hdng.utilities.Dictionary();
                    target('term') = hdng.experiments.Value.from(term_name);
                    target('target') = volume;

                    result.include_record(target);
                end
                
                return
            end
            
            targets = obj.compute_targets();
            
            if add_regular_targets || add_inverted_targets
                target_paths = geospm.models.utilities.render_model_targets(obj.domain_expression, targets, targets_directory, true, is_rehearsal, add_inverted_targets);

                term_names = keys(target_paths);

                for index=1:numel(term_names)
                    term_name = term_names{index};
                    paths = target_paths(term_name);

                    volume = hdng.experiments.VolumeReference();
                    volume.scalars = hdng.experiments.ImageReference(obj.canonical_path(paths{1}));
                    volume.image = hdng.experiments.ImageReference(obj.canonical_path(paths{2}));

                    target = hdng.utilities.Dictionary();
                    target('term') = hdng.experiments.Value.from(term_name);
                    target('target') = hdng.experiments.Value.from(volume);

                    result.include_record(target);

                    %fprintf('===== write_targets() for term %s:\n    image-path: %s\n    scalars-path: %s', term_name, paths{1}, paths{2});
                end
            end
        end
        
        function result = scan_for_nifti_files(~, directory)
            name_pattern = '^.*\.nii$';
            [result, ~] = hdng.utilities.scan_files(directory, name_pattern);
        end
        
        function process_nifti_files(obj, files)
            
            if strcmp(obj.nifti_mode, geospm.validation.SpatialExperiment.NIFTI_DELETE)

                hdng.utilities.delete(false, files{:});
            end
        end
        
        function results = load_results(obj)
            
            record_path = fullfile(obj.directory, 'record.json');
            record_text = hdng.utilities.load_text(record_path);
            record_map = hdng.utilities.decode_json(record_text);
            record_map = hdng.experiments.decode_json_proxy(record_map);
            
            results = hdng.utilities.Dictionary();
            
            keys = record_map.keys();
            
            RESULT_PREFIX = 'result.';
            result_key_start = numel(RESULT_PREFIX) + 1;
            
            for index=1:numel(keys)
                key = keys{index};
                
                if ~startsWith(key, RESULT_PREFIX)
                    continue
                end
                
                value = record_map(key);
                key = key(result_key_start:end);
                results(key) = value;
            end
        end
        
        function reuse_results(obj)

            saved_results = obj.load_results();

            keys = saved_results.keys();

            for index=1:numel(keys)
                key = keys{index};
                obj.results(key) = saved_results(key);
            end
        end
    end
    
    methods (Access=protected)
        
        function result = now(~)
            result = datetime('now', 'TimeZone', 'local', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        end
    end
    
    methods (Static, Access=public)
        
        function result = create_r_interface()
            
            persistent R_INTERFACE;
            
            if isempty(R_INTERFACE)
                where = mfilename('fullpath');
                [base_dir, ~, ~] = fileparts(where);
                base_dir = fullfile(base_dir, '+experiments');
                
                R_INTERFACE = hdng.r_support.RInterface(base_dir);
            end
            
            result = R_INTERFACE;
        end
        
    end
    
    methods (Static, Access=protected)
    end
end
