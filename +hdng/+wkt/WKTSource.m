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

classdef WKTSource < matlab.mixin.Copyable
    %WKTSource Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        url
        text
    end
    
    methods
        
        function obj = WKTSource()
            
            obj.url = '';
            obj.text = '';
        end
        
        function set.url(obj, value)
            
            if ~ischar(value)
                error('Expected char array value for ''url'' attribute.');
            end
            
            obj.url = value;
        end
        
        function set.text(obj, value)
            
            if ~ischar(value)
                error('Expected char array value for ''text'' attribute.');
            end
            
            obj.text = value;
        end
    end
end
