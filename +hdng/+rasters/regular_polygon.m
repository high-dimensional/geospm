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

function [x, y] = regular_polygon(N_sides)
    
    %regular_polygon Defines an n-sided, equiangular and equilateral polygon.
    
    N_vertices = N_sides;
    x = zeros(N_vertices, 1);
    y = zeros(N_vertices, 1);

    for i=1:N_vertices

        r = 2.0 * pi * (i / N_vertices);

        x(i) = cos(r);
        y(i) = sin(r);
    end
end
