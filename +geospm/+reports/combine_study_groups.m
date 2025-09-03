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

function [combination, column_values, study_spans] = combine_study_groups(studies, group_heights, group_widths, attachments)

    combination_size = [sum(group_heights), max(group_widths)];

    column_values = cell(combination_size);

    combination = struct();

    for k=1:numel(attachments)
        attachment = attachments{k};
        combination.(attachment) = cell(combination_size);
    end
    
    study_spans = zeros(numel(studies), 1);

    group_index = 1;
    pos = 1;

    for study_index=1:numel(studies)
        
        study = studies(study_index);
        groups = study.record_grid.groups;
        
        for index=1:numel(groups)
            group = groups{index};

            column_values(pos:pos + group_heights(group_index) - 1, 1:group_widths(group_index)) = group.column_value_per_cell;

            for k=1:numel(attachments)
                attachment = attachments{k};

                combination.(attachment)(pos:pos + group_heights(group_index) - 1, 1:group_widths(group_index)) = ...
                    group.cell_attachments.(attachment);
            end

            study_spans(study_index) = study_spans(study_index) + group_heights(group_index);

            pos = pos + group_heights(group_index);
            group_index = group_index + 1;
        end
    end
end
