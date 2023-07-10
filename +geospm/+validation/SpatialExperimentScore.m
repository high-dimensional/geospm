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

classdef SpatialExperimentScore < hdng.experiments.Score
    %SpatialExperimentScore 
    %   

    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = SpatialExperimentScore()
            obj = obj@hdng.experiments.Score();
        end
        
        function compute(obj, evaluation, mode)
        	
            if ~isfield(evaluation.attachments, 'experiment')
                warning('%s.compute(): Score is not applicable, missing ''experiment'' field in attachments.', class(obj));
                return
            end
            
            experiment = evaluation.attachments.experiment;
            
            if ~isa(experiment, 'geospm.validation.SpatialExperiment')
                warning('%s.compute(): Score is not applicable, ''experiment'' attachment is not an instance of geospm.validation.SpatialExperiment.', class(obj));
                return
            end
            
            obj.compute_for_experiment(experiment, evaluation, mode);
        end
    
    end
    
    methods (Access=protected)
        
        function compute_for_experiment(obj, experiment, evaluation, mode) %#ok<INUSD>
        end
        
    end
end
