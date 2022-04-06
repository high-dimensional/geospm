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

function write_nifti(data, file_path, data_type)
    
    if ~exist('data_type', 'var')
        data_type = spm_type('float64');
    end
    
    dims = size(data);
    
    while numel(dims) < 3
        dims = [dims 1]; %#ok<AGROW>
    end
    
    V=[];
    V.dt=[data_type 0];
    V.mat = eye(4);
    V.pinfo = [1 0 0]';
    V.fname = file_path;
    V.dim = dims;
    
    spm_write_vol(V, data);
end
