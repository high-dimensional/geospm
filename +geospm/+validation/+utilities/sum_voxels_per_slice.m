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

function [result, counts] = sum_voxels_per_slice(volume_path, mask_path)
    V = spm_vol(volume_path);
    data_volume = spm_read_vols(V);
    
    if exist('mask_path', 'var')
       M = spm_vol(mask_path);
       mask_volume = spm_read_vols(M) > 0;
    else
       mask_volume = ones(size(data_volume), 'logical');
    end
    
    
    
    N_slices = size(data_volume, 3);
    
    result = zeros(1, N_slices);
    counts = zeros(1, N_slices);
    
    
    for slice_index=1:N_slices
        data_slice = data_volume(:, :, slice_index);
        mask_slice = mask_volume(:, :, slice_index);
        
        result(slice_index) = sum(data_slice(mask_slice), 'all');
        counts(slice_index) = sum(mask_slice(:));
    end
end
