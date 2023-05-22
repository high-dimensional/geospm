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

function [ordered_contrasts, groups] = order_domain_contrasts(unordered_contrasts, statistic_order)

    contrast_map = containers.Map('KeyType', 'char', 'ValueType', 'any');

    for index=1:numel(unordered_contrasts)
        contrast = unordered_contrasts{index};

        if ~isKey(contrast_map, contrast.statistic)
            contrast_map(contrast.statistic) = {};
        end

        contrast_map(contrast.statistic) = [contrast_map(contrast.statistic); {contrast}];
    end

    statistic_order_map = containers.Map('KeyType', 'char', 'ValueType', 'int64');

    for index=1:numel(statistic_order)
        statistic = statistic_order{index};
        statistic_order_map(statistic) = index;
    end

    statistics = contrast_map.keys();

    %groups has the fields: statistic, contrasts, order

    groups = cell(numel(statistics), 3);

    for index=1:numel(statistics)
        statistic = statistics{index};

        if ~isKey(statistic_order_map, statistic)
            order = 0;
        else
            order = statistic_order_map(statistic);
        end

        contrast_batch = contrast_map(statistic);
        N_contrasts = numel(contrast_batch);

        sorted_contrast_batch = cell(numel(contrast_batch), 3);

        for c=1:N_contrasts
            contrast = contrast_batch{c};
            sorted_contrast_batch{c, 1} = contrast;
            sorted_contrast_batch{c, 2} = contrast.attachments.term_index;
            sorted_contrast_batch{c, 3} = min(contrast.attachments.threshold_indices);
            sorted_contrast_batch{c, 4} = 1 * contrast.attachments.is_auxiliary;
        end

        sorted_contrast_batch = sortrows(sorted_contrast_batch, [4, 3, 2]);
        
        groups{index, 1} = statistic;
        groups{index, 2} = sorted_contrast_batch(:, 1);
        groups{index, 3} = order;
    end

    groups = sortrows(groups, 3);
    groups = groups(:, 1:2);

    N_ordered_contrasts = numel(unordered_contrasts);
    
    ordered_contrasts = cell(N_ordered_contrasts, 1);
    contrast_index = 0;

    for index=1:size(groups, 1)
        contrast_batch = groups{index, 2};
        
        for c=1:numel(contrast_batch)
            contrast = contrast_batch{c};
            contrast_index = contrast_index + 1;
            contrast.order = contrast_index;
            ordered_contrasts{contrast_index} = contrast;
        end
    end
end
