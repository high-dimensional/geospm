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

classdef ListControlIterator < geospm.validation.value_generators.ControlIterator
    %ListControlIterator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        index
        values
    end
    
    methods
        
        function obj = ListControlIterator(value_generator, control, values)
            obj = obj@geospm.validation.value_generators.ControlIterator(value_generator, control);
            obj.index = 1;
            obj.values = values;
        end
        
        function [is_valid, value] = next(obj)
            
            is_valid = obj.index <= numel(obj.values);
            value = struct();
            value.control = obj.control;
            value.identifier = obj.control.identifier;
            value.value = [];
            
            if is_valid
                value.value = obj.values{obj.index};
                value = hdng.experiments.Value.from(value, hdng.experiments.label_for_content(value.value), missing, 'builtin.missing');
            end
            
            obj.index = obj.index + 1;
        end
        
    end
    
    methods (Static, Access=private)
    end
    
end
