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

function locations = cdf_mesh(dimensions)
    % Computes the mesh node locations for a grid of the specified 
    % dimensions.
    
    N_locations = prod(dimensions + 1);
    [X, Y, Z] = ind2sub(dimensions + 1, 1:N_locations);
    
    if numel(dimensions) == 3
        locations = [X', Y', Z'];
    elseif numel(dimensions) == 2
        locations = [X', Y'];
    else
        error('cdf_mesh(): dimensions must specify 2 or 3 elements.')
    end
end
