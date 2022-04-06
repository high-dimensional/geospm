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

classdef Rectangle < geospm.models.Region
    %Rectangle Summary
    %   Detailed explanation goes here
    
    properties
    end
    
    properties (SetAccess=private)
        fill
        x
        y
        width
        height
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Rectangle(map, fill, x, y, width, height)
            obj = obj@geospm.models.Region(map, fill, x, y, width, height);
            
            obj.fill = fill;
            obj.x = x;
            obj.y = y;
            obj.width = width;
            obj.height = height;
        end
        
        function render_impl(~, ~, raster_context, fill, x, y, width, height)
            raster_context.set_fill(fill);
            raster_context.fill_rect(x, y, width, height);
        end
    end
    
    methods (Static, Access=private)
    end
    
end
