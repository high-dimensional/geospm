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

function result = gather_spm_residual_sums(directory_path)
    
    file_name = 'ResMS.nii';

    directories = geospm.validation.utilities.iterate_spm_directories(directory_path);
    
    result = cell(numel(directories), 2);
    result_length = 0;
    
    for index=1:numel(directories)
        session_path = directories{index};
        
        residual_path = [session_path filesep file_name];
        
        if ~exist(residual_path, 'file')
            warning('Residual file does not exist, skipping: %s', session_path);
            continue
        end
        
        [~, min_index] = geospm.validation.utilities.compute_per_slice_residual_variance(session_path);
        
        result_length = result_length + 1;
        result{result_length, 1} = residual_path;
        result{result_length, 2} = min_index;
    end
    
    result = result(1:result_length, :);
end
