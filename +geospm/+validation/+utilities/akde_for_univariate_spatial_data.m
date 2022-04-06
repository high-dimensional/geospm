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

function result = akde_for_univariate_spatial_data(point1, point2, spatial_resolution, spatial_data, null_level, predictor_index, debug_directory)

    if ~exist('predictor_index', 'var')
        predictor_index = 1;
    end

    if ~exist('debug_directory', 'var')
        debug_directory = [];
    end

    grid = geospm.Grid();
    %grid.span_frame([1, 1, 1], [spatial_resolution 1], max(spatial_resolution));
    grid.span_frame(point1, point2, spatial_resolution);

    grid_data = grid.grid_data(spatial_data);
    
    row_selection = grid_data.observations(:, predictor_index) > null_level;
    col_selection = zeros(1, spatial_data.P, 'logical');
    col_selection(predictor_index) = true;
    
    grid_data = grid_data.select(row_selection, col_selection);

    [x, y] = meshgrid(1:grid_data.resolution(1), ...
                      1:grid_data.resolution(2));
    
    grid = reshape([x(:), y(:)], numel(x), 2);
    
    data = cast([grid_data.u, grid_data.v], 'double');
    data = data + rand(size(data)) * 0.1;
    
    if ~isempty(debug_directory)
        min_point = [1, 1];
        max_point = grid_data.resolution(1:2);

        grid_file = fullfile(debug_directory, sprintf('predictor_%d.eps', predictor_index));
        grid_data.write_as_eps(grid_file, min_point, max_point);
        
        grid_file = fullfile(debug_directory, sprintf('predictor_%d.png', predictor_index));
        grid_data.write_as_png(grid_file, min_point, max_point);
        
        
        grid_file = fullfile(debug_directory, sprintf('predictor_%d.csv', predictor_index));
        grid_data.write_as_csv(grid_file);
    end
    
    gamma = ceil(sqrt(grid_data.N) * 2.0);
    
    result = struct();
    result.start_time = now();
    [estimated_pdf, bandwidth] = akde(data, grid, gamma);
    result.stop_time = now();
    
    estimated_pdf = reshape(estimated_pdf, flip(spatial_resolution));
    estimated_pdf = flipud(rot90(estimated_pdf, 1));

    result.estimated_pdf = estimated_pdf;
    result.estimated_var = 0;
    result.bandwidth = bandwidth;
end

function result = now()
    result = datetime('now', 'TimeZone', 'local', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
end
