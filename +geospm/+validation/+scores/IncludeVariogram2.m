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

classdef IncludeVariogram2 < geospm.validation.scores.TermScore
    %IncludeVariogram2 
    %   
    
    properties
        quantile_p_values
    end
    
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = IncludeVariogram2()
            obj = obj@geospm.validation.scores.TermScore();
            
            obj.score_identifiers = { 'score.variogram_models', ...
                                      'score.variogram_partial_sills', ...
                                      'score.variogram_ranges', ... 
                                      'score.variogram_smoothness', ... 
                                        };
                                  
            obj.score_descriptions = { 'Variogram Models', ...
                                       'Variogram Partial Sills', ...
                                       'Variogram Ranges', ...
                                       'Variogram Smoothness', ...
                                        };
            obj.experiment = [];
            obj.covariogram_model = [];
            obj.empirical_covariogram = [];
        end
        
        
        function compute(obj, evaluation, mode)
        	
            if ~isfield(evaluation.attachments, 'experiment')
                warning('%s.compute(): Score is not applicable, missing ''experiment'' field in attachments.', class(obj));
                return
            end
            
            obj.experiment = evaluation.attachments.experiment;
            
            if ~isa(experiment, 'geospm.validation.SpatialExperiment')
                warning('%s.compute(): Score is not applicable, ''experiment'' attachment is not an instance of geospm.validation.SpatialExperiment.', class(obj));
                return
            end
            
            [obj.covariogram_model, obj.empirical_covariogram] = obj.compute_for_experiment(obj.experiment, evaluation, mode);
            
            compute@geospm.validation.scores.TermScore(obj, evaluation, mode);
            
            obj.experiment = [];
            obj.covariogram_model = [];
            obj.empirical_covariogram = [];
        end
        
        function define_score_attributes(obj, record_array)
            
            for index=1:numel(obj.score_identifiers)
                
                score_identifier = obj.score_identifiers{index};
                
                new_attribute = record_array.define_attribute(score_identifier, true, true);
                new_attribute.description = obj.score_descriptions{index};
            end
        end
        
        function mark_scores_not_applicable(obj, evaluation, mode, term_record) %#ok<INUSD>
        end
        
        function prepare_results(obj, evaluation, mode)
            prepare_results@geospm.validation.scores.TermScore(obj, evaluation, mode);
        end
        
        function finalise_results(obj, evaluation, mode)
            finalise_results@geospm.validation.scores.TermScore(obj, evaluation, mode);
        end
        
        function prepare_term(obj, evaluation, mode, term_record) %#ok<INUSD>
            
            obj.term = struct();
            
            N_scores = numel(obj.score_identifiers);
            
            obj.term.scores = zeros(1, N_scores);
        end
        
        function finalise_term(obj, evaluation, mode, term_record) %#ok<INUSL>
            
            N_scores = numel(obj.score_identifiers);
            
            for index=1:N_scores
                
                score_identifier = obj.score_identifiers{index};
                scores = obj.term.scores(:, index);
                term_record(score_identifier) = hdng.experiments.Value.from(scores);
            end
            
            obj.results.term_records.include_record(term_record);
        end
        
        function compute_scores_for_term(obj, evaluation, mode, term_record)
            
            obj.prepare_term(evaluation, mode, term_record);
            
            
            
            
            obj.finalise_term(evaluation, mode, term_record);
        end
        
        
        function [model, emp_variogram] = compute_for_experiment(obj, experiment, evaluation, mode) %#ok<INUSD>
            
            if ~isa(experiment, 'geospm.validation.experiments.Kriging')
                return
            end
            
            %results = evaluation.results;
            
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
            
            obj.save_diagram(model, emp_variogram, directory_path);
            obj.save_json(model, emp_variogram, directory_path);
        end
        
        function save_json(~, model, emp_variogram, directory_path)
            
            result = struct();
            result.covariogram_model = model.as_json();
            result.empirical_covariogram = emp_variogram.as_json();
            json = jsonencode(result);
            json_path = fullfile(directory_path, 'variograms.json');
            hdng.utilities.save_text(json, json_path);
        end
        
        function save_diagram(~, model, emp_variogram, directory_path)

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
                ylim([0, max_y]);
            end

            set(f, 'PaperPositionMode', 'auto',  ...
                   'PaperSize', [f.PaperPosition(3), f.PaperPosition(4)], ...
                   'PaperPosition', [0, 0, f.PaperPosition(3), f.PaperPosition(4)]);
            
            eps_path = fullfile(directory_path, 'variograms.eps');
            saveas(ax, eps_path, 'epsc');

            close(f);
            
            eps_text = hdng.utilities.load_text(eps_path);
            eps_text = regexprep(eps_text, 'Courier([^-])', 'Barlow-Regular$1');
            eps_text = regexprep(eps_text, 'Courier-', 'Barlow-');

            hdng.utilities.save_text(eps_text, eps_path);
            
        end
    end
end
