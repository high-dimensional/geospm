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

function [shapes, parts, coordinates] = disassemble_shapevector(shapevector, offset_type)
    
    if ~exist('offset_type', 'var')
        offset_type = 'int64';
    end
    
    N_shapes = numel(shapevector);
    
    N_vertices_estimate = 0;
    
    for i=1:N_shapes
        N_vertices_estimate = N_vertices_estimate + numel(shapevector(i).X);
    end
    
    shapes = zeros(N_vertices_estimate, 1, 'int32');
    parts = zeros(N_vertices_estimate, 1, 'int32');
    coordinates = zeros(N_vertices_estimate, 2);
    
    N_result_shapes = 0;
    N_coordinates = 0;
    N_parts = 0;
    
    for i=1:N_shapes

        [shape_x, shape_y, shape_parts] = hdng.geometry.utilities.disassemble_shape(shapevector(i), offset_type);
        
        shape_parts = shape_parts + N_coordinates;

        shapes(N_result_shapes + 1) = N_parts + 1;
        parts(N_parts + 1:N_parts + numel(shape_parts)) = shape_parts;
        coordinates(N_coordinates + 1:N_coordinates + numel(shape_x), :) = [shape_x, shape_y];
        
        N_result_shapes = N_result_shapes + 1;
        N_parts = N_parts + numel(shape_parts);
        N_coordinates = N_coordinates + numel(shape_x);
    end

    shapes = shapes(1:N_result_shapes);
    parts = parts(1:N_parts);
    coordinates = coordinates(1:N_coordinates, :);
end
