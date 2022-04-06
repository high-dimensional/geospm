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

function [vertices, offsets] = concat_vertices(primitives)
    
    N = numel(primitives);
    
    has_z_count = 0;
    N_coordinates = 0;
    
    for i=1:N
        value = primitives{i};
        
        N_coordinates = N_coordinates + value.vertices.N_vertices;
        has_z_count = has_z_count + value.vertices.has_z;
    end
    
    if has_z_count ~= 0 && has_z_count ~= N
        error('Primitives must all have the same dimensionality.');
    end

    has_z = has_z_count ~= 0;
    
    offsets = zeros(N, 1, 'int64');
    coordinates = zeros(N_coordinates, 2 + has_z);
    N_coordinates = 0;
    
    for i=1:N
        value = primitives{i};

        array = value.vertices.coordinates;
        range = N_coordinates + 1:N_coordinates + size(array, 1);

        if has_z && value.vertices.has_z
            coordinates(range, 1:3) = array;
        else
            coordinates(range, 1:2) = array(:, 1:2);
        end
        
        offsets(i) = N_coordinates + 1;

        N_coordinates = N_coordinates + size(array, 1);
    end

    vertices = hdng.geometry.Vertices.define(coordinates, 1);
end
