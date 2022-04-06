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

classdef Drawing < handle
    %Drawing Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        shapes
    end
    
    properties
    end
    
    methods
        function obj = Drawing(shapes)
            
            obj.shapes = shapes;
        end
        
        function draw(obj, raster_context)
            
            for i=numel(obj.shapes)
                obj.shapes{i}.draw(raster_context);
            end
        end
        
    end
    
    methods (Static)
    end
end
