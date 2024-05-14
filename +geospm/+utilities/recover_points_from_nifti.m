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

function [locations, count, indices, volume_data] = recover_points_from_nifti(file_path)
    
    data = geospm.utilities.read_nifti(file_path);

    mask = data ~= 0;
    indices = find(mask);
    [row, column, slice] = ind2sub(size(mask), indices);
    locations = [column, row, slice];
    
    count = data(indices);
    volume_data = data;
end

