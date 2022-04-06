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

classdef ControlIterator < hdng.experiments.ValueIterator
    %ControlIterator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        value_generator
        control
    end
    
    methods
        
        function obj = ControlIterator(value_generator, control)
            obj = obj@hdng.experiments.ValueIterator();
            obj.value_generator = value_generator;
            obj.control = control;
        end
        
        function [is_valid, value] = next(obj)
            
            is_valid = false;
            
            value = struct();
            value.control = obj.control;
            value.identifier = obj.control.identifier;
            value.value = [];
            
            value = hdng.experiments.Value.from(value, value.identifier, missing, 'builtin.missing');
        end
        
    end
    
    methods (Static, Access=public)
    end
    
end
