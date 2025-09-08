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

function [studies, group_widths, group_heights] = ...
    build_polygon_datasets(studies, preprocessing_identifier, ...
        input_attachment, output_attachment, shared_variables, ...
        cell_mask_volume_fn, slice_name)
    
    group_widths = [];
    group_heights = [];
    
    if ~isfield(studies(1), 'record_grid')
            studies(1).record_grid = [];
    end
    
    if ~isfield(studies(1), 'context')
            studies(1).context = [];
    end

    % Each study group is a cell grid of values selected by specific 
    % combination of group, row and column selector values.
    
    for study_index=1:numel(studies)
        
        study = studies(study_index);
        study_directory = study.directory;
        study_file = fullfile(study_directory, [study.identifier preprocessing_identifier '_preprocessed.mat']);
        
        if isempty(study.record_grid)
            record_grid = geospm.reports.RecordGrid.load(study_file);
        else
            record_grid = study.record_grid;
        end
        
        if isempty(study.context)
            study.context = geospm.reports.ReportContext(study_directory, shared_variables);
        end

        for index=1:numel(record_grid.groups)
    
            group = record_grid.groups{index};
            
            group.cell_attachments.(output_attachment) = ...
              study.context.create_cell_datasets( ...
                group, input_attachment, ...
                cell_mask_volume_fn, slice_name, ...
                shared_variables.easting_column, ...
                shared_variables.northing_column);
            
            group.collapse_across_columns();
            
            group_widths(end + 1) = size(group.cell_attachments.(output_attachment), 2); %#ok<AGROW>
            group_heights(end + 1) = size(group.cell_attachments.(output_attachment), 1); %#ok<AGROW>
        end

        study.record_grid = record_grid;
        studies(study_index) = study;
    end
end

