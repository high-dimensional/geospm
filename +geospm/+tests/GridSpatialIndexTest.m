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


            [tmp_u, tmp_v, tmp_w] = grid.space_to_grid(obj.x, obj.y, obj.z);
            [~, obj.u, obj.v, obj.w] = grid.clip_uvw(tmp_u, tmp_v, tmp_w);
            
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

        function test_select(obj)
            
            n = randi(obj.N);
            row_selection = randperm(obj.N, n);
            
            result = obj.spatial_index.select(row_selection, []);

            segment_indices = obj.spatial_index.segment_index;
            segment_indices = segment_indices(row_selection);

            selected_segment_sizes = geospm.SpatialIndex.segment_indices_to_segment_sizes(segment_indices);
            
            x_selection = obj.x(row_selection);
            y_selection = obj.y(row_selection);
            z_selection = obj.z(row_selection);
            
            u_selection = obj.u(row_selection);
            v_selection = obj.v(row_selection);
            w_selection = obj.w(row_selection);

            obj.verifyEqual(result.x, x_selection, 'Selected x coordinates do not match specification.');
            obj.verifyEqual(result.y, y_selection, 'Selected y coordinates do not match specification.');
            obj.verifyEqual(result.z, z_selection, 'Selected z coordinates do not match specification.');

            obj.verifyEqual(result.u, u_selection, 'Selected u coordinates do not match specification.');
            obj.verifyEqual(result.v, v_selection, 'Selected v coordinates do not match specification.');
            obj.verifyEqual(result.w, w_selection, 'Selected w coordinates do not match specification.');

            obj.verifyEqual(result.segment_sizes, selected_segment_sizes, 'Selected segment sizes do not match specification.');

            obj.verifyEqual(result.N, n, 'Number of selected coordinates does not match specification.');
            obj.verifyEqual(result.N, sum(result.segment_sizes), 'Number of selected coordinates does not match sum of segment sizes.');
            obj.verifyEqual(result.S, numel(result.segment_sizes), 'Number of selected segments does not match number of segment sizes.');
        end
    end
end
