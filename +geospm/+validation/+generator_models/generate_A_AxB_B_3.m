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

classdef generate_A_AxB_B_3 < geospm.models.GeneratorModel
    %generate_A_AxB_B_3 Defines a generator.
    %   Detailed explanation goes here
    
    methods
        
        function obj = generate_A_AxB_B_3(options, varargin)
            
            options = hdng.utilities.parse_options_argument(options, varargin{:});
            
            if ~isfield(options, 'use_fractals')
                options.use_fractals = false;
            end

            if ~isfield(options, 'fractal_levels')
                options.fractal_levels = 4;
            end

            if ~isfield(options, 'fractal_name')
                options.fractal_name = 'Koch Snowflake';
            end
            
            if ~isfield(options, 'triangular_layout')
                options.triangular_layout = true;
            end
            
            if ~isfield(options, 'parameterisation')
                options.parameterisation = 'effect_size'; % or 'separate', 'regionalisation'
            end
            
            obj = obj@geospm.models.GeneratorModel(options);
        end
        
        function configure_generator(obj, g)

            if strcmp(obj.options.parameterisation, 'effect_size')

                effect_size = geospm.models.Control(g, 'Effect Size', -1, 1, 0);

                regionalisation = geospm.models.Expression(g, 'Regionalisation', effect_size, ...
                    @(~, effect_size) geospm.validation.generator_models.generate_A_AxB_B_3.compute_regionalisation(effect_size));

                null_probability_l0 = geospm.models.Expression(g, 'Null Probability L0', regionalisation, @(~, r) r(1, 1));
                null_probability_l1 = geospm.models.Expression(g, 'Null Probability L1', regionalisation, @(~, r) r(1, 2));
                null_probability_l2 = geospm.models.Expression(g, 'Null Probability L2', regionalisation, @(~, r) r(1, 3));
                null_probability_l3 = geospm.models.Expression(g, 'Null Probability L3', regionalisation, @(~, r) r(1, 4));

                effect_a_l0 = geospm.models.Expression(g, 'Effect A L0', regionalisation, @(~, r) r(2, 1));
                effect_a_l1 = geospm.models.Expression(g, 'Effect A L1', regionalisation, @(~, r) r(2, 2));
                effect_a_l2 = geospm.models.Expression(g, 'Effect A L2', regionalisation, @(~, r) r(2, 3));
                effect_a_l3 = geospm.models.Expression(g, 'Effect A L3', regionalisation, @(~, r) r(2, 4));

                effect_b_l0 = geospm.models.Expression(g, 'Effect B L0', regionalisation, @(~, r) r(3, 1));
                effect_b_l1 = geospm.models.Expression(g, 'Effect B L1', regionalisation, @(~, r) r(3, 2));
                effect_b_l2 = geospm.models.Expression(g, 'Effect B L2', regionalisation, @(~, r) r(3, 3));
                effect_b_l3 = geospm.models.Expression(g, 'Effect B L3', regionalisation, @(~, r) r(3, 4));

                interaction_effect_l0 = geospm.models.Expression(g, 'Interaction Effect AxB L0', regionalisation, @(~, r) r(4, 1));
                interaction_effect_l1 = geospm.models.Expression(g, 'Interaction Effect AxB L1', regionalisation, @(~, r) r(4, 2));
                interaction_effect_l2 = geospm.models.Expression(g, 'Interaction Effect AxB L2', regionalisation, @(~, r) r(4, 3));
                interaction_effect_l3 = geospm.models.Expression(g, 'Interaction Effect AxB L3', regionalisation, @(~, r) r(4, 4));
            
            elseif strcmp(obj.options.parameterisation, 'separate')

                effect_a = geospm.models.Control(g, 'Effect A', -1, 1, 0);

                effect_a_l0 = geospm.models.Expression(g, 'Effect A L0', effect_a, @(~, c1) c1(1));
                effect_a_l1 = geospm.models.Expression(g, 'Effect A L1', effect_a, @(~, c1) c1(2));
                effect_a_l2 = geospm.models.Expression(g, 'Effect A L2', effect_a, @(~, c1) c1(3));
                effect_a_l3 = geospm.models.Expression(g, 'Effect A L3', effect_a, @(~, c1) c1(4));

                effect_b = geospm.models.Control(g, 'Effect B', -1, 1, 0);

                effect_b_l0 = geospm.models.Expression(g, 'Effect B L0', effect_b, @(~, c2) c2(1));
                effect_b_l1 = geospm.models.Expression(g, 'Effect B L1', effect_b, @(~, c2) c2(2));
                effect_b_l2 = geospm.models.Expression(g, 'Effect B L2', effect_b, @(~, c2) c2(3));
                effect_b_l3 = geospm.models.Expression(g, 'Effect B L3', effect_b, @(~, c2) c2(4));

                interaction_effect = geospm.models.Control(g, 'Interaction Effect AxB', -1, 1, 0);

                interaction_effect_l0 = geospm.models.Expression(g, 'Interaction Effect AxB L0', interaction_effect, @(~, c3) c3(1));
                interaction_effect_l1 = geospm.models.Expression(g, 'Interaction Effect AxB L1', interaction_effect, @(~, c3) c3(2));
                interaction_effect_l2 = geospm.models.Expression(g, 'Interaction Effect AxB L2', interaction_effect, @(~, c3) c3(3));
                interaction_effect_l3 = geospm.models.Expression(g, 'Interaction Effect AxB L3', interaction_effect, @(~, c3) c3(4));

                null_probability = geospm.models.Control(g, 'Null Probability', 0, 1, 0);

                null_probability_l0 = geospm.models.Expression(g, 'Null Probability L0', null_probability, @(~, p0) p0(1));
                null_probability_l1 = geospm.models.Expression(g, 'Null Probability L1', null_probability, @(~, p0) p0(2));
                null_probability_l2 = geospm.models.Expression(g, 'Null Probability L2', null_probability, @(~, p0) p0(3));
                null_probability_l3 = geospm.models.Expression(g, 'Null Probability L3', null_probability, @(~, p0) p0(4));
            
            elseif strcmp(obj.options.parameterisation, 'regionalisation')

                regionalisation = geospm.models.Control(g, 'Regionalisation', [], [], []);

                null_probability_l0 = geospm.models.Expression(g, 'Null Probability L0', regionalisation, @(~, r) r(1, 1));
                null_probability_l1 = geospm.models.Expression(g, 'Null Probability L1', regionalisation, @(~, r) r(1, 2));
                null_probability_l2 = geospm.models.Expression(g, 'Null Probability L2', regionalisation, @(~, r) r(1, 3));
                null_probability_l3 = geospm.models.Expression(g, 'Null Probability L3', regionalisation, @(~, r) r(1, 4));

                effect_a_l0 = geospm.models.Expression(g, 'Effect A L0', regionalisation, @(~, r) r(2, 1));
                effect_a_l1 = geospm.models.Expression(g, 'Effect A L1', regionalisation, @(~, r) r(2, 2));
                effect_a_l2 = geospm.models.Expression(g, 'Effect A L2', regionalisation, @(~, r) r(2, 3));
                effect_a_l3 = geospm.models.Expression(g, 'Effect A L3', regionalisation, @(~, r) r(2, 4));

                effect_b_l0 = geospm.models.Expression(g, 'Effect B L0', regionalisation, @(~, r) r(3, 1));
                effect_b_l1 = geospm.models.Expression(g, 'Effect B L1', regionalisation, @(~, r) r(3, 2));
                effect_b_l2 = geospm.models.Expression(g, 'Effect B L2', regionalisation, @(~, r) r(3, 3));
                effect_b_l3 = geospm.models.Expression(g, 'Effect B L3', regionalisation, @(~, r) r(3, 4));

                interaction_effect_l0 = geospm.models.Expression(g, 'Interaction Effect AxB L0', regionalisation, @(~, r) r(4, 1));
                interaction_effect_l1 = geospm.models.Expression(g, 'Interaction Effect AxB L1', regionalisation, @(~, r) r(4, 2));
                interaction_effect_l2 = geospm.models.Expression(g, 'Interaction Effect AxB L2', regionalisation, @(~, r) r(4, 3));
                interaction_effect_l3 = geospm.models.Expression(g, 'Interaction Effect AxB L3', regionalisation, @(~, r) r(4, 4));
            
            else
                error('geospm.validation.generator_models.generate_A_AxB_B_3.configure(): Unknown parameterisation ''%s''', obj.options.parameterisation);
            end
            
            
            radius = geospm.models.Control(g, 'Radius', 0, 100, 40);
            %actual_radius = geospm.models.Control(g, 'Actual Radius', 0, 100, 40);
            actual_radius = radius;
            
            probe_radius = geospm.models.Expression(g, 'Probe Radius', radius, @(~, radius) radius * 0.1);
                
            d1 = geospm.models.Expression(g, 'Radius x 1.5', radius, @(~, radius) radius * 1.5);
            d2 = geospm.models.Expression(g, 'Radius x 4',   radius, @(~, radius) radius * 4);

            if ~obj.options.triangular_layout
                d3 = geospm.models.Expression(g, 'Radius x 6.5', radius, @(~, radius) radius * 6.5);
            else
                d3 = d2;
            end
            
            if obj.options.triangular_layout
                d4 = geospm.models.Expression(g, 'Radius x 2.75', radius, @(~, radius) radius * 2.75);
                d5 = geospm.models.Expression(g, 'Radius x 3.75', radius, @(~, radius) radius * 3.75);
                d6 = geospm.models.Expression(g, 'Radius x 1.5', radius, @(~, radius) radius * 1.5);
            else
                d4 = d2;
                d5 = geospm.models.Expression(g, 'Radius x 1.5', radius, @(~, radius) radius * 1.5);
                d6 = d5;
            end
            
            d7 = geospm.models.Expression(g, 'Radius x 0.5', radius, @(~, radius) radius * 0.5);
            
            
            if ~obj.options.use_fractals
                shape = { 'ellipse' };
            else
                shape = { 'fractal', obj.options.fractal_name, struct('levels', obj.options.fractal_levels) };
            end
            
            
            density = geospm.models.Map(g, 'density', 1);
            
            density.define(...
                    'plane', ...
                    1);

            g.bind_parameter(density, 'density');
            
            
            null_probability_map = geospm.models.Map(g, 'Null Probability Map', 1);
            
            null_probability_map.define( ...
                    shape{:}, ...
                    null_probability_l1, ...
                    d1, ..., ...
                    d5, ...
                    actual_radius, ...
                    actual_radius);
                
            null_probability_map.define( ...
                    shape{:}, ...
                    null_probability_l2, ...
                    d3, ..., ...
                    d5, ...
                    actual_radius, ...
                    actual_radius);
            
            null_probability_map.define( ...
                    shape{:}, ...
                    null_probability_l3, ...
                    d4, ..., ...
                    d6, ...
                    actual_radius, ...
                    actual_radius);

            null_probability_map.define( ...
                    'plane', ...
                    null_probability_l0);
            
            
            g.bind_parameter(null_probability_map, 'null_probability');
            
            effect_a_map = geospm.models.Map(g, 'Effect A Map', 1);
            
            effect_a_map.define( ...
                    shape{:}, ...
                    effect_a_l1, ...
                    d1, ..., ...
                    d5, ...
                    actual_radius, ...
                    actual_radius);
                
            effect_a_map.define( ...
                    shape{:}, ...
                    effect_a_l2, ...
                    d3, ..., ...
                    d5, ...
                    actual_radius, ...
                    actual_radius);
                
            effect_a_map.define( ...
                    shape{:}, ...
                    effect_a_l3, ...
                    d4, ..., ...
                    d6, ...
                    actual_radius, ...
                    actual_radius);

            effect_a_map.define( ...
                    'plane', ...
                    effect_a_l0);
            
            g.bind_parameter(effect_a_map, 'effect_a');
            
            
            effect_b_map = geospm.models.Map(g, 'Effect B Map', 1);
            
            effect_b_map.define( ...
                    shape{:}, ...
                    effect_b_l1, ...
                    d1, ..., ...
                    d5, ...
                    actual_radius, ...
                    actual_radius);
                
            effect_b_map.define( ...
                    shape{:}, ...
                    effect_b_l2, ...
                    d3, ..., ...
                    d5, ...
                    actual_radius, ...
                    actual_radius);
                
            effect_b_map.define( ...
                    shape{:}, ...
                    effect_b_l3, ...
                    d4, ..., ...
                    d6, ...
                    actual_radius, ...
                    actual_radius);

            effect_b_map.define( ...
                    'plane', ...
                    effect_b_l0);
            
            g.bind_parameter(effect_b_map, 'effect_b');
            
            
            interaction_effect_map = geospm.models.Map(g, 'Interaction Effect AxB Map', 1);

            interaction_effect_map.define( ...
                    shape{:}, ...
                    interaction_effect_l1, ...
                    d1, ..., ...
                    d5, ...
                    actual_radius, ...
                    actual_radius);
                
            interaction_effect_map.define( ...
                    shape{:}, ...
                    interaction_effect_l2, ...
                    d3, ..., ...
                    d5, ...
                    actual_radius, ...
                    actual_radius);
                
            interaction_effect_map.define( ...
                    shape{:}, ...
                    interaction_effect_l3, ...
                    d4, ..., ...
                    d6, ...
                    actual_radius, ...
                    actual_radius);

            interaction_effect_map.define( ...
                    'plane', ...
                    interaction_effect_l0);
            
            g.bind_parameter(interaction_effect_map, 'interaction_effect_axb');
            
            
            L1 = geospm.models.Expression(g, 'Probe L1', d1, d5, probe_radius, @(~, x, y, r) [x, y, r]);
            L2 = geospm.models.Expression(g, 'Probe L2', d3, d5, probe_radius, @(~, x, y, r) [x, y, r]);

            if obj.options.triangular_layout
                L0 = geospm.models.Expression(g, 'Probe L0', d7, d6, probe_radius, @(~, x, y, r) [x, y, r]);
            else
                L0 = geospm.models.Expression(g, 'Probe L0', d7, d6, probe_radius, @(~, x, y, r) [x, y, r]);
            end

            L3 = geospm.models.Expression(g, 'Probe L3', d4, d6, probe_radius, @(~, x, y, r) [x, y, r]);

            probe_expressions = {L0, L1, L2, L3};
            
            g.probe_expressions = probe_expressions;
        end
    end
    
    methods (Access=protected)
       
        function result = access_variable_names(~)
            result = {'A', 'B'};
        end
        
        function result = access_spatial_resolution(obj)

            if obj.options.triangular_layout
                result = [220 210];
                %result = [330 315];
            else
                result = [320 120];
            end
        end
        
    end
    
    methods (Static, Access=private)
        
        function result = compute_regionalisation(effect_size)
            
            l0 = [0.25; 0.0; 0.0; 0.0];
            l1 = [(1 - 2 * effect_size) / 4; effect_size; 0.0; 0.0];
            l2 = [(1 - 2 * effect_size) / 4; 0.0; effect_size; 0.0];
            l3 = [(1 - 5 * effect_size) / 4; effect_size; effect_size; effect_size];
            
            result = [l0, l1, l2, l3];
        end
        
    end
    
end
