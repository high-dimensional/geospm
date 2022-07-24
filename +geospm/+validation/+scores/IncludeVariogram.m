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

classdef IncludeVariogram < geospm.validation.SpatialExperimentScore
    %IncludeVariogram
    %   
    
    properties
        results
    end
    
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = IncludeVariogram()
            obj = obj@geospm.validation.SpatialExperimentScore();
            
            attribute = obj.result_attributes.define('covariogram_model', true, true);
            attribute.description = 'Covariogram Model';
            
            attribute = obj.result_attributes.define('empirical_covariogram', true, true);
            attribute.description = 'Empirical Covariogram';
        end
        
    end
    
    methods (Access=protected)
        
        function prepare_results(obj, evaluation, mode) %#ok<INUSD>
            
            obj.results = struct();
            
            covariogram_model = hdng.experiments.RecordArray();
            
            attribute = covariogram_model.define_attribute('label', true, true);
            attribute.description = 'Label';
            
            attribute = covariogram_model.define_attribute('correlation_function', true, true);
            attribute.description = 'Correlation Function';
            
            attribute = covariogram_model.define_attribute('partial_sill', true, true);
            attribute.description = 'Partial Sill';
            
            attribute = covariogram_model.define_attribute('range', true, true);
            attribute.description = 'Range';
            
            attribute = covariogram_model.define_attribute('smoothness', true, true);
            attribute.description = 'Smoothness';
            
            covariogram_model.define_partitioning_attachment({
                struct('identifier', 'label', 'category', 'partitioning', 'view_mode', 'select'), ...
                ...
                struct('identifier', 'correlation_function', 'category', 'partitioning'), ...
                struct('identifier', 'partial_sill', 'category', 'content'), ...
                struct('identifier', 'range', 'category', 'content'), ...
                struct('identifier', 'smoothness', 'category', 'content'), ...
                ...
            });
            
            obj.results.covariogram_model = covariogram_model;
            
            
            empirical_covariogram = hdng.experiments.RecordArray();
            
            attribute = empirical_covariogram.define_attribute('label', true, true);
            attribute.description = 'Label';
            
            attribute = empirical_covariogram.define_attribute('distance', true, true);
            attribute.description = 'Distance';
            
            attribute = empirical_covariogram.define_attribute('gamma', true, true);
            attribute.description = 'gamma';
            
            attribute = empirical_covariogram.define_attribute('pairs', true, true);
            attribute.description = 'pairs';
            
            empirical_covariogram.define_partitioning_attachment({
                struct('identifier', 'label', 'category', 'partitioning', 'view_mode', 'select'), ...
                ...
                struct('identifier', 'distance', 'category', 'content'), ...
                struct('identifier', 'gamma', 'category', 'content'), ...
                struct('identifier', 'pairs', 'category', 'content'), ...
                ...
            });
            
            obj.results.empirical_covariogram = empirical_covariogram;
        end
        
        function finalise_results(obj, evaluation, mode) %#ok<INUSD>
            
            evaluation.results('covariogram_model') = hdng.experiments.Value.from(obj.results.covariogram_model);
            evaluation.results('empirical_covariogram') = hdng.experiments.Value.from(obj.results.empirical_covariogram);
        end
        
        function compute_for_experiment(obj, experiment, evaluation, mode)
            
            if ~isa(experiment, 'geospm.validation.experiments.Kriging')
                return
            end
            
            obj.prepare_results(evaluation, mode);
            
            directory_path = fullfile(experiment.kriging_directory_path, 'global');
            parameters_path = fullfile(directory_path, 'variograms.mat');
            parameters = geospm.variograms.load_parameters(parameters_path);
            
            model = geospm.variograms.CovariogramModel();
            model.initialise_from_parameters(...
                parameters.fitted, ...
                parameters.labels, ...
                parameters.models);

            emp_variogram = geospm.variograms.EmpiricalCovariogram();
            emp_variogram.initialise_from_parameters(...
                parameters.empirical, ...
                parameters.labels);
            
            for index=1:model.N_variograms
                variogram = model.variograms{index};
                
                for j=1:variogram.N_components
                    correlation = variogram.correlations{j};
                    record = hdng.utilities.Dictionary();
                    record('label') = hdng.experiments.Value.from(variogram.name);
                    record('correlation_function') = hdng.experiments.Value.from(correlation.name);
                    record('partial_sill') = hdng.experiments.Value.from(variogram.partial_sills(j));
                    
                    if isfield(correlation.parameters, 'range')
                        range = correlation.parameters.range;
                    else
                        range = NaN;
                    end
                    
                    record('range') = hdng.experiments.Value.from(range);
                    
                    if isfield(correlation.parameters, 'smoothness')
                        smoothness = correlation.parameters.smoothness;
                    else
                        smoothness = NaN;
                    end
                    
                    record('smoothness') = hdng.experiments.Value.from(smoothness);
                    obj.results.covariogram_model.include_record(record);
                end
            end
            
            for index=1:emp_variogram.N_variograms
                variogram = emp_variogram.variograms{index};

                record = hdng.utilities.Dictionary();
                record('label') = hdng.experiments.Value.from(variogram.name);
                record('distance') = hdng.experiments.Value.from(variogram.distance);
                record('gamma') = hdng.experiments.Value.from(variogram.gamma);
                record('pairs') = hdng.experiments.Value.from(variogram.pairs);

                obj.results.empirical_covariogram.include_record(record);
            end
            
            save_files = obj.should_compute(mode, evaluation.results);
            
            [eps_path, png_path] = obj.save_diagram(model, emp_variogram, directory_path, save_files);
            json_path = obj.save_json(model, emp_variogram, directory_path, save_files);
            
            file_records = evaluation.results('files').content;
            
            file = hdng.experiments.FileReference();
            file.path = experiment.canonical_path(eps_path);
            file_records('variograms.eps') = hdng.experiments.Value.from(file);
            
            
            file = hdng.experiments.ImageReference();
            file.path = experiment.canonical_path(png_path);
            file_records('variograms.png') = hdng.experiments.Value.from(file);
            
            file = hdng.experiments.FileReference();
            file.path = experiment.canonical_path(json_path);
            file_records('variograms.json') = hdng.experiments.Value.from(file); %#ok<NASGU>
            
            obj.finalise_results(evaluation, mode);
            obj.results = [];
        end
        
        function json_path = save_json(~, model, emp_variogram, directory_path, save_files)
            
            result = struct();
            result.covariogram_model = model.as_json();
            result.empirical_covariogram = emp_variogram.as_json();
            json = jsonencode(result);
            json_path = fullfile(directory_path, 'variograms.json');
            
            if save_files
                hdng.utilities.save_text(json, json_path);
            end
        end
        
        function [eps_path, png_path] = save_diagram(~, model, emp_variogram, directory_path, save_files)
            
            f = figure;
            emp_variogram.plot(model);

            N = model.N_components;
            ys = zeros(1, N);

            for index=1:numel(model.variograms)

                [x, y] = geospm.variograms.CovariogramModel.index_to_xy(index);
                k = (x - 1) * N + y;

                ax = subplot(N, N, k);

                yr = ylim; 
                ys(index) = yr(2);

                if y == 1
                    ylabel('Variance');
                end

                if x == N
                    xlabel('Range');
                end

                ytickformat('%.2f');

                set(ax, 'FontName', 'Barlow-Regular');
    
                variogram = model.variograms{index};
                correlations = variogram.correlations(~variogram.nugget_components);

                if isempty(correlations)
                    correlations = variogram.correlations(variogram.nugget_components);
                end

                if ~isempty(correlations)
                    title([variogram.name ': ' correlations{1}.name]);
                end
            end

            max_y = max(ys);

            for index=1:numel(model.variograms)


                [x, y] = geospm.variograms.CovariogramModel.index_to_xy(index);
                k = (x - 1) * N + y;

                ax = subplot(N, N, k);
                
                if isfinite(max_y) && max_y > 0.0
                    ylim([0, max_y]);
                end
            end

            set(f, 'PaperPositionMode', 'auto',  ...
                   'PaperSize', [f.PaperPosition(3), f.PaperPosition(4)], ...
                   'PaperPosition', [0, 0, f.PaperPosition(3), f.PaperPosition(4)]);
            
            eps_path = fullfile(directory_path, 'variograms.eps');
            
            if save_files
                saveas(ax, eps_path, 'epsc');
            end
            
            png_path = fullfile(directory_path, 'variograms.png');
            
            if save_files
                saveas(ax, png_path, 'png');
            end
            
            close(f);
            
            if save_files
                eps_text = hdng.utilities.load_text(eps_path);
                eps_text = regexprep(eps_text, 'Courier([^-])', 'Barlow-Regular$1');
                eps_text = regexprep(eps_text, 'Courier-', 'Barlow-');

                hdng.utilities.save_text(eps_text, eps_path);
            end
        end
    end
end
