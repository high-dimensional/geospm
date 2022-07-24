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

classdef IncludeVariogram1 < geospm.validation.SpatialExperimentScore
    %IncludeVariogram1 
    %   
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = IncludeVariogram1()
            obj = obj@geospm.validation.SpatialExperimentScore();
            
            attribute = obj.result_attributes.define('model_variograms');
            attribute.description = 'Model Variograms';
        end
    end
    
    methods (Access=protected)
        
        function compute_for_experiment(obj, experiment, evaluation, mode)
            
            if ~isa(experiment, 'geospm.validation.experiments.Kriging')
                return
            end
            
            results = evaluation.results;
            
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
        end
        
        function save_json(~, model, emp_variogram, directory_path)
            
            
            
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
            
            eps_path = fullfile(directory_path, 'variogram.eps');
            saveas(ax, eps_path, 'epsc');

            close(f);
            
            eps_text = hdng.utilities.load_text(eps_path);
            eps_text = regexprep(eps_text, 'Courier([^-])', 'Barlow-Regular$1');
            eps_text = regexprep(eps_text, 'Courier-', 'Barlow-');

            hdng.utilities.save_text(eps_text, eps_path);
            
        end
    end
end
