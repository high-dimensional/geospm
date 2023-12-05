% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2021,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function [cell_sizes, row_sizes, column_sizes, grid_size] = compute_cell_sizes(grid_cell_contexts)
    
    cell_sizes = zeros([size(grid_cell_contexts), 2]);

    for index=1:numel(grid_cell_contexts)
        context = grid_cell_contexts{index};

        if isempty(context)
            continue;
        end

        [y, x] = ind2sub(size(grid_cell_contexts), index);

        cell_sizes(y, x, :) = context.stack.size;
    end
    
    row_sizes = max(cell_sizes(:, :, 2), [], 2);
    column_sizes = max(cell_sizes(:, :, 1), [], 1);
    grid_size = [sum(column_sizes), sum(row_sizes)];
end
