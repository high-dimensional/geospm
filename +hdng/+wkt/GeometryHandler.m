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

classdef GeometryHandler < handle
    %GeometryHandler Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        
        function obj = GeometryHandler()
        end
        
        function result = handle_points(obj, collection) %#ok<INUSD,STOUT>
        end
        
        function result = handle_polylines(obj, collection) %#ok<INUSD,STOUT>
        end
        
        function result = handle_polygons(obj, collection) %#ok<INUSD,STOUT>
        end
    end
    
end
