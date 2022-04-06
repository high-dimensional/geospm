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

classdef A < geospm.models.GeneratorModel
    %A Defines a generator.
    %   Detailed explanation goes here
    
    methods
        
        function obj = A(options, varargin)
            
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
            
            obj = obj@geospm.models.GeneratorModel(options);
        end
        
        function configure_generator(obj, g)
            
            p_A = geospm.models.Control(g, 'A probability', 0, 1, 1);

            p_not_A = geospm.models.Expression(g, 'Not A probability', p_A, @(~, p_A) 1 - p_A);

            radius = geospm.models.Control(g, 'Radius', 0, 100, 40);
            
            probe_radius = geospm.models.Expression(g, 'probe Radius', radius, @(~, radius) radius * 0.3);

            d1 = geospm.models.Expression(g, 'Radius x 1.5', radius, @(~, radius) radius * 1.5);
            d2 = geospm.models.Expression(g, 'Radius x 1.5', radius, @(~, radius) radius * 1.5);

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
                    d1, ...
                    d2, ...
                    radius, ...
                    radius);

            marginal_A.define( ...
                    'plane', ...
                    {p_A, p_not_A});

            g.bind_parameter(marginal_A, 'marginal_distribution', struct('variable_index', 1));
            
            L0 = geospm.models.Expression(g, 'Probe L0', probe_radius, probe_radius, probe_radius, @(~, x, y, r) [x, y, r]);
            L1 = geospm.models.Expression(g, 'Probe L1', d1, d2, probe_radius, @(~, x, y, r) [x, y, r]);
            
            g.probe_expressions = {L0, L1};
        end
    end
    
    methods (Access=protected)
       
        function result = access_variable_names(~)
            result = {'A'};
        end
        
        function result = access_spatial_resolution(~)
            result = [120 120];
        end
        
    end
    
    methods (Static, Access=private)
    end
    
end
