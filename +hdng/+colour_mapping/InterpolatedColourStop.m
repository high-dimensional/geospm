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

classdef InterpolatedColourStop < hdng.colour_mapping.ColourStop
    %InterpolatedColourStop Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        position
    end
    
    methods
        
        function obj = InterpolatedColourStop(colour_model, colour_values, left, right, position)
            
            obj = obj@hdng.colour_mapping.ColourStop(colour_model, colour_values, {left, right});
            obj.position = position;
        end
        
        function value_indices = register_statistics(obj, ~)
            value_indices = obj.requires;
        end
        
        function result = compute_locations(obj, value_indices, batch_results)
            
            N = numel(batch_results);
            result = zeros(1, N);
            
            value_indices = cell2mat(value_indices);
            
            for i=1:N
                values = batch_results{i}.('stops');
                L = values(value_indices(1));
                L = L{1};
                R = values(value_indices(2));
                R = R{1};
                result(i) = L(i) * (1.0 - obj.position)  + R(i) * obj.position;
            end
            
        end
    end
end
