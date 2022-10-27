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

classdef Stein < geospm.variograms.Function
    %Stein 
    %   
    
    methods
        
        function obj = Stein()
            obj = obj@geospm.variograms.Function();
            obj.parameters = struct();
        end
        
        function [x, y] = evaluate(obj, range_min, range_max, steps)
            
            parameters = obj.parameters;
            
            factor1 = 2.0 * sqrt(parameters.smoothness) / parameters.range;
            factor2 = pow2(1 - parameters.smoothness) / gamma(parameters.smoothness);
            
            
            if steps > 1
                x = (0:steps - 1)' / (steps - 1) * (range_max - range_min) + range_min;
            else
                x = range_min;
            end
            
            y = zeros(steps, 1);
            
            for index=1:steps
                
                if x(index) == 0.0
                    y(index) = 1.0;
                    continue;
                end
                
                bes = besselk(parameters.smoothness, factor1 * x(index));
                
                if ~isfinite(bes)
                    y(index) = 1.0;
                    continue;
                end
                
                if bes == 0.0
                    continue;
                end
                
                mult = factor2 * power(factor1 * x(index), parameters.smoothness);
                
                if ~isfinite(mult)
                    continue;
                end
                
                y(index) = bes * mult;
            end
        end
    end
    
    methods (Access=protected)
        
        function result = access_name(obj) %#ok<MANU>
            result = 'Stein';
        end
        
        function result = access_parameter_names(obj) %#ok<MANU>
            result = {'smoothness', 'range'};
        end
        
        function assign_parameters(obj, value)
            
            if ~isfield(value, 'range')
                value.range = 1.0;
            end
            
            if ~isfield(value, 'smoothness')
                value.smoothness = 1.0;
            end
            
            obj.parameters_ = {};
            
            for index=1:numel(obj.parameter_names)
                name = obj.parameter_names{index};
                obj.parameters_.(name) = value.(name);
            end
            
            obj.parameters_.kappa = sqrt(2.0 * value.smoothness) / value.range;
        end
    end
end
