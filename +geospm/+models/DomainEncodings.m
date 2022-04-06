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

classdef DomainEncodings < handle
    %DomainEncodings Summary of this class goes here
    %   Detailed explanation goes here
    
    
    properties (Constant)
        
        DIRECT_ENCODING = 'direct'
        DIRECT_ENCODING_WITH_INTERACTIONS = 'direct_with_interactions'
        FACTORIAL_WITH_BINARY_LEVELS_ENCODING = 'factorial_with_binary_levels'
        
    end
    
    methods
        
        function obj = DomainEncodings()
        end
        
        function method = resolve_encoding_method(~, encoding)
            
            parts = split(encoding, ':');
            
            encoding = parts{1};
            
            switch encoding
                case geospm.models.DomainEncodings.DIRECT_ENCODING
                    method = @(object, domain) object.create_direct_encoding(domain, false);
                case geospm.models.DomainEncodings.DIRECT_ENCODING_WITH_INTERACTIONS
                    method = @(object, domain) object.create_direct_encoding(domain, true);
                case geospm.models.DomainEncodings.FACTORIAL_WITH_BINARY_LEVELS_ENCODING
                    method = @(object, domain) object.create_factorial_encoding_with_binary_levels(domain);
                
                otherwise
                    method = @(object, domain) object.report_unknown_encoding(encoding);
            end
        end
        
        function report_unknown_encoding(~, encoding)
            error('geospm.models.DomainEncodings: Unknown encoding ''%s''', encoding);
        end
        
        
        function result = create_factorial_encoding_with_binary_levels(obj, domain)
            
            domain_terms = {};
            domain_levels = repmat(2, 1, domain.N_variables);
            
            MAX_FACTORS = 64;

            N_factors = domain.N_variables;
            
            if N_factors > MAX_FACTORS
                error('geospm.models.DomainEncodings: Too many variables for factorial encoding.');
            end
            
            [powers, N_conditions] = obj.compute_factorial_powers(domain_levels);
            
            for condition=1:N_conditions
                levels = obj.levels_from_condition_index(condition, powers);
                %computed_condition = sum(levels .* powers') + 1;
                condition_name = ['(' obj.label_from_factors(domain, levels) ')'];

                term = geospm.models.DomainTerm(...
                        domain.variable_names, ...
                        @(varargin) geospm.models.DomainEncodings.compute_condition_values(condition, powers, varargin), ...
                        condition_name);
                
                term.probability_expression = ...
                    @(distribution) geospm.models.DomainEncodings.compute_condition_probabilities(condition, powers, distribution);
                
                domain_terms = [domain_terms {term}]; %#ok<AGROW>
            end
            
            result = geospm.models.DomainExpression(domain_terms);
        end
        
        function result = create_direct_encoding(~, domain, include_interaction_terms)
            
            domain_terms = {};
            
            for i=1:domain.N_variables
                name = domain.variable_names{i};
                term = geospm.models.DomainTerm({name});
                
                domain_terms = [domain_terms {term}]; %#ok<AGROW>
            end
            
            if include_interaction_terms

                main_terms = domain_terms;
                N_main_terms = numel(main_terms);

                interaction_terms = {};

                for i=1:N_main_terms

                    t1 = main_terms{i};

                    for j=i + 1:N_main_terms

                        t2 = main_terms{j};

                        t3 = geospm.models.DomainTerm([t1.variables t2.variables], ...
                            @(A, B) geospm.models.DomainEncodings.compute_interaction_values(A, B), ...
                            [t1.name 'x' t2.name]);

                        t3.probability_expression = ...
                            @(distribution) geospm.models.DomainEncodings.compute_interaction_probabilities(distribution);

                        interaction_terms = [interaction_terms {t3}]; %#ok<AGROW>
                    end
                end

                domain_terms = [domain_terms interaction_terms];
            end
            
            result = geospm.models.DomainExpression(domain_terms);
        end
    end
    
    methods (Static, Access=private)
        
        function [powers, N_conditions] = compute_factorial_powers(levels)
            
            powers = ones(1, numel(levels) + 1);
            
            for i=1:numel(levels)
                powers(i + 1) = powers(i) * levels(i); %power(levels(i), i - 1);
            end
            
            N_conditions = powers(end);
            powers = powers(1:end - 1);
        end
        
        function result = levels_from_condition_index(index, powers)
            
            result = zeros(numel(powers), 1);
            value = index - 1;
            
            for i=numel(powers):-1:1
                factor = floor(value / powers(i));
                value = value - factor * powers(i);
                result(i) = factor;
            end
        end
        
        function label = label_from_factors(domain, factors)
            
            label = '';
            
            for i=1:domain.N_variables
                name = domain.variable_names{i};
                label = [label sprintf(' %s=%d', name, factors(i))]; %#ok<AGROW>
            end
            
            label = strip(label);
        end
        
        function values = compute_condition_values(condition_index, powers, terms)
            
            terms = [terms{:}];
            
            condition_value = condition_index - 1;
            
            observation_levels = terms > 0.5;
            
            indicators = cast(sum(observation_levels .* powers, 2), 'uint64');
            values = cast(indicators == condition_value, 'double');
        end
        
        function probabilities = compute_condition_probabilities(condition_index, powers, distribution)
            
            levels = geospm.models.DomainEncodings.levels_from_condition_index(condition_index, powers);
            levels = num2cell(levels + 1);
            probabilities = distribution(:, :, levels{:});
        end
        
        function interaction = compute_interaction_values(A, B)
            interaction = A .* B;
        end
        
        function interaction = compute_interaction_probabilities(distribution)
            interaction = distribution(:, :, 2, 2);
        end
        
    end
    
end
