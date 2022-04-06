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

classdef DiscreteQuantity < geospm.models.Quantity
    %DiscreteQuantity Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        values
    end
    
    methods
        
        function obj = DiscreteQuantity(model, name, values)
            d = size(values);
            d = d(3:end);
            
            if isempty(d)
                d = 1;
            end
            
            obj = obj@geospm.models.Quantity(model, name, d);
            obj.values = values;
        end
        
        function [result, optional_entity] = value_at(obj, x, y)
            x = floor(x);
            y = floor(y);
            result = reshape(obj.values(x, y, :), [obj.dimensions 1]);
            optional_entity = [];
        end
        
        function result = flatten(obj)
        	result = obj.values;
        end
    end
    
    methods (Static, Access=private)
    end
    
end
