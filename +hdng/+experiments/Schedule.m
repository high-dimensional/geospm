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

classdef Schedule < handle
    %Schedule Defines a set of variables to produce a sequence of configurations.
    % 
    properties (Constant)

        STUDY_SEED = 'study_seed'
        REPETITION = 'repetition'
        EXPERIMENT_SEED = 'seed'
        EXPERIMENT = 'experiment'
        EXPERIMENT_URL = 'url'

    end
        
    properties (SetAccess=private)
        variables
        variables_by_identifier
    end
     
    properties (Dependent, Transient)
        N_variables
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = Schedule()
            
           obj.variables = cell(0, 1);
           obj.variables_by_identifier = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end
        
        function nth_variable = add_variable(obj, variable)
            
            obj.variables{end + 1} = variable;
            nth_variable = numel(obj.variables);
            
            obj.variables_by_identifier(variable.identifier) = variable;
        end
        
        function result = get.N_variables(obj)
            result = numel(obj.variables);
        end
        
        function [ordered_variables, permutation, requirements] = order_variables(obj)
            
            permutation = ...
                hdng.utilities.sort_topologically(obj.variables, @(variable, index) variable.requirement_indices);
            
            ordered_variables = obj.variables;
            ordered_variables = ordered_variables(permutation);
            
            requirements = cell(obj.N_variables, 1);
            
            for index=1:obj.N_variables
                variable = ordered_variables{index};
                R = numel(variable.requirements);
                identifiers = cell(R, 1);
                
                for r_index=1:R
                    identifiers{r_index} = variable.requirements{r_index}.identifier; 
                end
                
                requirements{index} = identifiers;
            end
        end
        
        function [iterator] = iterate_configurations(obj, constants)
            
            if ~exist('constants', 'var')
                constants = struct();
            end
            
            iterator = hdng.experiments.ScheduleIterator(obj, constants);
        end
        
    end
    
    methods (Access=protected)
        
        function result = now(~)
            result = datetime('now', 'TimeZone', 'local', 'Format', 'yyyy_MM_dd_HH_mm_ss');
        end
        
    end
    
    methods (Static, Access=public)
    end
    
end
