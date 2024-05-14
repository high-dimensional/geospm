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
        N
        x
        y
        z
    end
 
    methods

        function assign_instance(obj)
        end

        
        function initialise_with_options(obj, varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            obj.N = randi(1000);
            
            if isfield(options, 'N') && ~isempty(options.N)
                obj.N = options.N;
            end

            % number of duplicates
            K = randi(obj.N - 1);

            if isfield(options, 'K') && ~isempty(options.K)
                K = options.K;
            end
            
            duplicates = randi(obj.N - K, [K, 1]);
            duplicates = sort(duplicates, 'descend');

            unique_xyz = rand(obj.N - K, 3) * 100;

            xyz = zeros(obj.N, 3);
            xyz(1:obj.N - K, :) = unique_xyz;

            for index=1:numel(duplicates)
                choice = duplicates(index);
                M = obj.N - K + index - 1; % Effective array size
                xyz(choice + 1:M + 1, :) = xyz(choice:M, :);
            end

            obj.x = xyz(:, 1);
            obj.y = xyz(:, 2);
            obj.z = xyz(:, 3);
            
            obj.assign_instance();
        end
        
        function result = generate_grid(~)
            
            origin = randi(100, [1, 3]);
            span = randi(100, [1, 3]);
            resolution = randi(100, [1, 3]);
            cell_size = span ./ resolution;
            flip = cast(randi(2, [1, 2]) - 1, 'logical');

            result = geospm.Grid();
            result.define(...
                'origin', origin, ...
                'cell_size', cell_size, ...
                'flip_u', flip(1), ...
                'flip_v', flip(2), ...
                'resolution', resolution ...
                );

        end

        function [u, v, w] = transform(obj, T, as_integers)
        
            if ~exist('as_integers', 'var')
                as_integers = true;
            end

            result = T * [obj.x(:)'; obj.y(:)'; obj.z(:)'; ones(1, numel(obj.x))];
            result = result(1:3, :) ./ result(4, :);
            
            if as_integers
                result = cast(floor(result), 'int64');
            end
            
            u = result(1, :)';
            v = result(2, :)';
            w = result(3, :)';
            
        end
    end
 
    methods(TestMethodSetup)

        function initialise1(obj)
            obj.initialise_with_options();
        end
    end
 
    methods(TestMethodTeardown)
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

        function test_concatenation(obj)

            A = obj.generate_grid();
            B = obj.generate_grid();

            for index=1:16

                A.flip_u = index & 8;
                A.flip_v = index & 4;
                B.flip_u = index & 2;
                B.flip_v = index & 1;

                C = geospm.Grid.concat(A, B);
    
                [u, v, w] = C.space_to_grid(obj.x, obj.y, obj.z);
                uvw = [u, v, w];
    
                At = A.space_to_grid_transform;
                Bt = B.space_to_grid_concatenable_transform;
                T = At * Bt;
    
                obj.verifyEqual(C.space_to_grid_transform, T, 'Transformations do not match.', 'AbsTol', 1e-10);
    
                [u_control, v_control, w_control] = obj.transform(T);
                uvw_control = [u_control, v_control, w_control];
    
                obj.verifyEqual(uvw, uvw_control, 'Transformed point sets do not match.');

            end
        end

    end
end
