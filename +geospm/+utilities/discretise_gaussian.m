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

function result = discretise_gaussian(dimensions, mean, covariance, ...
                    method, parameters, show_result)
    % Approximates a Gaussian in a 2 or 3 dimensional grid with the given
    % dimensions, mean and standard deviation.
    %
    % dimensions ? A {2, 3}-vector specifying the dimensions of the grid.
    % mean ? A {2, 3}-vector specifying the location of the mean in grid
    %       coordinates
    % covariance ? A {2x2, 3x3}-matrix specifying the covariance matrix.
    % method ? An identifier specifying the implementation for computing
    % the Gaussian
    % parameters ? Optional parameters used by the method as a struct value
    % show_result ? boolean, indicates whether the result should be
    % plotted.
    
    if ~exist('method', 'var') || isempty(method)
        method = 'matic2';
    end
    
    if ~exist('show_result', 'var')
        show_result = false;
    end
    
    switch method
        
        case 'cdf'
            result = run_cdf(dimensions, mean, covariance, parameters);
            
        case 'spm_smoothto8bit'
            result = run_spm_smoothto8bit(dimensions, mean, covariance, ...
                        parameters);
            
        case 'spm_smooth'
            result = run_spm_smooth(dimensions, mean, covariance, ...
                        parameters);
        
        case 'matic1'
            result = run_matic(dimensions, mean, covariance, 'matic1', ...
                        0.0, 0.0, parameters);
            
        case 'matic2'
            result = run_matic(dimensions, mean, covariance, 'matic2', ...
                        0.0, eps, parameters);
            
        otherwise
            error('geospm.utilities.discretise_gaussian(): Unknown method ''%s''.', method);
    end
    
    if show_result
        
        D = numel(dimensions);
        
        if D == 3
            figure;
            volshow(result);
        elseif D == 2

            [X, Y] = meshgrid(1:dimensions(1), 1:dimensions(2));

            figure;
            surf(X, Y, result);
            
            figure;
            image(result == 0.0, 'CDataMapping', 'scaled');
        end
    end
end


function result = run_cdf(dimensions, mean, covariance, ...
                            parameters) %#ok<INUSD>
    
    result = zeros(dimensions);
    
    % Define the grid locations for which the distribution function
    % should be evaluated. We compute locations for a grid that is
    % one unit larger to account for the fact that we have to take
    % differences.
    
    N_locations = prod(dimensions + 1);
    [X, Y, Z] = ind2sub(dimensions + 1, 1:N_locations);
    
    if numel(dimensions) == 3
        locations = [X', Y', Z'];
    elseif numel(dimensions) == 2
        locations = [X', Y'];
    else
        error('discretise_gaussian(): dimensions must specify 2 or 3 elements.')
    end
    
    % Evaluate the CDF at the locations of the grid
    
    P = mvncdf(locations, mean, covariance);
    P = reshape(P, dimensions+1);
    
    if numel(dimensions) == 2
        
        result = take_differences_2d(P, dimensions);
        
    else
        
        for i=1:dimensions(1)
            for j=1:dimensions(2)
                for k=1:dimensions(3)
                    result(i, j, k) = P(i + 1, j + 1, k + 1) - P(i + 1, j, k + 1) - P(i, j + 1, k + 1) + P(i, j, k + 1) ...
                                 - P(i + 1, j + 1, k) + P(i + 1, j, k) + P(i, j + 1, k) - P(i, j, k);
                end
            end
        end
    end
end

function result = take_differences_2d(P, dimensions)

    result =   P(1:dimensions(1),     1:dimensions(2)) ...
             + P(2:dimensions(1) + 1, 2:dimensions(2) + 1) ...
             - P(1:dimensions(1),     2:dimensions(2) + 1) ...
             - P(2:dimensions(1) + 1, 1:dimensions(2));
end

function check_covariance_is_diagonal(covariance, method)
    if ~isdiag(covariance)
        error('geospm.utilities.discretise_gaussian(): ''%s'' method can only be used with a diagonal covariance matrix.', method);
    end
end

function result = run_matic(dimensions, mean, covariance, method, ...
                    fill_value1, fill_value2, parameters)  %#ok<INUSD>
    
    D = diag(covariance);

    if ~isdiag(covariance)
        error('geospm.utilities.discretise_gaussian(): ''%s'' method can only be used with a diagonal covariance matrix.', method);
    end
    
    result = geospm.utilities.compute_gaussian_cdf_matic_2018(...
        dimensions, mean, D, fill_value1);
    
    mask = result > eps;
    result(~mask) = fill_value2;
end

function result = run_spm_smooth(dimensions, mean, covariance, ...
                    parameters)  %#ok<INUSD>
    
    check_covariance_is_diagonal(covariance, 'spm_smooth');
    
    data = zeros(dimensions);
    
    switch numel(dimensions)
        
        case 2
            data(mean(1), mean(2)) = 1.0;
            
        case 3
            data(mean(1), mean(2), mean(3)) = 1.0;
            
        otherwise
            error('discretise_gaussian(): dimensions must specify 2 or 3 elements.')
    end
    
    fwhm = diag(geospm.utilities.fwhm_from_stddev(sqrt(covariance)));
    
    result = zeros(dimensions);
    spm_smooth(data, result, fwhm);
end

function result = run_spm_smoothto8bit(dimensions, mean, covariance, ...
                    parameters)  %#ok<INUSD>
    
    check_covariance_is_diagonal(covariance, 'spm_smoothto8bit');

    switch numel(dimensions)
        
        case 2
            dimensions = [dimensions, 1];
            mean = [mean 1];
            S = eye(3);
            S(1:2, 1:2) = covariance;
            covariance = S;
            
        case 3
            
            
        otherwise
            error('discretise_gaussian(): dimensions must specify 2 or 3 elements.')
    end
    
    data = zeros(dimensions);
    data(mean(1), mean(2), mean(3)) = 1.0;
    
    result = zeros(dimensions);
    
    vol = blank_spm_volume(dimensions);
    fwhm = diag(geospm.utilities.fwhm_from_stddev(sqrt(covariance)));
    
    result = geospm.utilities.MemSmooth64bit(data, fwhm, vol, result);
end


function result = blank_spm_volume(dimensions, spm_precision)

    if ~exist('spm_precision', 'var')
        spm_precision = 'float64';
    end

    result = struct();

    result.dt = [spm_type(spm_precision) 0];
    result.mat = eye(4);
    result.pinfo = [1 0 0]';
    result.dim = dimensions;
end
