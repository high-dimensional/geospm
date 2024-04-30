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

classdef SpatialIndexTest < matlab.unittest.TestCase
 
    properties
        N
        S
        x
        y
        z
        segments
        spatial_index
    end

    methods

        function assign_instance(obj)
            obj.spatial_index = geospm.SpatialIndex(obj.x, obj.y, obj.z, obj.segments); 
        end

        
        function initialise_with_options(obj, varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            obj.N = randi(1000);
            
            if isfield(options, 'N') && ~isempty(options.N)
                obj.N = options.N;
            end

            obj.S = randi(obj.N);
            
            if isfield(options, 'S') && ~isempty(options.S)
                obj.S = options.S;
            end
            
            % number of duplicates
            K = randi(obj.N - 1);

            if isfield(options, 'K') && ~isempty(options.K)
                K = options.K;
            end
            
            duplicates = randi(obj.N - K, [K, 1]);
            duplicates = sort(duplicates, 'descend');

            unique_xyz = rand(obj.N - K, 3);

            xyz = zeros(obj.N, 3);
            xyz(1:obj.N - K, :) = unique_xyz;

            for index=1:numel(duplicates)
                choice = duplicates(index);
                M = obj.N - K + index - 1; % Effective array size
                xyz(choice + 1:M + 1, :) = xyz(choice:M, :);
            end

            %{
            obj.x = rand(obj.N, 1);
            obj.y = rand(obj.N, 1);
            obj.z = rand(obj.N, 1);
            %}

            obj.x = xyz(:, 1);
            obj.y = xyz(:, 2);
            obj.z = xyz(:, 3);
            

            obj.segments = geospm.tests.SpatialIndexTest.generate_segments(obj.S, obj.N);

            obj.assign_instance();
        end
        
    end
 
    methods(TestMethodSetup)

        function initialise1(obj)
            obj.initialise_with_options();
        end
    end
 
    methods(TestMethodTeardown)
    end
 
    methods(Static)

        function result = generate_segments(S, N)

            result = ones(S, 1);
            
            % Each segment has at least one point, so only assign 
            % the remaining N - S points

            for index=S + 1:N
                % Choose a random segment and increase its count by one.
                r = randi(S);
                result(r) = result(r) + 1;
            end
        end
    end
    
    methods(Test)
        
        function test_N(obj)
            [~] = obj.spatial_index.N;
        end

        function test_S(obj)
            [~] = obj.spatial_index.S;
        end

        function test_x(obj)
            [~] = obj.spatial_index.x;
        end
        
        function test_y(obj)
            [~] = obj.spatial_index.y;
        end
        
        function test_z(obj)
            [~] = obj.spatial_index.z;
        end

        function test_N_xyz_consistent(obj)
            obj.verifyEqual([obj.spatial_index.N, 1], size(obj.spatial_index.x), 'N and dimensions of x do not agree');
            obj.verifyEqual(size(obj.spatial_index.x), size(obj.spatial_index.y), 'x and y dimensions do not agree');
            obj.verifyEqual(size(obj.spatial_index.x), size(obj.spatial_index.z), 'x and z dimensions do not agree');
        end

        function test_S_offsets_sizes_consistent(obj)
            obj.verifyEqual([obj.spatial_index.S, 1], size(obj.spatial_index.segment_offsets), 'S and dimensions of segment offsets do not agree');
            obj.verifyEqual(size(obj.spatial_index.segment_offsets), size(obj.spatial_index.segment_sizes), 'segment offsets and segment sizes dimensions do not agree');
        end

        function test_ctor(obj)

            obj.verifyEqual(obj.spatial_index.N, obj.N, 'N and N attribute do not agree');
            obj.verifyEqual(obj.spatial_index.S, obj.S, 'S and S attribute do not agree');

            obj.verifyEqual(obj.spatial_index.x, obj.x, 'x ctor argument and x attribute do not agree');
            obj.verifyEqual(obj.spatial_index.y, obj.y, 'y ctor argument and y attribute do not agree');
            obj.verifyEqual(obj.spatial_index.z, obj.z, 'z ctor argument and z attribute do not agree');
            
            obj.verifyEqual(obj.spatial_index.segment_sizes, obj.segments, 'segment sizes do not agree with specification');

            actual_segments = [diff(obj.spatial_index.segment_offsets); obj.N - obj.spatial_index.segment_offsets(end) + 1];
            obj.verifyEqual(actual_segments, obj.segments, 'segment offsets do not agree with specification');
        end

        function test_segment_indices(obj)

            segment_index = 1;
            segment_counts = obj.segments;

            expected_indices = zeros(obj.S, 1);

            for position=1:obj.N
                

                expected_indices(position) = segment_index;
                segment_counts(segment_index) = segment_counts(segment_index) - 1;

                if segment_counts(segment_index) == 0
                    segment_index = segment_index + 1;
                end
            end

            obj.verifyEqual(obj.spatial_index.segment_index, expected_indices, 'segment indices do not agree with specification');
        end

        function test_x_min_max(obj)
            obj.verifyEqual(obj.spatial_index.x_min, min(obj.x), 'x_min does not match actual minimum');
            obj.verifyEqual(obj.spatial_index.x_max, max(obj.x), 'x_max does not match actual maximum');
        end
        
        function test_y_min_max(obj)
            obj.verifyEqual(obj.spatial_index.y_min, min(obj.y), 'y_min does not match actual minimum');
            obj.verifyEqual(obj.spatial_index.y_max, max(obj.y), 'y_max does not match actual maximum');
        end
        
        function test_z_min_max(obj)
            obj.verifyEqual(obj.spatial_index.z_min, min(obj.z), 'z_min does not match actual minimum');
            obj.verifyEqual(obj.spatial_index.z_max, max(obj.z), 'z_max does not match actual maximum');
        end
        
        function test_xy_min_max(obj)
            obj.verifyEqual(obj.spatial_index.min_xy, [min(obj.x), min(obj.y)], 'min_xy does not match actual minimum');
            obj.verifyEqual(obj.spatial_index.max_xy, [max(obj.x), max(obj.y)], 'max_xy does not match actual maximum');
        end
        
        function test_xyz_min_max(obj)
            obj.verifyEqual(obj.spatial_index.min_xyz, [min(obj.x), min(obj.y), min(obj.z)], 'min_xyz does not match actual minimum');
            obj.verifyEqual(obj.spatial_index.max_xyz, [max(obj.x), max(obj.y), max(obj.z)], 'max_xyz does not match actual maximum');
        end
        
        function test_centroid_x(obj)
            obj.verifyEqual(obj.spatial_index.centroid_x, mean(obj.x), 'centroid_x does not match actual mean value of x');
        end
        
        function test_centroid_y(obj)
            obj.verifyEqual(obj.spatial_index.centroid_y, mean(obj.y), 'centroid_y does not match actual mean value of y');
        end
        
        function test_centroid_z(obj)
            obj.verifyEqual(obj.spatial_index.centroid_z, mean(obj.z), 'centroid_z does not match actual mean value of z');
        end
        
        function test_centroid_xyz(obj)
            obj.verifyEqual(obj.spatial_index.centroid_xyz, [mean(obj.x), mean(obj.y), mean(obj.z)], 'centroid_xyz does not match actual mean value of xyz');
        end
        
        function test_xyz(obj)
            obj.verifyEqual(obj.spatial_index.xyz, [obj.x, obj.y, obj.z], 'xyz does not match actual concatenation xyz');
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

            obj.verifyEqual(result.segment_sizes, selected_segment_sizes, 'Selected segment sizes do not match specification.');

            obj.verifyEqual(result.x, x_selection, 'Selected x coordinates do not match specification.');
            obj.verifyEqual(result.y, y_selection, 'Selected y coordinates do not match specification.');
            obj.verifyEqual(result.z, z_selection, 'Selected z coordinates do not match specification.');

            obj.verifyEqual(result.N, n, 'Number of selected coordinates does not match specification.');
            obj.verifyEqual(result.N, sum(result.segment_sizes), 'Number of selected coordinates does not match sum of segment sizes.');
            obj.verifyEqual(result.S, numel(result.segment_sizes), 'Number of selected segments does not match number of segment sizes.');
        end

        function test_select_by_segment(obj)
        
            s = randi(obj.S);
            segment_selection = randperm(obj.S, s);
            
            result = obj.spatial_index.select_by_segment(segment_selection);
            row_selection = obj.spatial_index.row_indices_from_segment_indices(segment_selection);
            
            segment_indices = obj.spatial_index.segment_index;
            segment_indices = segment_indices(row_selection);

            selected_segment_sizes = geospm.SpatialIndex.segment_indices_to_segment_sizes(segment_indices);

            x_selection = obj.x(row_selection);
            y_selection = obj.y(row_selection);
            z_selection = obj.z(row_selection);

            obj.verifyEqual(result.segment_sizes, selected_segment_sizes, 'Selected segment sizes do not match specification.');

            obj.verifyEqual(result.x, x_selection, 'Selected x coordinates do not match specification.');
            obj.verifyEqual(result.y, y_selection, 'Selected y coordinates do not match specification.');
            obj.verifyEqual(result.z, z_selection, 'Selected z coordinates do not match specification.');

            obj.verifyEqual(result.N, sum(result.segment_sizes), 'Number of selected coordinates does not match sum of segment sizes.');
            obj.verifyEqual(result.S, s, 'Number of selected segments does not match specification.');
            obj.verifyEqual(result.S, numel(result.segment_sizes), 'Number of selected segments does not match number of segment sizes.');

        end
    end
end
