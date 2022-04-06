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

classdef Quantity < handle
    %Quantity Represents the spatial distribution of a (multi-dimensional) value.
    %   Detailed explanation goes here
    
    properties
        model
        name
        nth_quantity
        
        dimensions
    end
    
    methods
        
        function obj = Quantity(model, name, dimensions)
            obj.model = model;
            obj.name = name;
            obj.nth_quantity = 0;
            obj.dimensions = dimensions;
            
            obj.nth_quantity = obj.model.add_quantity(obj);
        end
        
        function [result, optional_entity] = value_at(obj, x, y) %#ok<INUSD,STOUT>
        	error('Quantity.value_at() must be implemented by a subclass.');
        end
        
        function result = flatten(obj) %#ok<MANU,STOUT>
        	error('Quantity.flatten() must be implemented by a subclass.');
        end
        
    end
    
    methods (Static, Access=private)
    end
    
end
