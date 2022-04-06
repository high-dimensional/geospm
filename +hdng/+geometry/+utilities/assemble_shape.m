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

function [shape] = assemble_shape(type, X, Y, parts)
    
    N_vertices = numel(X);

    parts = [parts(2:end); N_vertices + 1];
    
    for j=1:numel(parts)
        parts(j) = parts(j) + j - 1;
    end
    
    last_offset = 1;
    
    shape = struct();
    shape.Geometry = type;
    shape.X = [];
    shape.Y = [];
    
    for j=1:numel(parts)
        offset = parts(j);
        
        shape.X = [shape.X; X(last_offset:offset - 1); NaN];
        shape.Y = [shape.Y; Y(last_offset:offset - 1); NaN];
    end
end
