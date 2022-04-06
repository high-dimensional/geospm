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

function diameter = diameter_from_p_stddev(p, stddev, dimensions)

    if ~exist('dimensions', 'var')
        dimensions = 1;
    end

    if ~any(dimensions == [1, 2])
        error('geospm.utilities.diameter_from_p_stddev(): dimensions must be from {1, 2}');
    end
    
    if dimensions == 1
        k = (p + 1) / 2; % Calculate the equivalent cdf probability 
                         % for a two-tailed region of probablity p.

        cv = norminv(k, 0, stddev); % Compute the critical value of k for 
                                   % a distribution with the given standard
                                   % variation.

        diameter = 2 * cv; % The diameter is twice the critical value as the
                           % corresponding interval extends from -cv to +cv.
    else
        
        p_radius = sqrt(spm_invXcdf(p, 2));
        diameter = stddev * p_radius * 2;
    end
end
