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

function test_stddev_from_p_diameter(p, diameter, dimensions)

    if ~exist('dimensions', 'var')
        dimensions = 1;
    end

    stddev = geospm.utilities.stddev_from_p_diameter(p, diameter, dimensions);
    
    N = 10e3;
    P = mvnrnd([0 0], eye(2) * stddev * stddev, N);
    
    X = P(:,1);
    Y = P(:,2);
    
    D = sqrt(power(X, 2) + power(Y, 2));
    
    selector = D <= (diameter / 2.0);
    
    f = sum(selector) / N;
    
    fprintf('Measured frequency of samples in a circle with diameter %.2f: %1.2f\n', diameter, f);
    
    figure;
    
    ax = gca;
    axis(ax, 'equal');
    
    hold on;
    
    plot(X(selector), Y(selector), '+', 'MarkerFaceColor', 'blue');
    plot(X(~selector), Y(~selector), '+', 'MarkerFaceColor', 'red');
    
    hold off;
end
