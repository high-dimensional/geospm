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

function [slice_residual_variances] = compute_per_slice_residual_variance(directory_path)
    
    file_path = [directory_path filesep 'ResMS.nii'];

    if ~exist(file_path, 'file')
        error('Residual file does not exist: %s', file_path);
    end

    slice_residual_variances = geospm.validation.utilities.sum_voxels_per_slice(file_path);
end
