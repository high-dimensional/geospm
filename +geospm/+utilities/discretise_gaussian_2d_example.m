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

function discretise_gaussian_2d_example()
    
    self_path = mfilename('fullpath');
    [directory, ~, ~] = fileparts(self_path);
    [~, parent_name, ~] = fileparts(directory);
    
    if strcmp(parent_name, '+utilities')
        method_name = @geospm.utilities.discretise_gaussian;
    else
        method_name = @discretise_gaussian;
    end
    
    image_centre = [100, 100];
    variance = 80;
    zero_constant = 10e-10;
    zero_constant = eps;
    show_result = false;
    
    %{
    pdf_data = method_name(image_centre * 2 - 1, image_centre, eye(2) * variance, zero_constant, 'pdf');
    imwrite(pdf_data * 255.0, 'gaussian_pdf.png');
    
    pdf_data_mask = pdf_data == zero_constant;
    imwrite(pdf_data_mask, 'gaussian_pdf_mask.png');
    
    save('gaussian_pdf.mat', 'pdf_data');
    %}
    
    cdf_data = method_name(image_centre * 2 - 1, image_centre, eye(2) * variance, zero_constant, 'cdf', show_result);
    
    geospm.utilities.write_nifti(cdf_data, 'gaussian_cdf.nii');
    
    mass = sum(cdf_data, 'all');
    
    fprintf('CDF mass: %f\n', mass);
    
    cdf_data_mask = cdf_data > zero_constant;
    imwrite(cdf_data_mask, 'gaussian_cdf_mask.png');
    
    save('gaussian_cdf.mat', 'cdf_data');
    
    min_cdf = min(cdf_data, [], 'all');
    max_cdf = max(cdf_data, [], 'all');
    
    cdf_data = (cdf_data - min_cdf) ./ (max_cdf - min_cdf);
    
    imwrite(cdf_data, 'gaussian_cdf.png');
    
end
