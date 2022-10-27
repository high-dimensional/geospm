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

function discretise_gaussian_2d_example(method, parameters, variances)
    
    if ~exist('method', 'var')
        method = 'cdf';
    end
    
    if ~exist('parameters', 'var')
        parameters = struct();
    end
    
    if ~exist('variances', 'var')
        variances = 80;
    end

    self_path = mfilename('fullpath');
    [directory, ~, ~] = fileparts(self_path);
    [~, parent_name, ~] = fileparts(directory);
    
    if strcmp(parent_name, '+utilities')
        method_name = @geospm.utilities.discretise_gaussian;
    else
        method_name = @discretise_gaussian;
    end
    
    image_centre = [100, 100];
    zero_constant = eps;
    show_result = false;
    
    g_data = method_name(image_centre * 2 - 1, image_centre, eye(2) .* variances, method, parameters, show_result);
    
    name = sprintf('gaussian_%s', method);
    
    geospm.utilities.write_nifti(g_data, [name '.nii']);
    
    mass = sum(g_data, 'all');
    
    fprintf('CDF mass: %f\n', mass);
    
    cdf_data_mask = g_data > zero_constant;
    imwrite(cdf_data_mask, [name '_mask.png']);
    
    values = g_data;
    eval([method,' = g_data;']);
    
    save([name '.mat'], 'values', method);
    
    min_cdf = min(g_data, [], 'all');
    max_cdf = max(g_data, [], 'all');
    
    g_data = (g_data - min_cdf) ./ (max_cdf - min_cdf);
    
    imwrite(g_data, [name '.png']);
    
end
