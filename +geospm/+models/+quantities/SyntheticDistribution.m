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

classdef SyntheticDistribution < geospm.models.Quantity
    %SyntheticDistribution Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        marginal_quantities
        case_selectors
        case_biases
        binary_bias
    end
    
    methods
        
        function obj = SyntheticDistribution(model, name, marginal_quantities, case_selectors, case_biases, binary_bias)

            if ~exist('binary_bias', 'var')
                binary_bias = [];
            end
            
            N_marginals = numel(marginal_quantities);
            dimensions = ones(1, N_marginals);
            
            for i=1:N_marginals
                marginal = marginal_quantities{i};
                dimensions(i) = marginal.dimensions;
            end
            
            obj = obj@geospm.models.Quantity(model, name, dimensions);
            obj.marginal_quantities = marginal_quantities;
            obj.case_selectors = case_selectors;
            obj.case_biases = case_biases;
            obj.binary_bias = binary_bias;
        end
        
        function [result, optional_entity] = value_at(obj, x, y)
            
            distribution = geospm.models.Distribution(obj.dimensions);
            
            N_marginals = numel(obj.marginal_quantities);
            marginals = cell(1, N_marginals);
            
            for i=1:N_marginals
                [marginals{i}, ~] = obj.marginal_quantities{i}.value_at(x, y);
            end
            
            distribution.compute_from_marginals(marginals);
            
            if ~isempty(obj.binary_bias)
                distribution.apply_binary_bias(obj.binary_bias.value_at(x, y));
            end
            
            result = distribution.masses;
            optional_entity = distribution;
        end
        
        
        function result = flatten(obj)
            
            N_marginals = numel(obj.marginal_quantities);
            marginals = cell(1, N_marginals);
            marginal_dimensions = zeros(1, N_marginals);
            powers = ones(1, N_marginals + 1);
            
            for i=1:N_marginals
                marginals{i} = obj.marginal_quantities{i}.flatten();
                marginal_dimensions(i) = obj.marginal_quantities{i}.dimensions;
                powers(i + 1) = powers(i) * marginal_dimensions(i);
            end
            
            result = zeros([obj.model.spatial_resolution obj.dimensions]);
            
            N_conditions = powers(end);
            powers = powers(1:end-1);
            
            for i=1:N_conditions
                factors = obj.factors_from_condition_index(i, powers) + 1;
                p = 1;
                
                for j=1:N_marginals
                    M = marginals{j};
                    p = p .* M(:,:,factors(j));
                end
                factors = num2cell(factors);
                result(:, :, factors{:}) = p;
            end
            
            if ~isempty(obj.binary_bias)
                
                bias = obj.binary_bias.flatten();
                
                min_mass1 = min(cat(3, result(:,:,1,1), result(:,:,2,2)), [], 3) .* (bias < 0.0);
                min_mass2 = min(cat(3, result(:,:,1,2), result(:,:,2,1)), [], 3) .* (bias > 0.0);
                
                result(:,:,1,2) = result(:,:,1,2) + min_mass1 - min_mass2;
                result(:,:,2,1) = result(:,:,2,1) + min_mass1 - min_mass2;
                result(:,:,1,1) = result(:,:,1,1) - min_mass1 + min_mass2;
                result(:,:,2,2) = result(:,:,2,2) - min_mass1 + min_mass2;
            end
        end
    end
    
    methods (Access=protected)

        function result = factors_from_condition_index(~, index, powers)
            
            result = zeros(numel(powers), 1);
            value = index - 1;
            
            for i=numel(powers):-1:1
                factor = floor(value / powers(i));
                value = value - factor * powers(i);
                result(numel(powers) - i + 1) = factor;
            end
        end
    end
    
    methods (Static, Access=private)
    end
    
end
