% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2019,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function [data, data_type] = read_nifti(file_path)
        
    uncompressed_file_path = file_path;

    if endsWith(file_path, '.gz')
        uncompressed_file_path = gunzip(file_path);
        uncompressed_file_path = uncompressed_file_path{1};
    end

    V = spm_vol(uncompressed_file_path);
    data_type = V.dt(1);
    
    data = spm_read_vols(V);

    if ~strcmp(uncompressed_file_path, file_path)
        hdng.utilities.delete(false, uncompressed_file_path);
    end
end
