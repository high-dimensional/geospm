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

classdef GridSpatialIndexTest < geospm.tests.SpatialIndexTest

    properties
        u
        v
        w
    end

    methods

        function assign_instance(obj)

            resolution = [100, 100, 100];

            grid = geospm.Grid();

            scale = 0.68;
            std_xyz = [std(obj.x), std(obj.y), std(obj.z)];

            d = std_xyz * scale / 25;

            grid.span_frame([min(obj.x), min(obj.y), min(obj.z)] - d, ...
                            [max(obj.x), max(obj.y), max(obj.z)] + d, ...
                            resolution);


            [~, uvw] = grid.select_xyz([obj.x, obj.y, obj.z]);
            
            obj.u = uvw(:, 1);
            obj.v = uvw(:, 2);
            obj.w = uvw(:, 3);

            obj.spatial_index = geospm.GridSpatialIndex(obj.u, obj.v, obj.w, obj.x, obj.y, obj.z, obj.segments, resolution, grid); 
        end
        
    end
 
    methods(TestMethodSetup)
    end
 
    methods(TestMethodTeardown)
    end
 
    methods(Static)
    end
    
    methods(Test)
        

        function test_u(obj)
            [~] = obj.spatial_index.u;
        end
        
        function test_v(obj)
            [~] = obj.spatial_index.v;
        end
        
        function test_w(obj)
            [~] = obj.spatial_index.w;
        end

        function test_N_uvw_consistent(obj)
            obj.verifyEqual([obj.spatial_index.N, 1], size(obj.spatial_index.u), 'N and dimensions of u do not agree');
            obj.verifyEqual(size(obj.spatial_index.u), size(obj.spatial_index.v), 'u and v dimensions do not agree');
            obj.verifyEqual(size(obj.spatial_index.u), size(obj.spatial_index.w), 'u and w dimensions do not agree');
        end

        function test_ctor(obj)

            test_ctor@geospm.tests.SpatialIndexTest(obj);

            obj.verifyEqual(obj.spatial_index.u, obj.u, 'u ctor argument and u attribute do not agree');
            obj.verifyEqual(obj.spatial_index.v, obj.v, 'v ctor argument and v attribute do not agree');
            obj.verifyEqual(obj.spatial_index.w, obj.w, 'w ctor argument and w attribute do not agree');
        end

        function test_u_min_max(obj)
            obj.verifyEqual(obj.spatial_index.u_min, min(obj.u), 'u_min does not match actual minimum');
            obj.verifyEqual(obj.spatial_index.u_max, max(obj.u), 'u_max does not match actual maximum');
        end
        
        function test_v_min_max(obj)
            obj.verifyEqual(obj.spatial_index.v_min, min(obj.v), 'v_min does not match actual minimum');
            obj.verifyEqual(obj.spatial_index.v_max, max(obj.v), 'v_max does not match actual maximum');
        end
        
        function test_w_min_max(obj)
            obj.verifyEqual(obj.spatial_index.w_min, min(obj.w), 'w_min does not match actual minimum');
            obj.verifyEqual(obj.spatial_index.w_max, max(obj.w), 'w_max does not match actual maximum');
        end
        
        function test_uv_min_max(obj)
            obj.verifyEqual(obj.spatial_index.min_uv, [min(obj.u), min(obj.v)], 'min_uv does not match actual minimum');
            obj.verifyEqual(obj.spatial_index.max_uv, [max(obj.u), max(obj.v)], 'max_uv does not match actual maximum');
        end
        
        function test_uvw_min_max(obj)
            obj.verifyEqual(obj.spatial_index.min_uvw, [min(obj.u), min(obj.v), min(obj.w)], 'min_uvw does not match actual minimum');
            obj.verifyEqual(obj.spatial_index.max_uvw, [max(obj.u), max(obj.v), max(obj.w)], 'max_uvw does not match actual maximum');
        end
        
        function test_uvw(obj)
            obj.verifyEqual(obj.spatial_index.uvw, [obj.u, obj.v, obj.w], 'uvw does not match actual concatenation uvw');
        end
    end
end
