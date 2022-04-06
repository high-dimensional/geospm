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

function [result, thresholds, fwhms, resels] = select_slice_by_critical_height_threshold(SPM, alpha, stat)
    
    [fwhms, resels] = geospm.validation.utilities.compute_per_slice_smoothness(SPM);
    
    thresholds = geospm.validation.utilities.compute_per_slice_critical_height_thresholds(SPM, alpha, stat, resels);
    
    [~, result] = min(thresholds);
end
