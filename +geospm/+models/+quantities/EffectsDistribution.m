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

classdef EffectsDistribution < geospm.models.Quantity
    %EffectsDistribution Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        null_probability
        effect_1
        effect_2
        interaction_effect
    end
    
    methods
        
        function obj = EffectsDistribution(model, name, null_probability, ...
                effect_1, effect_2, interaction_effect )
            
            obj = obj@geospm.models.Quantity(model, name, [2, 2]);
            
            obj.null_probability = null_probability;
            obj.effect_1 = effect_1;
            obj.effect_2 = effect_2;
            obj.interaction_effect = interaction_effect;
        end
        
        function [result, optional_entity] = value_at(obj, x, y)
            
            distribution = geospm.models.Distribution(obj.dimensions);
            
            p0 = obj.null_probability.value_at(x, y);
            c1 = obj.effect_1.value_at(x, y);
            c2 = obj.effect_2.value_at(x, y);
            c3 = obj.interaction_effect.value_at(x, y);
            
            p = [p0, p0 + c2; p0 + c1, p0 + c1 + c2 + c3];
            
            if any(p < 0, 'all') || any(p > 1, 'all')
                error('geospm.models.quantities.EffectsDistribution.value_at(): One or more computed probabilities are invalid.');
            end
            
            distribution.compute_from_masses(p);
            
            result = distribution.masses ./ sum(distribution.masses(:));
            optional_entity = distribution;
        end
        
        
        function result = flatten(obj)
            
            result = zeros([obj.model.spatial_resolution obj.dimensions]);
            
            p0 = obj.null_probability.flatten();
            c1 = obj.effect_1.flatten();
            c2 = obj.effect_2.flatten();
            c3 = obj.interaction_effect.flatten();
            
            p1 = p0 + c1;
            p2 = p0 + c2;
            p3 = p0 + c1 + c2 + c3;
            
            if any(p0 < 0, 'all') || any(p0 > 1, 'all')
                error('geospm.models.quantities.EffectsDistribution.flatten(): One or more computed p0 probabilities are invalid.');
            end
            
            if any(p1 < 0, 'all') || any(p1 > 1, 'all')
                error('geospm.models.quantities.EffectsDistribution.flatten(): One or more computed p1 probabilities are invalid.');
            end
            
            if any(p2 < 0, 'all') || any(p2 > 1, 'all')
                error('geospm.models.quantities.EffectsDistribution.flatten(): One or more computed p2 probabilities are invalid.');
            end
            
            if any(p3 < 0, 'all') || any(p3 > 1, 'all')
                error('geospm.models.quantities.EffectsDistribution.flatten(): One or more computed p3 probabilities are invalid.');
            end
            
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
