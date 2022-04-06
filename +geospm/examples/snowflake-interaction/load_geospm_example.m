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

function [spatial_data, options] = load_geospm_example
    
    spatial_data = geospm.load_data('spatial_data.csv', 'row_identifier_index', []);
    
    options = struct();
    options.smoothing_levels = 40.0;
    options.apply_density_mask = false;
    options.min_location = floor(spatial_data.min_xyz);
    options.max_location = ceil(spatial_data.max_xyz);
    options.spatial_resolution_max = 220;
    options.thresholds = { 'T[1, 2]: p<0.05 (FWE)' };
    options.add_georeference_to_images = false;
    options.trace_thresholds = false;
end
