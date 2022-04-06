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

classdef Parameter < matlab.mixin.Copyable
    %Fractal Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        identifier
        default_value
        description
    end
    
    methods
        
        function obj = Parameter(identifier, default_value, description)
            
            if ~exist('description', 'var')
                description = '';
            end
            
            obj.identifier = identifier;
            obj.default_value = default_value;
            obj.description = description;
        end
    end
end
