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

classdef DependencyControlIterator < geospm.validation.value_generators.ControlIterator
    %DependencyControlIterator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        is_valid
        value
        expression
    end
    
    methods
        
        function obj = DependencyControlIterator(value_generator, control, value, expression)
            obj = obj@geospm.validation.value_generators.ControlIterator(value_generator, control);
            obj.is_valid = true;
            obj.value = value;
            
            if ~exist('expression', 'var')
                expression = @(value, description) [value, description];
            end
            
            obj.expression = expression;
        end
        
        function [is_valid, value] = next(obj)
            
            is_valid = obj.is_valid;
            value = struct();
            value.control = obj.control;
            value.identifier = obj.control.identifier;
            value.value = obj.value;
            
            if is_valid
                obj.is_valid = false;
                
                description = hdng.experiments.label_for_content(value.value);
                [value.value, description] = obj.expression(obj.value, description);
                
                value = hdng.experiments.Value.from(value, description, missing, 'builtin.missing');
            end
        end
        
    end
    
    methods (Static, Access=public)
    end
    
end
