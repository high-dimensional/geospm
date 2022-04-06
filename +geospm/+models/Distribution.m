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

classdef Distribution < handle

    properties
    end
    
    properties (SetAccess=private)
        dimensions
        masses
        N_cases
        marginals
        cdf
        independent_probabilities
        
        sub2ind
        ind2sub
    end
    
    
    properties (Dependent, Transient)
        N_dimensions
        df_constant_marginals
    end
    
    properties (GetAccess=private, SetAccess=private)
        integer_dimensions
        integer_steps
        
        safe_dimensions
        
        constant_marginal_limits
        
        independent_limits
        
        showed_warning
    end
    
    methods (Static)
    
    end
    
    methods
        
        function obj = Distribution(dimensions)
            
            obj.dimensions = dimensions(:)';
            obj.safe_dimensions = [obj.dimensions, 1]; %if dimensions is scalar
            
            obj.integer_dimensions = cast(obj.dimensions, 'int32');
            obj.integer_steps = [cumprod(obj.integer_dimensions(2:end), 'reverse') ones(1, 'int32')];
            
            obj.masses = zeros(obj.safe_dimensions);
            obj.independent_probabilities = zeros(obj.safe_dimensions);
            
            obj.N_cases = prod(obj.dimensions);
            obj.cdf = zeros(obj.N_cases, 1);
            obj.marginals = cell(obj.N_dimensions,1);
            
            indices = 1:obj.N_cases;
            obj.ind2sub = zeros(obj.N_cases,obj.N_dimensions);
            obj.sub2ind = zeros(obj.safe_dimensions);
            
            for i=1:obj.N_dimensions
                [outer, inner] = ind2sub(obj.dimensions(i:end), indices);
                obj.ind2sub(:,i) = outer;
                indices = inner;
            end
            
            for i=1:obj.N_cases
                selector = num2cell(obj.ind2sub(i,:));
                obj.sub2ind(selector{:}) = i;
            end
            
            obj.showed_warning = false;
        end
        
        function result = get.N_dimensions(obj)
            result = numel(obj.dimensions);
        end
        
        function result = get.df_constant_marginals(obj)
            result = geospm.models.Distribution.compute_df_constant_marginals(obj.dimensions);
        end
        
        function result = index_to_subscript(obj, index)
            result = obj.ind2sub(index,:);
        end
        
        function compute_from_marginals(obj, marginals)
            
            if ~isequal(numel(marginals), obj.N_dimensions)
                error('Distribution.compute_cdf_from_marginals(): The number of specified marginal distributions does not match the number of dimensions of the distribution.');
            end
            
            for i=1:numel(marginals)
            
                m = marginals{i};
                
                if numel(m) ~= obj.dimensions(i)
                    error('Distribution.compute_cdf_from_marginals(): The number of elements in one of the marginal distributions does not match its corresponding dimension of the distribution.');
                end
            end
            
            computed_masses = ones(obj.safe_dimensions);
            
            for i=1:obj.N_cases
                
                s = obj.index_to_subscript(i);
                
                for j=1:obj.N_dimensions
                    m = marginals{j};
                    computed_masses(i) = computed_masses(i) * m(s(j));
                end
            end
            
            obj.compute_from_masses(computed_masses);
        end
        
        function compute_from_masses(obj, masses)
            
            if ~isequal(obj.dimensions, size(masses)) && ~isequal(obj.safe_dimensions, size(masses))
                error('Distribution.compute_cdf_from_masses(): The dimensions of the specified masses do not match the dimensions of the distribution.');
            end
            
            masses_min = min(masses(:));
            
            if masses_min < 0.0
                error('Distribution.ctor(): Only non-negative probability masses can be specified.');
            end
            
            obj.cdf = zeros(obj.N_cases, 1); %obj.safe_dimensions);
            
            total = sum(masses(:));
            accumulated_mass = 0;
            
            for i=1:obj.N_cases
                
                accumulated_mass = accumulated_mass + masses(i);
                obj.cdf(i) = accumulated_mass ./ total;
            end
            
            obj.masses = masses;
            
            for i=1:obj.N_dimensions
                domain = 1:obj.N_dimensions;
                domain = [domain(1:i-1) domain(i+1:end)];
                
                if ~isempty(domain)
                    m = sum(obj.masses, domain) ./ total;
                    obj.marginals{i} = m(:);
                else
                    obj.marginals{i} = obj.masses ./ total;
                end
            end
            
            independent_masses = ones(obj.safe_dimensions);
            obj.independent_limits = ones(obj.safe_dimensions);
            
            for i=1:obj.N_cases
                
                s = obj.index_to_subscript(i);
                marginal_values = zeros(obj.N_dimensions, 1);
                
                for j=1:obj.N_dimensions
                    m = obj.marginals{j};
                    independent_masses(i) = independent_masses(i) * m(s(j));
                    marginal_values(j) = m(s(j));
                end
                
                obj.independent_limits(i) = min(marginal_values) ./ total;
            end
            
            obj.independent_probabilities = independent_masses ./ total;
        end
        
        function apply_binary_bias(obj, bias)
            
            if bias < -1.0 || bias > 1.0
                error('Distribution.apply_binary_bias(): A binary bias was outside the expected range [-1, 1].');
            end
            
            if bias ~= 0.0

                biased_masses = obj.masses;
                
                m11 = biased_masses(obj.sub2ind(1, 1));
                m22 = biased_masses(obj.sub2ind(2, 2));
                m12 = biased_masses(obj.sub2ind(1, 2));
                m21 = biased_masses(obj.sub2ind(2, 1));

                if bias <= 0.0
                    min_mass = min([m11, m22]);
                    
                    biased_masses(obj.sub2ind(1, 2)) = m12 + min_mass;
                    biased_masses(obj.sub2ind(2, 1)) = m21 + min_mass;
                    biased_masses(obj.sub2ind(1, 1)) = m11 - min_mass;
                    biased_masses(obj.sub2ind(2, 2)) = m22 - min_mass;
                    
                else
                    min_mass = min([m12, m21]);
                    
                    biased_masses(obj.sub2ind(1, 2)) = m12 - min_mass;
                    biased_masses(obj.sub2ind(2, 1)) = m21 - min_mass;
                    biased_masses(obj.sub2ind(1, 1)) = m11 + min_mass;
                    biased_masses(obj.sub2ind(2, 2)) = m22 + min_mass;
                end
                
                obj.compute_from_masses(biased_masses);
            else
                sprintf('None');
            end
            
        end
        
        function result = samples_from_uniform(obj, samples)
            
            result = zeros([numel(samples) obj.N_dimensions]);
            
            for i=1:numel(samples)
                result(i,:) = obj.sample_from_uniform(samples(i));
            end
        end
        
        
        function result = sample_from_uniform(obj, value)
            
            start = cast(1, 'int32');
            limit = cast(numel(obj.cdf) + 1, 'int32');
            
            while start < limit
                
                pivot = start + idivide(limit - start, 2, 'floor');
                
                if value <= obj.cdf(pivot)
                    limit = pivot;
                else
                    start = pivot + 1;
                end
            end
            
            result = obj.index_to_subscript(start);
        end
    end
    
    methods (Static)
        
        function result = compute_df_constant_marginals(dimensions)
            
            N_cases = prod(dimensions);
            N_dimensions = numel(dimensions);
            
            result = N_cases - sum(dimensions) + N_dimensions - 1;
        end
    end
    
    methods (Static, Access=private)
    end
    
end
