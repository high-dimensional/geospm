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

function result = compute_per_slice_critical_height_thresholds(SPM, alpha, stat, resels)
    
    Ic = 1;
    
    if (any(diff(double(cat(1,SPM.xCon(Ic).STAT)))) || ...
                any(abs(diff(cat(1,SPM.xCon(Ic).eidf))) > 1))
        error('Illegal conjunction: can only conjoin SPMs of same STAT and df');
    end
    
    df = [SPM.xCon(Ic(1)).eidf SPM.xX.erdf];
    
    N_slices = SPM.xVol.DIM(3);
    S = SPM.xVol.DIM(1) * SPM.xVol.DIM(2);
    
    result = zeros(N_slices, 1);
    
    for index=1:N_slices
        R = resels(index, :);
        result(index, 1) = spm_uc(alpha, df, stat, R, 1, S);
    end
end
