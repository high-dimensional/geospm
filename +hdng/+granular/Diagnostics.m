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

classdef Diagnostics < handle
    
    %Diagnostics Description to follow.
    
    properties
    end
    
    
    properties (GetAccess=public, SetAccess=private)
        errors
        warnings
    end

    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = Diagnostics()
            obj.errors = {};
            obj.warnings = {};
        end
    end
    
    methods (Access=protected)
        
    end
    
    methods (Static, Access=public)
    end
    
end
