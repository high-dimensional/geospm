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

classdef GridTest < matlab.unittest.TestCase
 
    properties
    end
 
    methods(TestMethodSetup)
        
        function initialise(~)
        end
        
    end
 
    methods(TestMethodTeardown)
    end
 
    methods
    end
    
    methods(Test)
        
        function test_min_point_maps_to_min_cell(obj)
            
            g = geospm.Grid();
            g.define('resolution', [200, 300, 400], 'cell_size', [0.1, 0.1, 0.1]);
            
            p = num2cell(g.origin);
            [u, v, w] = g.space_to_grid(p{:});
            obj.verifyEqual([u, v, w], int64([1, 1, 1]), 'Grid origin should map to 1, 1, 1.');
        end
        
        function test_max_point_maps_to_max_cell(obj)
            
            g = geospm.Grid();
            g.define('resolution', [200, 300, 400], 'cell_size', [0.1, 0.1, 0.1]);
            
            p = num2cell(g.resolution .* g.cell_size + g.origin - eps * 100);
            [u, v, w] = g.space_to_grid(p{:});
            obj.verifyEqual([u, v, w], int64(g.resolution), 'Grid corner should map to grid resolution.');
        end
        
    end
end
