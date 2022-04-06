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

classdef generate_A_AxB_B_2 < geospm.models.GeneratorModel
    %generate_A_AxB_B_2 Defines a generator.
    %   Detailed explanation goes here
    
    methods
        
        function obj = generate_A_AxB_B_2(options, varargin)
            
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
            
            obj = obj@geospm.models.GeneratorModel(options);
        end
        
        function configure_generator(obj, g)

            interaction_effect = geospm.models.Control(g, 'Interaction Effect AxB', -1, 1, 0);
            
            balance_A = geospm.models.Control(g, 'Balance A', -1, 1, 0);
            balance_B = geospm.models.Expression(g, 'Balance B', balance_A, @(~, balance_A) -balance_A);
            
            null_factors = geospm.models.Control(g, 'Null Factors', 0, 1, 0);
            null_factor_l0 = geospm.models.Expression(g, 'Null Factor L0', null_factors, @(~, null_factors) null_factors(1));
            null_factor_l1 = geospm.models.Expression(g, 'Null Factor L1', null_factors, @(~, null_factors) null_factors(2));
            null_factor_l2 = geospm.models.Expression(g, 'Null Factor L2', null_factors, @(~, null_factors) null_factors(3));
            null_factor_l3 = geospm.models.Expression(g, 'Null Factor L3', null_factors, @(~, null_factors) null_factors(4));
            
            radius = geospm.models.Control(g, 'Radius', 0, 100, 40);

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
            
            interaction_effect_map = geospm.models.Map(g, 'Interaction Effect', 1);

            interaction_effect_map.define( ...
                    shape{:}, ...
                    interaction_effect, ...
                    d4, ..., ...
                    d6, ...
                    radius, ...
                    radius);

            interaction_effect_map.define( ...
                    'plane', ...
                    0);
            
            g.bind_parameter(interaction_effect_map, 'interaction_effect');
            
            
            balance_factor_map = geospm.models.Map(g, 'Balance Factor', 1);
            
            
            balance_factor_map.define( ...
                    shape{:}, ...
                    balance_A, ...
                    d1, ..., ...
                    d5, ...
                    radius, ...
                    radius);
                
            balance_factor_map.define( ...
                    shape{:}, ...
                    balance_B, ...
                    d3, ..., ...
                    d5, ...
                    radius, ...
                    radius);
            
            balance_factor_map.define( ...
                    shape{:}, ...
                    0.0, ...
                    d4, ..., ...
                    d6, ...
                    radius, ...
                    radius);

            balance_factor_map.define( ...
                    'plane', ...
                    0.0);
            
            g.bind_parameter(balance_factor_map, 'balance_factor');
            
            null_factor_map = geospm.models.Map(g, 'Null Factor', 1);
            
            null_factor_map.define( ...
                    shape{:}, ...
                    null_factor_l1, ...
                    d1, ..., ...
                    d5, ...
                    radius, ...
                    radius);
                
            null_factor_map.define( ...
                    shape{:}, ...
                    null_factor_l2, ...
                    d3, ..., ...
                    d5, ...
                    radius, ...
                    radius);
            
            null_factor_map.define( ...
                    shape{:}, ...
                    null_factor_l3, ...
                    d4, ..., ...
                    d6, ...
                    radius, ...
                    radius);

            null_factor_map.define( ...
                    'plane', ...
                    null_factor_l0);
            
            
            g.bind_parameter(null_factor_map, 'null_factor');
            
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
            else
                result = [320 120];
            end
        end
        
    end
    
    methods (Static, Access=private)
    end
    
end
