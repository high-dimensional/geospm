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

classdef Handler < handle
    %Handler Summary goes here.
    %
    
    methods
        
        function obj = Handler()
        end
        
        function result = handle_points(~, points) %#ok<INUSD>
            result = [];
        end
        
        function result = handle_polylines(~, polylines) %#ok<INUSD>
            result = [];
        end
        
        function result = handle_polygons(~, polygons) %#ok<INUSD>
            result = [];
        end
    end
    
end
