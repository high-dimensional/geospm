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

classdef WKTWGS84Transformation < handle
    %WKTWGS84Transformation Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        dx
        dy
        dz
        ex
        ey
        ez
        ppm
    end
    
    methods
        
        function obj = WKTWGS84Transformation()
            
            obj.dx = 0.0;
            obj.dy = 0.0;
            obj.dz = 0.0;
            obj.ex = 0.0;
            obj.ey = 0.0;
            obj.ez = 0.0;
            obj.ppm = 0.0;
        end
        
        function set.dx(obj, value)
            
            if ~isnumeric(value)
                error('Expected numeric array value for ''dx'' attribute.');
            end
            
            obj.dx = value;
        end
        
        function set.dy(obj, value)
            
            if ~isnumeric(value)
                error('Expected numeric array value for ''dy'' attribute.');
            end
            
            obj.dy = value;
        end
        
        function set.dz(obj, value)
            
            if ~isnumeric(value)
                error('Expected numeric array value for ''dz'' attribute.');
            end
            
            obj.dz = value;
        end
        
        function set.ex(obj, value)
            
            if ~isnumeric(value)
                error('Expected numeric array value for ''ex'' attribute.');
            end
            
            obj.ex = value;
        end
        
        function set.ey(obj, value)
            
            if ~isnumeric(value)
                error('Expected numeric array value for ''ey'' attribute.');
            end
            
            obj.ey = value;
        end
        
        function set.ez(obj, value)
            
            if ~isnumeric(value)
                error('Expected numeric array value for ''ez'' attribute.');
            end
            
            obj.ez = value;
        end
        
        function set.ppm(obj, value)
            
            if ~isnumeric(value)
                error('Expected numeric array value for ''ppm'' attribute.');
            end
            
            obj.ppm = value;
        end
    end
end
