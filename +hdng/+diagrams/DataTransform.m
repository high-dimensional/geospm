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

classdef DataTransform < handle
    %DataTransform Summary.  
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (Access=private)
    end

    methods
        function obj = DataTransform()
        end
        
        function result_scope = compute(obj, data_scope, base, parent, siblings) %#ok<INUSD>
            result_scope = data_scope;
        end
    end

    methods (Access=protected)
    
    end
end
