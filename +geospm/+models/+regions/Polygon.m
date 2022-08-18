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

classdef Polygon < geospm.models.Region
    %Polygon Summary
    %   Detailed explanation goes here
    
    properties
    end
    
    properties (SetAccess=private)
        fill
        x
        y
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Polygon(map, fill, x, y)
            obj = obj@geospm.models.Region(map, fill, x, y);
            
            obj.fill = fill;
            obj.x = x;
            obj.y = y;
        end
        
        function render_impl(~, ~, raster_context, fill, x, y)
            raster_context.set_fill(fill);
            raster_context.fill_polygon(x, y);
        end
    end
    
    methods (Static, Access=private)
    end
    
end
