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

function [fwhm, resels] = compute_per_slice_smoothness(SPM)
    
    df = [SPM.nscan SPM.xX.erdf];
    
    residuals_file_pattern = '^(ResI_[0-9]+\.nii)$';
    [file_paths, file_names] = hdng.utilities.scan_files(SPM.swd, residuals_file_pattern);
    
    N_slices = SPM.xVol.DIM(3);
    
    V_cells = spm_vol(file_paths);
    V = struct([]);
    
    for index=1:numel(V_cells)
        
        name = file_names{index};
        name = name{1};
        file_names{index} = name{1};
        
        if index == 1
            V = V_cells{index};
            %data = spm_read_vols(V);
            %N_slices = size(data, 3);
        else
            V(index) = V_cells{index};
        end
    end
    
    VM = spm_vol([SPM.swd filesep SPM.VM.fname]);
    
    resels = zeros(N_slices, 4);
    fwhm = zeros(N_slices, 3);
    
    tmp_directory = [SPM.swd filesep 'tmp'];
    
    for index=1:N_slices
        
        [dirstatus, dirmsg, ~] = mkdir(tmp_directory);
        if dirstatus ~= 1; error(dirmsg); end

        saved_wd = cd(tmp_directory);
        
        residuals = spm_read_vols(V);
        residual_volumes = struct([]);
        
        for r_index=1:numel(file_names)
            name = file_names{r_index};
            data = residuals(:, :, index, r_index);
            
            if r_index == 1
                residual_volumes = geospm.utilities.write_nifti(data, name);
            else
                residual_volumes(r_index) = geospm.utilities.write_nifti(data, name);
            end
        end
        
        mask = spm_read_vols(VM);
        data = mask(:, :, index);
        mask_volume = write_nifti(data, 'mask.nii');
        
        [slice_fwhm, ~,R] = spm_est_smoothness(residual_volumes, mask_volume, df);
        
        resels(index, :) = R;
        fwhm(index, :) = slice_fwhm;
        
        [file_paths, ~] = hdng.utilities.list_files(tmp_directory);
        
        hdng.utilities.delete(false, file_paths{:});
        
        cd(saved_wd);
        
        hdng.utilities.rmdir(tmp_directory, true, false);
    end
end
