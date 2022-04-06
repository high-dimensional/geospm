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

function stddev = stddev_from_p_diameter(p, diameter, dimensions)
    
    if ~exist('dimensions', 'var')
        dimensions = 1;
    end

    if ~any(dimensions == [1, 2])
        error('geospm.utilities.stddev_from_p_diameter(): dimensions must be from {1, 2}');
    end
    
    if dimensions == 1
        k = (p + 1) / 2; % Calculate the equivalent cdf probability 
                         % for a two-tailed region of probability p.

        cv = diameter / 2; % Calculate the critical value as half the diameter,
                           % because the corresponding interval extends from
                           % -cv to +cv.

        stddev = cv / norminv(k); % The standard deviation is the ratio between
                                 % the desired critical value and the critical
                                 % value for the same k with unitary standard
                                 % deviation.
    else
        
        radius = diameter / 2;
        p_radius = sqrt(spm_invXcdf(p, 2));
        stddev = radius / p_radius;
    end
    
    
end
