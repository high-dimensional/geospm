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

function [unique_values, value_indices] = compute_unique_values(values)
    % Computes an array of unique values and their locations in the given
    % array.

    value_indices = {};
    unique_values = [];

    for index=1:numel(values)

        value = values(index);
        
        [is_at, insert_at] = hdng.utilities.binary_search(unique_values, value);

        if is_at == 0
            unique_values = [unique_values(1:insert_at - 1) value unique_values(insert_at:end)];
            matches = find(value == values);
            value_indices = [value_indices(1:insert_at - 1) {matches} value_indices(insert_at:end)];
        end
    end

end