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

classdef generate_A_B < geospm.models.GeneratorModel
    %generate_A_B Defines a generator.
    %   Detailed explanation goes here
    
    methods
        
        function obj = generate_A_B(options, varargin)
            
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
            
            if ~isfield(options, 'solid_arrangement')
                options.solid_arrangement = true;
            end
            
            if ~isfield(options, 'nested_arrangement')
                options.nested_arrangement = true;
            end
            
            if ~isfield(options, 'diagonal_layout')
                options.diagonal_layout = false;
            end
            
            obj = obj@geospm.models.GeneratorModel(options);
        end
        
        function configure_generator(obj, g)

            p_A = geospm.models.Control(g, 'A probability', 0, 1, 1);
            p_B = geospm.models.Control(g, 'B probability', 0, 1, 1);

            p_not_A = geospm.models.Expression(g, 'Not A probability', p_A, @(~, p_A) 1 - p_A);
            p_not_B = geospm.models.Expression(g, 'Not B probability', p_B, @(~, p_B) 1 - p_B);

            radius = geospm.models.Control(g, 'Radius', 0, 100, 40);

            probe_radius = geospm.models.Expression(g, 'probe Radius', radius, @(~, radius) radius * 0.15);
                
            d1 = geospm.models.Expression(g, 'Radius x 1.5', radius, @(~, radius) radius * 1.5);
            d2 = geospm.models.Expression(g, 'Radius x 4',   radius, @(~, radius) radius * 4);
            
            if obj.options.solid_arrangement && obj.options.nested_arrangement
                d3 = d2;
            else
                d3 = d1;
            end
            
            inner_radius = geospm.models.Expression(g, 'Radius x 0.5', radius, @(~, radius) radius * 0.5);
            
            density = geospm.models.Map(g, 'density', 1);
            
            density.define(...
                    'plane', ...
                    1);

            g.bind_parameter(density, 'density');
            
            marginal_A = geospm.models.Map(g, 'marginal A', 2);

            if ~obj.options.use_fractals
                shape = { 'ellipse' };
            else
                shape = { 'fractal', obj.options.fractal_name, struct('levels', obj.options.fractal_levels) };
            end
            
            if obj.options.solid_arrangement

                marginal_A.define( ...
                        shape{:}, ...
                        {p_not_A, p_A}, ...
                        d1, ..., ...
                        d3, ...
                        radius, ...
                        radius);
                    
            end
            
            if obj.options.nested_arrangement
                
                if ~obj.options.nested_arrangement
                    l = d1;
                    r = d2;
                else
                    l = d2;
                    r = d1;
                end
                
                marginal_A.define( ...
                        shape{:}, ...
                        {p_A, p_not_A}, ...
                        l, ...
                        d1, ...
                        inner_radius, ...
                        inner_radius);
                
                marginal_A.define( ...
                        shape{:}, ...
                        {p_not_A, p_A}, ...
                        l, ...
                        d1, ...
                        radius, ...
                        radius);
                    
                marginal_A.define( ...
                        shape{:}, ...
                        {p_not_A, p_A}, ...
                        r, ...
                        d1, ...
                        inner_radius, ...
                        inner_radius);
            end
            
            marginal_A.define( ...
                    'plane', ...
                    {p_A, p_not_A});

            g.bind_parameter(marginal_A, 'marginal_distribution', struct('variable_index', 1));

            marginal_B = geospm.models.Map(g, 'marginal B', 2);
            
            if obj.options.solid_arrangement
            
                marginal_B.define( ...
                        shape{:}, ...
                        {p_not_B, p_B}, ...
                        d2, ...
                        d3, ...
                        radius, ...
                        radius);
            end
            
            if obj.options.nested_arrangement
                
                if ~obj.options.nested_arrangement
                    l = d2;
                    r = d1;
                else
                    l = d1;
                    r = d2;
                end
                
                marginal_B.define( ...
                        shape{:}, ...
                        {p_B, p_not_B}, ...
                        l, ...
                        d1, ...
                        inner_radius, ...
                        inner_radius);
                    
                marginal_B.define( ...
                        shape{:}, ...
                        {p_not_B, p_B}, ...
                        l, ...
                        d1, ...
                        radius, ...
                        radius);
                
                marginal_B.define( ...
                        shape{:}, ...
                        {p_not_B, p_B}, ...
                        r, ...
                        d1, ...
                        inner_radius, ...
                        inner_radius);
            end

            marginal_B.define( ...
                    'plane', ...
                    {p_B, p_not_B});

            g.bind_parameter(marginal_B, 'marginal_distribution', struct('variable_index', 2));

            bias_AB = geospm.models.Map(g, 'bias AB', 1);
            
            bias_AB.define( ...
                    'plane', ...
                    0);

            g.bind_parameter(bias_AB, 'binary_bias');
            
            %{
            L1 = geospm.models.Expression(g, 'Probe L1', d1, d5, probe_radius, @(~, x, y, r) [x, y, r]);
            L2 = geospm.models.Expression(g, 'Probe L2', d3, d5, probe_radius, @(~, x, y, r) [x, y, r]);
            
            if obj.options.model_cooccurrence
                
                if obj.options.triangular_layout
                    L0 = geospm.models.Expression(g, 'Probe L0', d7, d6, probe_radius, @(~, x, y, r) [x, y, r]);
                else
                    L0 = geospm.models.Expression(g, 'Probe L0', d7, d6, probe_radius, @(~, x, y, r) [x, y, r]);
                end
                
                L3 = geospm.models.Expression(g, 'Probe L3', d4, d6, probe_radius, @(~, x, y, r) [x, y, r]);
                    
                probe_expressions = {L0, L1, L2, L3};
            else
                L0 = geospm.models.Expression(g, 'Probe L0', d4, d5, probe_radius, @(~, x, y, r) [x, y, r]);
                
                probe_expressions = {L0, L1, L2};
            end
            
            g.probe_expressions = probe_expressions;
            %}
        end
    end
    
    methods (Access=protected)
       
        function result = access_variable_names(~)
            result = {'A', 'B'};
        end
        
        function result = access_spatial_resolution(obj)
            if obj.options.solid_arrangement && obj.options.nested_arrangement
                result = [220 220];
            else
                if ~obj.options.diagonal_layout
                    result = [220 120];
                else
                    result = [220 220];
                end
            end
        end
        
    end
    
    methods (Static, Access=private)
    end
    
end
