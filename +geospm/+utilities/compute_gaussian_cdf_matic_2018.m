% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2022,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function result = compute_gaussian_cdf_matic_2018(dimensions, mean, variance, fill_value)
    % Approximates a spherical Gaussian in a 2 or 3 dimensional grid with
    % the given dimensions, mean and variance.
    %
    % dimensions ? A {2, 3}-vector specifying the dimensions of the grid.
    % mean ? A {2, 3}-vector specifying the location of the mean in grid
    %       coordinates
    % variance ? A {2, 3}-vector for the variance of each dimension.
    % fill_value ? The constant to use for values which evaluated to zero
    
    if ~exist('fill_value', 'var')
        fill_value = 0.0;
    end
    
    result = compute_normal_cdf(dimensions, mean, variance, fill_value);
end


function y = cdf_upper_bound(x)
    x_sq = x .* x;
    root_half_pi = sqrt(pi * 0.5);
    
    y = 1 - root_half_pi .* exp(- x_sq * 0.5) ...
            ./ (sqrt(x_sq + 2 * pi) + (pi - 1) .* x);
end

function y = cdf_lower_bound(x)
    x_sq = x .* x;
    root_half_pi = sqrt(pi * 0.5);
    
    y = 1 - root_half_pi .* exp(- x_sq * 0.5) ...
        ./ (sqrt((pi - 2)^2 .* x_sq + 2 * pi) + 2 .* x);
end


function y = evaluate_1d_standard_cdf_at(x)
    % 1d standard Gaussian approximation
    % This is based on F_hat_5 described in 
    % "A sharp Pólya-based approximation to the normal cumulative 
    % distribution function" by Matic et al.
    % [Applied Mathematics and Computation 322 (2018) 111–122]
    
    persistent GAMMA;
    
    if isempty(GAMMA)
        
        pi_sq = pi * pi;
        pi_cu = pi * pi_sq;
        
        GAMMA = [ ...
            -1 / 3  + 1 / pi, ...
             7 / 90 - 2 / (3 * pi) + 4 / (3 * pi_sq), ...
            -1 / 70 + 4 / (15 * pi) - 4 / (3 * pi_sq) + 2 / pi_cu, ...
            83 / 37800 - 76 / (945 * pi) + 34 / (45 * pi_sq) - 8 / (3 * pi_cu) + 16 / (5 * pi * pi_cu), ...
            0.00000014841 ...
            ];
    end

    x_sq = x .* x;
    
    exponent = x_sq;
    factor = x_sq;
    
    for i=1:5
        factor = factor .* x_sq;
        exponent = exponent + GAMMA(i) .* factor;
    end
    
    y = zeros(numel(x), 1);
    
    
    selector_r = x >  2.5;
    selector_l = x < -2.5;
        
    selector = ~selector_l & ~selector_r;
    
    uf = 0.732;
    lf = 1.0 - uf;
    
    y(selector) = 0.5 + 0.5 .* sign(x(selector)) .* sqrt(1 - exp(-2 / pi .* exponent(selector)));
    y(selector_r) = uf .* cdf_upper_bound(x(selector_r)) + lf .* cdf_lower_bound(x(selector_r));
    y(selector_l) = 1 - uf .* cdf_upper_bound(-x(selector_l)) - lf .* cdf_lower_bound(-x(selector_l));
end


function values = evaluate_standard_cdf_at(spans, mean, variance)
    
    sigma = sqrt(variance);
    
    switch size(spans, 2)
        case 1
            
            zx = (spans{1} - mean) ./ sigma;
            X = evaluate_1d_standard_cdf_at(zx);
            values = {X};
        case 2
            
            zx = (spans{1} - mean(1)) ./ sigma(1);
            zy = (spans{2} - mean(2)) ./ sigma(2);
            
            X = evaluate_1d_standard_cdf_at(zx);
            Y = evaluate_1d_standard_cdf_at(zy);
            values = {X, Y};
        case 3
            zx = (spans{1} - mean(1)) ./ sigma(1);
            zy = (spans{2} - mean(2)) ./ sigma(2);
            zz = (spans{3} - mean(3)) ./ sigma(3);
            
            X = evaluate_1d_standard_cdf_at(zx);
            Y = evaluate_1d_standard_cdf_at(zy);
            Z = evaluate_1d_standard_cdf_at(zz);
            values = {X, Y, Z};
        otherwise
            error('compute_gaussian_cdf_matic_2018.evaluate_standard_cdf_at(): locations must specify 1, 2 or 3 dimensions.')
    end

end

function spans = compute_grid_spans(dimensions)

    switch numel(dimensions)
        case 1
            spans = {(1:dimensions(1))'};
        case 2
            spans = {(1:dimensions(1))', (1:dimensions(2))'};
        case 3
            spans = {(1:dimensions(1))', (1:dimensions(2))', (1:dimensions(3))'};
        otherwise
            error('compute_gaussian_cdf_matic_2018.compute_grid_spans(): dimensions must specify 1, 2 or 3 elements.')
    end
end

function [first, last] = find_non_zero_range(values)
    selector = values > 0.0;
    first = find(selector, 1);
    last = find(selector, 1, 'last');
end

function values = fill_zeros(values, fill_value)
    [first, last] = find_non_zero_range(values);
    
    values(1:first - 1) = fill_value;
    values(last + 1:end) = fill_value;
end

function values = compute_normal_cdf(dimensions, mean, variance, fill_value)
    
    spans = compute_grid_spans(dimensions+1);
    values = evaluate_standard_cdf_at(spans, mean, variance);
    
    switch numel(dimensions)
        case 1
            
            X = values{1};
            
            X = X(2:end) - X(1:end - 1); X = fill_zeros(X, fill_value);
            
            values = X;
            
        case 2
            
            X = values{1};
            Y = values{2};
            
            X = X(2:end) - X(1:end - 1); X = fill_zeros(X, fill_value);
            Y = Y(2:end) - Y(1:end - 1); Y = fill_zeros(Y, fill_value);
            
            values = X .* Y';
            
        case 3
            
            X = values{1};
            Y = values{2};
            Z = values{3};
            
            X = X(2:end) - X(1:end - 1); X = fill_zeros(X, fill_value);
            Y = Y(2:end) - Y(1:end - 1); Y = fill_zeros(Y, fill_value);
            Z = Z(2:end) - Z(1:end - 1); Z = fill_zeros(Z, fill_value);
            
            f = X .* Y';
            
            values = reshape(kron(Z', f),[size(f), numel(Z)]);
        otherwise
            error('compute_gaussian_cdf_matic_2018.compute_normal_cdf(): locations must specify 1, 2 or 3 dimensions.');
    end
end
