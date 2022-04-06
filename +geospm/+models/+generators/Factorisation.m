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

classdef Factorisation < geospm.models.Generator
    %Factorisation Summary.
    %   A factorisation is defined by a density parameter and, for each 
    %   variable in the domain, a marginal distribution parameter as well 
    %   as a bias parameter.
    %   The overall distribution of samples
    
    properties
    end
    
    properties (SetAccess=private)
        density_role
        marginal_distribution_role
        bias_role
        binary_bias_role
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Factorisation(domain)
            obj = obj@geospm.models.Generator(domain);
            
            obj.density_role = geospm.models.ParameterRole(obj, ...
                'density', ...
                'map', ...
                {}, ...
                1, ...
                1, ...
                'Density', ...
                @(generator, bindings) obj.check_density_bindings(bindings));
            
            obj.marginal_distribution_role = geospm.models.ParameterRole(obj, ...
                'marginal_distribution', ...
                'map', ...
                {'variable_index'}, ...
                domain.N_variables, ...
                domain.N_variables, ...
                'Marginal probability distribution of domain variable.', ...
                @(generator, bindings) obj.check_marginal_distribution_bindings(bindings), ...
                @(generator, bindings, added, removed) obj.marginal_distribution_bindings_changed(bindings, added, removed));
            
            max_biases = geospm.models.Distribution.compute_df_constant_marginals(domain.joint_dimensions);
            
            obj.bias_role = geospm.models.ParameterRole(obj, ...
                'bias', ...
                'map', ...
                {'case_selector'}, ...
                0, ...
                max_biases, ...
                'Bias', ...
                @(generator, bindings) obj.check_bias_bindings(bindings));
            
            
            obj.binary_bias_role = geospm.models.ParameterRole(obj, ...
                'binary_bias', ...
                'map', ...
                {}, ...
                0, ...
                1, ...
                'Binary Bias', ...
                @(generator, bindings) obj.check_binary_bias_bindings(bindings));
        end
        
        function result = check_marginal_distribution_bindings(obj, bindings)
            result = struct();
            result.passed = true;
            result.diagnostic = '';
            
            assignments = zeros(obj.domain.N_variables, 1, 'logical');
            
            for i=1:numel(bindings)
                binding = bindings{i};
                
                variable_index = binding.arguments.variable_index;
                assignments(variable_index) = 1;
            end
            
            if sum(assignments) ~= obj.domain.N_variables
                result.passed = false;
                result.diagnostic = 'Inconsistent or missing marginal distributions for domain variables.';
            end
        end
        
        function marginal_distribution_bindings_changed(obj, bindings, added, removed) %#ok<INUSD>
        end
        
        function result = check_bias_bindings(obj, bindings)
            
            result = struct();
            result.passed = true;
            result.diagnostic = '';
            
            case_assignments = zeros(obj.domain.joint_dimensions, 'logical');
            
            for i=1:numel(bindings)
                binding = bindings{i};
                
                case_selector = binding.arguments.case_selector;
                
                if case_assignments(case_selector)
                    result.passed = false;
                    result.diagnostic = 'Bias case selector specified more than once.';
                    return;
                end
                
                case_assignments(case_selector) = 1;
            end
        end
        
        function result = check_binary_bias_bindings(~, ~)
            
            result = struct();
            result.passed = true;
            result.diagnostic = '';
        end
        
        function result = check_density_bindings(~, ~)
            
            result = struct();
            result.passed = true;
            result.diagnostic = '';
        end
        
        function [model, metadata] = render(obj, seed, transform, spatial_resolution, settings)
            
            obj.check_bindings();
            
            for i=1:numel(obj.controls)
                control = obj.controls{i};
                
                if ~isfield(settings, control.identifier)
                    continue
                end
                
                value = settings.(control.identifier);
                control.set(value);
            end
            
            %{
            control_ids = fieldnames(control_settings);
            
            for i=1:numel(control_ids)
                id = control_ids{i};
            end
            %}
            
            model = geospm.models.SpatialModel(obj.domain, spatial_resolution);
            
            metadata = geospm.models.Metadata(obj, seed, transform);
            
            geospm.models.Parameter.render(model, metadata, obj.parameters);
            
            marginals = obj.resolve_marginal_distributions(model, metadata);
            [case_selectors, case_biases] = obj.resolve_biases(model, metadata);
            
            binary_biases = obj.resolve_binary_biases(model, metadata);
            
            model.probes = obj.resolve_probes(model, metadata);
            
            geospm.models.quantities.SyntheticDistribution(model, 'joint_distribution', ...
                marginals, case_selectors, case_biases, binary_biases);
        end
        
        function result = resolve_marginal_distributions(obj, ~, metadata)
            
            bindings = obj.bindings_per_role{obj.marginal_distribution_role.nth_role};
            N = numel(bindings);
            
            result = cell(obj.domain.N_variables, 1);
            
            for i=1:N
                binding = bindings{i};
                binding_result = metadata.get_parameter_metadata(binding.parameter_index);
                result{binding.arguments.variable_index} = binding_result.quantity;
            end
        end
        
        function [selectors, biases] = resolve_biases(obj, ~, metadata)
            
            bindings = obj.bindings_per_role{obj.bias_role.nth_role};
            N = numel(bindings);
            
            selectors = cell(N, 1);
            biases = cell(N,1);
            
            for i=1:N
                binding = bindings{i};
                binding_result = metadata.get_parameter_metadata(binding.parameter_index);
                selectors{i} = binding.arguments.case_selector;
                biases{i} = binding_result.quantity;
            end
        end
        
        function binary_biases = resolve_binary_biases(obj, ~, metadata)
            
            bindings = obj.bindings_per_role{obj.binary_bias_role.nth_role};
            N = numel(bindings);
            
            binary_biases = cell(N,1);
            
            for i=1:N
                binding = bindings{i};
                binding_result = metadata.get_parameter_metadata(binding.parameter_index);
                binary_biases{i} = binding_result.quantity;
            end
            
            if N == 1
                binary_biases = binary_biases{1};
            else
                binary_biases = {};
            end
        end
        
        function result = resolve_targets(obj, ~, metadata)
            
            bindings = obj.bindings_per_role{obj.targets_role.nth_role};
            binding_result = metadata.get_parameter_metadata(bindings{1}.parameter_index);
            result = binding_result.quantity;
        end
        
        function result = resolve_probes(obj, ~, metadata)
            
            result = zeros(0, 3);
            
            N_probes = numel(obj.probe_expressions);
            
            for i=1:N_probes
                
                expr = obj.probe_expressions{i};
                
                result = [result; expr.value]; %#ok<AGROW>
            end
            
            if N_probes > 0
                t = [metadata.transform; 0 0 1];

                x_result = result(:, 1) * t(1,1) + result(:, 2) * t(1, 2) + t(1, 3);
                y_result = result(:, 1) * t(2,1) + result(:, 2) * t(2, 2) + t(2, 3);

                result(:, 1) = x_result;
                result(:, 2) = y_result;
                result(:, 3) = result(:, 3) * (0.5 * (t(1,1) + t(2,2)));
            end
        end
    end
    
    methods (Static, Access=private)
    end
    
end
