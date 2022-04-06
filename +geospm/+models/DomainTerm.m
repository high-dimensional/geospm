% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2019,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef DomainTerm < handle
    %DomainTerm Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name
        variables
        
        value_expression
        
        probability_expression
    end
    
    methods
        
        function obj = DomainTerm(variables, value_expression, name)
            
            if ~iscell(variables)
                error('DomainTerm.ctor(): Expected a cell array of variable names.');
            end
            
            if ~exist('value_expression', 'var')
                if numel(variables) ~= 1
                    error('DomainTerm.ctor(): A default identity value_expression can only be generated for a single variable.');
                end
            
                value_expression = @(value) value;
                name = variables{1};
            end
                
            if ~exist('name', 'var')
                name = '';
            end
            
            if numel(name) == 0
                for i=1:numel(variables)
                    variable_name = variables{i};
                    name = [name ', ' variable_name]; %#ok<AGROW>
                end
                
                name = ['(' name(3:end) ')'];
            end
            
            obj.name = name;
            obj.variables = variables;
            obj.value_expression = value_expression;
            obj.probability_expression = @geospm.models.DomainTerm.compute_default_probability;
        end
        
        function result = compute_values(obj, bound_variables)
            
            if numel(bound_variables) ~= numel(obj.variables)
                error('DomainTerm.compute_values(): Number of bindings does not match number of variables.');
            end
            
            result = obj.value_expression(bound_variables{:});
        end
        
        function result = compute_probabilities(obj, distribution)
            result = obj.probability_expression(distribution);
        end
        
        function result = char(obj)
            result = obj.name;
        end
    end
    
    methods (Static, Access=private)
        
        function result = compute_default_probability(distribution)
            result = 1.0 - distribution(:, :, 1);
        end
        
    end
    
end
