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

classdef WKTParameter < matlab.mixin.Copyable
    %WKTParameter Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        name
        value
    end
    
    methods
        
        function obj = WKTParameter(name, value)
            
            if ~ischar(name)
                error('Expected char array value for ''name'' attribute.');
            end
            
            if ~isnumeric(value) && ~ischar(value)
                error('Expected numeric value or char array for ''value'' attribute.');
            end
            
            obj.name = name;
            obj.value = value;
        end
    end
end
