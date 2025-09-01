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

classdef Generator < hdng.diagrams.Definition
    %Generator Summary.
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Generator()
            obj = obj@hdng.diagrams.Definition('generator');
        end

        function scopes = apply(obj, scope, child_data_level) %#ok<INUSD>
            scopes = {};
        end

    end
end
