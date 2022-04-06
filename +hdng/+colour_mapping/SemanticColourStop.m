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

classdef SemanticColourStop < hdng.colour_mapping.ColourStop
    %SemanticColourStop Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        label
        arguments
    end
    
    methods
        
        function obj = SemanticColourStop(colour_model, colour_values, label, arguments)
            
            obj = obj@hdng.colour_mapping.ColourStop(colour_model, colour_values);
            
            if ~exist('arguments', 'var')
                arguments = struct();
            end
            
            obj.label = label;
            obj.arguments = arguments;
        end
        
        function value_indices = register_statistics(obj, image_statistics)
            entry = image_statistics.require_statistic(obj.label, obj.arguments);
            value_indices = entry.index;
        end
        
        function result = compute_locations(obj, value_indices, batch_results)
            
            N = numel(batch_results);
            result = zeros(1, N);
            
            for i=1:N
                values = batch_results{i}.(obj.label);
                result(i) = values{value_indices};
            end
        end
        
    end
end
