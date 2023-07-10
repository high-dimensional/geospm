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

function result = compute_neighbourhood_from_index(index)
    % index ranges from [1, 16]
    
    result = [0, 0; 0, 0];
    
    value = index - 1;
    
    result(2, 1) = (value & 1) ~= 0;
    result(2, 2) = (value & 2) ~= 0;
    result(1, 1) = (value & 4) ~= 0;
    result(1, 2) = (value & 8) ~= 0;
end
