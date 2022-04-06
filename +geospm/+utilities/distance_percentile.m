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

function result = distance_percentile(data, location, percentile)
    distances = geospm.utilities.distance_from(data, location);
    [distances, order] = sort(distances);
    position = ceil(data.N * percentile / 100.0);
    limit = distances(position);
    
    while position < data.N
        if distances(position) > limit
            break
        end
        
        position = position + 1;
    end
    
    selection = order(1:position);
    selection = sort(selection);
    
    result = data.select(selection);
end
