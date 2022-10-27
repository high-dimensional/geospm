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

classdef Nugget < geospm.variograms.Function
    %Nugget 
    %
    
    methods
        
        function obj = Nugget()
            obj = obj@geospm.variograms.Function();
            obj.parameters = struct();
        end
        
        function [x, y] = evaluate(obj, range_min, range_max, steps) %#ok<INUSL>
            
            %parameters = obj.parameters;
            
            if steps > 1
                x = (0:steps - 1)' / (steps - 1) * (range_max - range_min) + range_min;
            else
                x = range_min;
            end
            
            y = zeros(steps, 1);
            y(1) = 1.0;
        end
    end
    
    methods (Access=protected)
        
        function result = access_name(obj) %#ok<MANU>
            result = 'Nugget';
        end
        
        function result = access_parameter_names(obj) %#ok<MANU>
            result = {};
        end
        
        function assign_parameters(obj, value)
            
            obj.parameters_ = {};
            
            for index=1:numel(obj.parameter_names)
                name = obj.parameter_names{index};
                obj.parameters_.(name) = value.(name);
            end
        end
    end
end
