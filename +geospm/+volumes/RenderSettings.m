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

classdef RenderSettings < handle
    
    %RenderSettings 
    %
    
    properties (GetAccess=public, SetAccess=private)
    end
    
    properties (GetAccess=public, SetAccess=public)
        formats
        grid
        crs
        centre_pixels
    end
    
    properties (Dependent, Transient)
        
    end
    
    
    properties (GetAccess=private, SetAccess=private)
        
    end
    
    methods
        
        function obj = RenderSettings()
            
            obj.formats = {'png', 'tif'};
            
            obj.grid = geospm.Grid.empty;
            obj.crs = hdng.SpatialCRS.empty;
            obj.centre_pixels = true;
        end
    end
end
