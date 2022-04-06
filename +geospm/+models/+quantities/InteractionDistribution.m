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

classdef InteractionDistribution < geospm.models.Quantity
    %InteractionDistribution Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        null_factor
        interaction_effect
        balance_factor
    end
    
    methods
        
        function obj = InteractionDistribution(model, name, null_factor, interaction_effect, balance_factor)
            
            obj = obj@geospm.models.Quantity(model, name, [2, 2]);
            
            obj.null_factor = null_factor;
            obj.interaction_effect = interaction_effect;
            obj.balance_factor = balance_factor;
        end
        
        function [result, optional_entity] = value_at(obj, x, y)
            
            distribution = geospm.models.Distribution(obj.dimensions);
            
            p0_relative = obj.null_factor.value_at(x, y);
            
            c3 = obj.interaction_effect.value_at(x, y);
            sum_p1_p2 = 0.5 - 0.5 * c3;
            
            b = obj.balance_factor.value_at(x, y);
            t = 0.5 + 0.5 * b;
            
            p1 = t * sum_p1_p2;
            p2 = (1.0 - t) * sum_p1_p2;
            p0 = p0_relative * (1 - p1 - p2);
            p3 = 1 - p0 - p1 - p2;
            
            p = [p0, p2; p1, p3];
            
            distribution.compute_from_masses(p);
            
            result = distribution.masses;
            optional_entity = distribution;
        end
        
        
        function result = flatten(obj)
            
            result = zeros([obj.model.spatial_resolution obj.dimensions]);
            
            p0_relative = obj.null_factor.flatten();
            
            c3 = obj.interaction_effect.flatten();
            sum_p1_p2 = 0.5 - 0.5 .* c3;
            
            b = obj.balance_factor.flatten();
            t = 0.5 + 0.5 .* b;
            
            p1 = t .* sum_p1_p2;
            p2 = (1.0 - t) .* sum_p1_p2;
            p0 = p0_relative .* (1 - p1 - p2);
            p3 = 1 - p0 - p1 - p2;
            
            result(:, :, 1, 1) = p0;
            result(:, :, 2, 1) = p1;
            result(:, :, 1, 2) = p2;
            result(:, :, 2, 2) = p3;
        end
        
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=private)
    end
    
end
