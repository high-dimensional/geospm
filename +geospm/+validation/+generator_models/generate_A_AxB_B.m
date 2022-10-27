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

classdef generate_A_AxB_B < geospm.models.GeneratorModel
    %generate_A_AxB_B Defines a generator.
    %   Detailed explanation goes here
    
    methods
        
        function obj = generate_A_AxB_B(options, varargin)
            
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
            
            if ~isfield(options, 'model_cooccurrence')
                options.model_cooccurrence = true;
            end
            
            if ~isfield(options, 'inverted')
                options.inverted = false;
            end
            
            if ~isfield(options, 'interaction_factor')
                options.interaction_factor = 1.0 * options.model_cooccurrence;
            end
            
            options.interaction_factor = options.interaction_factor * options.model_cooccurrence;

            if ~isfield(options, 'triangular_layout')
                options.triangular_layout = true;
            end
            
            obj = obj@geospm.models.GeneratorModel(options);
        end
        
        function configure_generator(obj, g)

            p_A = geospm.models.Control(g, 'A probability', 0, 1, 1);
            p_B = geospm.models.Control(g, 'B probability', 0, 1, 1);

            p_not_A = geospm.models.Expression(g, 'Not A probability', p_A, @(~, p_A) 1 - p_A);
            p_not_B = geospm.models.Expression(g, 'Not B probability', p_B, @(~, p_B) 1 - p_B);
            
            if obj.options.inverted
                tmp = p_A;
                p_A = p_not_A;
                p_not_A = tmp;
                
                tmp = p_B;
                p_B = p_not_B;
                p_not_B = tmp;
            end
            
            radius = geospm.models.Control(g, 'Radius', 0, 100, 40);

            probe_radius = geospm.models.Expression(g, 'probe Radius', radius, @(~, radius) radius * 0.15);
                
            d1 = geospm.models.Expression(g, 'Radius x 1.5', radius, @(~, radius) radius * 1.5);
            d2 = geospm.models.Expression(g, 'Radius x 4',   radius, @(~, radius) radius * 4);

            if obj.options.model_cooccurrence && ~obj.options.triangular_layout
                d3 = geospm.models.Expression(g, 'Radius x 6.5', radius, @(~, radius) radius * 6.5);
            else
                d3 = d2;
            end
            
            if obj.options.model_cooccurrence && obj.options.triangular_layout
                d4 = geospm.models.Expression(g, 'Radius x 2.75', radius, @(~, radius) radius * 2.75);
                d5 = geospm.models.Expression(g, 'Radius x 3.75', radius, @(~, radius) radius * 3.75);
                d6 = geospm.models.Expression(g, 'Radius x 1.5', radius, @(~, radius) radius * 1.5);
            else
                d4 = d2;
                d5 = geospm.models.Expression(g, 'Radius x 1.5', radius, @(~, radius) radius * 1.5);
                d6 = d5;
            end
            
            d7 = geospm.models.Expression(g, 'Radius x 0.5', radius, @(~, radius) radius * 0.5);
            d8 = geospm.models.Expression(g, 'Radius x 5.5', radius, @(~, radius) radius * 5.5);
            d9 = geospm.models.Expression(g, 'Radius x 3.25', radius, @(~, radius) radius * 3.25);
            d10 = geospm.models.Expression(g, 'Radius x 5.25', radius, @(~, radius) radius * 5.25);
            
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
            
            marginal_A.define( ...
                    shape{:}, ...
                    {p_not_A, p_A}, ...
                    d1, ..., ...
                    d5, ...
                    radius, ...
                    radius);

            if obj.options.model_cooccurrence

                marginal_A.define( ...
                        shape{:}, ...
                        {p_not_A, p_A}, ...
                        d4, ...
                        d6, ...
                        radius, ...
                        radius);
            end
            

            if obj.options.inverted
                
                marginal_A.define( ...
                        'polygon', ...
                        {p_not_A, p_A}, ...
                        {d4,  d4, d8,  d8}, ...
                        {d10, d9, 0.0, d10} ...
                        );
            end
                
            marginal_A.define( ...
                    'plane', ...
                    {p_A, p_not_A});
            
            g.bind_parameter(marginal_A, 'marginal_distribution', struct('variable_index', 1));

            marginal_B = geospm.models.Map(g, 'marginal B', 2);

            marginal_B.define( ...
                    shape{:}, ...
                    {p_not_B, p_B}, ...
                    d3, ...
                    d5, ...
                    radius, ...
                    radius);

            if obj.options.model_cooccurrence

                marginal_B.define( ...
                        shape{:}, ...
                        {p_not_B, p_B}, ...
                        d4, ...
                        d6, ...
                        radius, ...
                        radius);
            end
            

            if obj.options.inverted
                
                marginal_B.define( ...
                        'polygon', ...
                        {p_not_B, p_B}, ...
                        {d4,  0.0, 0.0, d4}, ...
                        {d10, d10, 0.0, d9} ...
                        );
            end
            
            marginal_B.define( ...
                    'plane', ...
                    {p_B, p_not_B});

            g.bind_parameter(marginal_B, 'marginal_distribution', struct('variable_index', 2));

            bias_AB = geospm.models.Map(g, 'bias AB', 1);
            
            if obj.options.interaction_factor

                bias_AB.define( ...
                        shape{:}, ...
                        obj.options.interaction_factor, ...
                        d4, ...
                        d6, ...
                        radius, ...
                        radius);
            end
            
            bias_AB.define( ...
                    'plane', ...
                    0);

            g.bind_parameter(bias_AB, 'binary_bias');
            
            target_A = geospm.models.Map(g, 'target A', 1);
            
            target_A.define( ...
                    shape{:}, ...
                    1, ...
                    d1, ..., ...
                    d5, ...
                    radius, ...
                    radius);

            if obj.options.model_cooccurrence
                
                target_A.define( ...
                        shape{:}, ...
                        1, ...
                        d4, ...
                        d6, ...
                        radius, ...
                        radius);
            end
            
            target_A.define( ...
                    'plane', ...
                    0);
            
            g.bind_parameter(target_A, 'target', struct('variable_index', 1));
            
            target_B = geospm.models.Map(g, 'target B', 1);
            
            target_B.define( ...
                    shape{:}, ...
                    1, ...
                    d3, ...
                    d5, ...
                    radius, ...
                    radius);
            
            if obj.options.model_cooccurrence
                
                target_B.define( ...
                        shape{:}, ...
                        1, ...
                        d4, ...
                        d6, ...
                        radius, ...
                        radius);
            end
            
            target_B.define( ...
                    'plane', ...
                    0);
            
            g.bind_parameter(target_B, 'target', struct('variable_index', 2));
                        
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
        end
    end
    
    methods (Access=protected)
       
        function result = access_variable_names(~)
            result = {'A', 'B'};
        end
        
        function result = access_spatial_resolution(obj)
            if obj.options.model_cooccurrence
                
                if obj.options.triangular_layout
                    result = [220 210];
                else
                    result = [320 120];
                end
            else
                result = [220 120];
            end
        end
        
    end
    
    methods (Static, Access=private)
    end
    
end
