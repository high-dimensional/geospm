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

function variogram_cloud(x, y, values)

    V = values(:) - values(:)';
    V = 0.5 * (V .* V);
    
    dx = cast(x - x', 'double');
    dy = cast(y - y', 'double');
    
    dx = dx .* dx;
    dy = dy .* dy;
    
    D = sqrt(dx + dy);
    
    S = (1:size(V, 1))' <= (1:size(V, 2));
    
    V = V(S);
    D = D(S);
    
    d = [max(x), max(y)] - [min(x), min(y)];
    l = sqrt(sum(d .* d));
    
    df = D <= l;
    
    D_filtered = D(df);
    V_filtered = V(df);
    
    figure;
    scatter(D_filtered(:), V_filtered(:));
end
