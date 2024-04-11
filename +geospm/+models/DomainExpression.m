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

classdef DomainExpression < handle
    %DomainExpression Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        terms
    end
    
    properties (Dependent, Transient)
        term_names
        N_terms
    end
    
    properties (GetAccess=private, SetAccess=private)
        term_indices_by_name
    end
    
    methods
        
        function obj = DomainExpression(terms)
            obj.terms = terms;
            obj.term_indices_by_name = containers.Map('KeyType', 'char','ValueType', 'any');
            
            for i=1:numel(obj.terms)
                t = obj.terms{i};
                obj.term_indices_by_name(t.name) = i;
            end
        end
        
        function result = get.term_names(obj)
            
            result = cell(1, numel(obj.terms));
            
            for i=1:numel(obj.terms)
                result{i} = obj.terms{i}.name;
            end
        end
        
        function result = get.N_terms(obj)
            result = numel(obj.terms);
        end
        
        function index_or_zero = index_for_term_name(obj, name)
            
            if ~isKey(obj.term_indices_by_name, name)
                index_or_zero = 0;
                return
            end
            
            index_or_zero = obj.term_indices_by_name(name);
        end
        
        function result = copy(obj)
            result = geospm.models.DomainExpression(obj.terms);
        end
        
        function result = compute_matrix(obj, domain, observations)
            
            [is_bound, bindings] = obj.bind_terms(domain);
            
            if ~is_bound
                error('DomainExpression.compute_matrix(): Couldn''t bind terms.');
            end
            
            result = zeros(size(observations, 1), numel(obj.terms));
            
            for i=1:numel(obj.terms)
                
                t = obj.terms{i};
                b = bindings{i};
                
                arguments = cell(1, numel(b));
                
                for j=1:numel(b)
                    arguments{j} = observations(:,b(j));
                end
                
                result(:,i) = t.compute_values(arguments);
            end
        end
        
        
        function result = compute_term_probabilities(obj, domain, joint_distribution)
            
            %compute_probabilities Computes the term probabilities from the joint distribution of the domain.
            %   For each term, we compute a joint marginal distribution of
            %   its defining variables. The term uses this marginal
            %   distribution to derive a suitable probability measure.

            [is_bound, bindings] = obj.bind_terms(domain);
            
            if ~is_bound
                error('DomainExpression.compute_vectors(): Couldn''t bind terms.');
            end
            
            result = cell(1, domain.N_variables);
            
            factor_levels = size(joint_distribution);
            factor_levels = factor_levels(3:end);
            
            N_factors = numel(factor_levels);
            
            for i=1:numel(obj.terms)
                
                term = obj.terms{i};
                
                %Compute a marginal distribution for the term with all
                %unused domain variables factored out.
                
                selector = (1:N_factors) + 2;
                selector(bindings{i}) = [];
                
                distribution = joint_distribution;
                
                if ~isempty(selector)
                    distribution = squeeze(sum(joint_distribution, selector));
                end
                
                result{i} = term.compute_probabilities(distribution);
            end
        end
        
        function result = compute_spatial_data(obj, domain, spatial_data)
            
            observations = obj.compute_matrix(domain, spatial_data.observations);

            function specifier = swap_observations(specifier, modifier)
                
                old_column_indices = 1:specifier.C;

                per_column.variable_names = obj.term_names;
                specifier = modifier.insert_columns_op(specifier, specifier.C + 1, observations, per_column);
                specifier = modifier.delete_op(specifier, [], old_column_indices);
            end

            result = spatial_data.select([], [], @swap_observations);
        end
        
        function result = char(obj)
            
            result = '';
            
            for i=1:numel(obj.terms)
                t = obj.terms{i};
                result = [result, ', ', t.name]; %#ok<AGROW>
            end
            
            if startsWith(result, ', ')
                result = result(3:end);
            end
            
            result = ['{' result '}'];
        end
    end
    
    methods (Access=private)
        
        function [bindings_ok, bindings] = bind_terms(obj, domain)
            
            bindings_ok = true;
            bindings = cell(numel(obj.terms),1);
            
            for i=1:numel(obj.terms)
                t = obj.terms{i};
                t_bindings = zeros(numel(t.variables), 1);
                
                for j=1:numel(t.variables)
                    name = t.variables{j};
                    
                    variable_index = domain.index_for_variable_name(name);
                    
                    if variable_index ~= 0
                        t_bindings(j) = variable_index;
                    end
                    
                    bindings_ok = bindings_ok && (variable_index ~= 0);
                end
                
                bindings{i} = t_bindings;
            end
        end
    end
    
    methods (Static, Access=private)
    end
    
end
