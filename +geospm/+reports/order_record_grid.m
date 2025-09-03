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

function studies = order_record_grid(studies, column_order)
    
    for study_index=1:numel(studies)
        
        study = studies(study_index);

        record_grid = study.record_grid;
        
        for index=1:numel(record_grid.groups)
    
            group = record_grid.groups{index};
            group.order_columns(column_order);
        end
        
        study.record_grid = record_grid;
        studies(study_index) = study;
    end
end

