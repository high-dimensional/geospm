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

classdef WKTAuthority < matlab.mixin.Copyable
    %WKTParameter Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        name
        code
    end
    
    methods
        
        function obj = WKTAuthority(name, code)
            
            if ~ischar(name)
                error('Expected char array value for ''name'' attribute.');
            end
            
            if ~isnumeric(code) && ~ischar(code)
                error('Expected numeric value or char array for ''code'' attribute.');
            end
            
            if isnumeric(code)
                code = num2str(code, '%d');
            end
            
            obj.name = name;
            obj.code = code;
        end
        
        function result = format(obj)
            
            result = strcat('AUTHORITY[', ']');
            
        end
    end
end
