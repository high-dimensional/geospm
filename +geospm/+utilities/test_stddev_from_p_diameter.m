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

function test_stddev_from_p_diameter(p, diameter, dimensions, N)

    if ~exist('dimensions', 'var')
        dimensions = 2;
    end

    if ~exist('N', 'var')
        N = 1e4;
    end

    stddev = geospm.utilities.stddev_from_p_diameter(p, diameter, dimensions);
    
    switch(dimensions)

        case 1
            P = normrnd(0, stddev, 1, N);

            selector = abs(P) <= (diameter / 2.0);
            S = sum(selector, 'all');

            f = sum(selector) / N;
            
            fprintf('Measured frequency of samples in an interval with length %.2f: %1.2f\n', diameter, f);
            fprintf('Computed stddev: %.5f\n', stddev);
            
            figure;
            
            ax = gca;
            axis(ax, 'equal');
            
            hold on;
            
            plot(P(selector), ones(1, S), '+', 'MarkerFaceColor', 'blue');
            plot(P(~selector), ones(1, N - S), '+', 'MarkerFaceColor', 'red');
            
            hold off;



        case 2
            P = mvnrnd([0 0], eye(2) * stddev * stddev, N);
            
            X = P(:,1);
            Y = P(:,2);
            
            D = sqrt(power(X, 2) + power(Y, 2));
            
            selector = D <= (diameter / 2.0);
            
            f = sum(selector) / N;
            
            fprintf('Measured frequency of samples in a circle with diameter %.2f: %1.2f\n', diameter, f);
            fprintf('Computed stddev: %.5f\n', stddev);
            
            figure;
            
            ax = gca;
            axis(ax, 'equal');
            
            hold on;
            
            plot(X(selector), Y(selector), '+', 'MarkerFaceColor', 'blue');
            plot(X(~selector), Y(~selector), '+', 'MarkerFaceColor', 'red');
            
            hold off;


        case 3
            P = mvnrnd([0 0 0], eye(3) * stddev * stddev, N);
            
            X = P(:,1);
            Y = P(:,2);
            Z = P(:,3);
            
            D = sqrt(power(X, 2) + power(Y, 2) + power(Z, 2));
            
            selector = D <= (diameter / 2.0);
            
            f = sum(selector) / N;
            
            fprintf('Measured frequency of samples in a sphere with diameter %.2f: %1.2f\n', diameter, f);
            fprintf('Computed stddev: %.5f\n', stddev);
            
            figure;
            
            ax = gca;
            axis(ax, 'equal');
            
            hold on;
            
            plot3(X(selector), Y(selector), Z(selector), '+', 'MarkerFaceColor', 'blue');
            plot3(X(~selector), Y(~selector), Z(~selector), '+', 'MarkerFaceColor', 'red');
            
            hold off;
    end
end
