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

function result = compute_neighbourhood_index_at(image, x, y)
    % x ranges in [2, size(image, 2)] and
    % y ranges in [2, size(image, 1)]
    
    %{
    
     4 8
     1 2
    
    %}
    
    result =   1 + image(y - 1, x - 1) ...
             + 2 * image(y - 1, x) ...
             + 4 * image(y, x - 1) ...
             + 8 * image(y, x);
end
