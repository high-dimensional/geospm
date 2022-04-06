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

classdef Variable < handle
    %Variable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        domain
        name
        nth_variable
    end
    
    methods
        
        function obj = Variable(domain, name)
            obj.domain = domain;
            obj.name = name;
            obj.nth_variable = obj.domain.add_variable(obj);
        end
    end
    
    methods (Static, Access=private)
    end
    
end
