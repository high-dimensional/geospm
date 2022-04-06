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

classdef SkipValue < hdng.experiments.ValueDirective
    
    %SkipValue Indicates that a value is to be skipped
    %
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=public, SetAccess=public)
    end
    
    properties (GetAccess=public, SetAccess=private)
    end
    
    methods
        
        function obj = SkipValue()
            obj = obj@hdng.experiments.ValueDirective();
        end
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
