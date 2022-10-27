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

classdef Wave < geospm.variograms.Function
    %Wave 
    %   
    
    methods
        
        function obj = Wave()
            obj = obj@geospm.variograms.Function();
            obj.parameters = struct();
        end
        
        function [x, y] = evaluate(obj, range_min, range_max, steps)
            
            parameters = obj.parameters;
            
            if steps > 1
                x = (0:steps - 1)' / (steps - 1) * (range_max - range_min) + range_min;
            else
                x = range_min;
            end
            
            y = zeros(steps, 1);
            
            for index=1:steps
                
                d = x(index) * pi / parameters.range;
                
                y(index) = sin(d);
                
                if d ~= 0.0
                    y(index) = y(index) / d;
                else
                    y(index) = 1.0;
                end
            end
        end
    end
    
    methods (Access=protected)
        
        function result = access_name(obj) %#ok<MANU>
            result = 'Wave';
        end
        
        function result = access_parameter_names(obj) %#ok<MANU>
            result = {'range'};
        end
        
        function assign_parameters(obj, value)
            
            if ~isfield(value, 'range')
                value.range = pi / 2.0;
            end
            
            obj.parameters_ = {};
            
            for index=1:numel(obj.parameter_names)
                name = obj.parameter_names{index};
                obj.parameters_.(name) = value.(name);
            end
        end
    end
end
