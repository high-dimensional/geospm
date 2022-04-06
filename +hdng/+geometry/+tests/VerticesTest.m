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

classdef VerticesTest < matlab.unittest.TestCase
 
    properties
    end
 
    methods(TestMethodSetup)
        
        function initialise(obj)
        end
        
    end
 
    methods(TestMethodTeardown)
    end
 
    methods
    end
    
    methods(Test)
        
        function test_orientation(obj)
            
            coords = [10, 100; 10, 10; 110, 110; 10, 100];
            ccw_polygon = hdng.geometry.Polygon.define(coords, 1);
            result_1 = ccw_polygon.vertices.is_clockwise_xy(1, ccw_polygon.vertices.N_vertices - 1);
            
            
            coords = [10, 100; 110, 110; 10, 10; 10, 100];
            cw_polygon = hdng.geometry.Polygon.define(coords, 1);
            result_2 = cw_polygon.vertices.is_clockwise_xy(1, cw_polygon.vertices.N_vertices - 1);
            
            
        end
        
    end
end
