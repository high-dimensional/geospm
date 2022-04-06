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

function p = p_from_stddev_diameter(stddev, diameter, dimensions)

    if ~exist('dimensions', 'var')
        dimensions = 1;
    end

    if ~any(dimensions == [1, 2])
        error('geospm.utilities.p_from_stddev_diameter(): dimensions must be from {1, 2}');
    end
    
    if dimensions == 1
        p = 2 * normcdf(diameter / 2, 0, stddev) - 1;
    else
        p_radius = diameter / (2 * stddev);
        p = chi2cdf(p_radius^2, 2);
    end
end
