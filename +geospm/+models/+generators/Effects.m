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

classdef Effects < geospm.models.Generator
    %Effects Summary.
    %   Defines a density parameter. 
    
    properties
    end
    
    properties (SetAccess=private)
        density_role
        
        null_probability_role
        effect_a_role
        effect_b_role
        interaction_effect_axb_role
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Effects(domain)
            obj = obj@geospm.models.Generator(domain);
            
            obj.density_role = geospm.models.ParameterRole(obj, ...
                'density', ...
                'map', ...
                {}, ...
                1, ...
                1, ...
                'Density', ...
                @(generator, bindings) obj.check_density_bindings(bindings));
            
            
            obj.null_probability_role = geospm.models.ParameterRole(obj, ...
                'null_probability', ...
                'map', ...
                {}, ...
                0, ...
                1, ...
                'Null Probability', ...
                @(generator, bindings) obj.check_null_probability_bindings(bindings));
            
            obj.effect_a_role = geospm.models.ParameterRole(obj, ...
                'effect_a', ...
                'map', ...
                {}, ...
                1, ...
                1, ...
                'Effect A', ...
                @(generator, bindings) obj.check_effect_a_bindings(bindings));
            
            obj.effect_b_role = geospm.models.ParameterRole(obj, ...
                'effect_b', ...
                'map', ...
                {}, ...
                1, ...
                1, ...
                'Effect B', ...
                @(generator, bindings) obj.check_effect_b_bindings(bindings));
            
            obj.interaction_effect_axb_role = geospm.models.ParameterRole(obj, ...
                'interaction_effect_axb', ...
                'map', ...
                {}, ...
                1, ...
                1, ...
                'Interaction Effect AxB', ...
                @(generator, bindings) obj.check_interaction_effect_axb_bindings(bindings));
            
        end
        
        function result = check_density_bindings(~, ~)
            
            result = struct();
            result.passed = true;
            result.diagnostic = '';
        end
        
        function result = check_null_probability_bindings(~, ~)
            
            result = struct();
            result.passed = true;
            result.diagnostic = '';
        end
        
        function result = check_effect_a_bindings(~, ~)
            
            result = struct();
            result.passed = true;
            result.diagnostic = '';
        end
        
        function result = check_effect_b_bindings(~, ~)
            
            result = struct();
            result.passed = true;
            result.diagnostic = '';
        end
        
        function result = check_interaction_effect_axb_bindings(~, ~)
            
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
            
            model = geospm.models.SpatialModel(obj.domain, spatial_resolution);
            
            metadata = geospm.models.Metadata(obj, seed, transform);
            
            geospm.models.Parameter.render(model, metadata, obj.parameters);
            
            null_probability = obj.resolve_null_probability(model, metadata);
            effect_a = obj.resolve_effect_a(model, metadata);
            effect_b = obj.resolve_effect_b(model, metadata);
            interaction_effect = obj.resolve_interaction_effect_axb(model, metadata);
            
            model.probes = obj.resolve_probes(model, metadata);
            
            geospm.models.quantities.EffectsDistribution(model, 'joint_distribution', ...
                    null_probability, effect_a, effect_b, interaction_effect);
        end
        
        
        function result = resolve_null_probability(obj, ~, metadata)
            
            bindings = obj.bindings_per_role{obj.null_probability_role.nth_role};
            binding = bindings{1};
            binding_result = metadata.get_parameter_metadata(binding.parameter_index);
            
            result = binding_result.quantity;
            
            values = result.flatten();
            values = values(:);
            
            if any(values > 1) || any(values < 0)
                error('geospm.models.generators.Effects.resolve_null_probability(): Invalid null factor values.');
            end
        end
        
        function result = resolve_effect_a(obj, ~, metadata)
            
            bindings = obj.bindings_per_role{obj.effect_a_role.nth_role};
            binding = bindings{1};
            binding_result = metadata.get_parameter_metadata(binding.parameter_index);
            
            result = binding_result.quantity;
            
            values = result.flatten();
            values = values(:);
            
            if any(values > 1) || any(values < -1)
                error('geospm.models.generators.Effects.resolve_effect_a(): Invalid effect a values.');
            end
        end
        
        function result = resolve_effect_b(obj, ~, metadata)
            
            bindings = obj.bindings_per_role{obj.effect_b_role.nth_role};
            binding = bindings{1};
            binding_result = metadata.get_parameter_metadata(binding.parameter_index);
            
            result = binding_result.quantity;
            
            values = result.flatten();
            values = values(:);
            
            if any(values > 1) || any(values < -1)
                error('geospm.models.generators.Effects.resolve_effect_b(): Invalid effect b values.');
            end
        end
        
        function result = resolve_interaction_effect_axb(obj, ~, metadata)
            
            bindings = obj.bindings_per_role{obj.interaction_effect_axb_role.nth_role};
            binding = bindings{1};
            binding_result = metadata.get_parameter_metadata(binding.parameter_index);
            
            result = binding_result.quantity;
            
            values = result.flatten();
            values = values(:);
            
            if any(values > 1) || any(values < -1)
                error('geospm.models.generators.Effects.resolve_interaction_effect_axb(): Invalid interaction effect axb values.');
            end
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
