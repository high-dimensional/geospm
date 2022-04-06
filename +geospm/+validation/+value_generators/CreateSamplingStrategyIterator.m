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

classdef CreateSamplingStrategyIterator < hdng.experiments.ValueIterator
    %CreateSamplingStrategyIterator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        value_generator
        arguments
        is_valid
    end
    
    methods
        
        function obj = CreateSamplingStrategyIterator(value_generator, arguments)
            obj = obj@hdng.experiments.ValueIterator();
            obj.value_generator = value_generator;
            obj.arguments = hdng.utilities.struct_to_name_value_sequence(arguments);
            obj.is_valid = true;
        end
        
        function [is_valid, value] = next(obj)
            
            is_valid = obj.is_valid;
            value = [];
            
            if is_valid
                value = geospm.models.SamplingStrategy.create(obj.value_generator.strategy_type, obj.arguments{:});
                value = hdng.experiments.Value.from(value, obj.value_generator.description, missing, 'builtin.missing');
                obj.is_valid = false;
            end
        end
        
    end
    
    methods (Static, Access=private)
    end
    
end
