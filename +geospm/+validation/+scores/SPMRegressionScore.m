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

classdef SPMRegressionScore < geospm.validation.SpatialExperimentScore
    %SPMRegressionScore 
    %   
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = SPMRegressionScore()
            obj = obj@geospm.validation.SpatialExperimentScore();
        end
    end
    
    methods (Access=protected)
        
        function compute_for_experiment(obj, experiment, evaluation, mode)
            
            if ~isa(experiment, 'geospm.validation.experiments.SPMRegression')
                %warning('%s.compute(): Score is not applicable, ''experiment'' attachment is not an instance of geospm.validation.experiments.SPMRegression.', class(obj));
                return
            end
            
            extra_variables = struct();
            
            results = evaluation.results;
            
            if ~results.holds_key('spm_output_directory')
                warning('%s.compute(): Score is not applicable, missing ''spm_output_directory'' key in results dictionary.', class(obj));
                return
            end
            
            spm_output_directory = results('spm_output_directory').content.resolve_path_relative_to(evaluation.canonical_base_path);
            extra_variables.spm_session = geospm.spm.SPMSession(fullfile(spm_output_directory, 'SPM.mat'));
            
            
            if ~results.holds_key('threshold_directories')
                warning('%s.compute(): Score is not applicable, missing ''threshold_directories'' key in results dictionary.', class(obj));
                return
            end
            
            threshold_directories = results('threshold_directories').content;
                           
            for index=1:numel(threshold_directories)
                threshold_directory = threshold_directories{index};
                threshold_directory = threshold_directory.resolve_path_relative_to(evaluation.canonical_base_path);
                threshold_directories{index} = threshold_directory;
            end
            
            extra_variables.threshold_directories = threshold_directories;
            
            obj.compute_for_spm_regression(experiment, extra_variables, evaluation, mode);
        end
        
        function compute_for_spm_regression(obj, spm_regression, extra_variables, evaluation, mode) %#ok<INUSD>
        end
    end
end
