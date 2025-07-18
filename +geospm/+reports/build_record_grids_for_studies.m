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

function build_record_grids_for_studies(studies, suffix, ...
    row_field, column_field, grid_options, varargin)
    
    options = hdng.utilities.parse_struct_from_varargin(varargin{:});

    if ~isfield(options, 'output_dir')
        options.output_dir = hdng.utilities.make_timestamped_directory(base_directory);
    end

    if ~isfield(options, 'do_debug')
        options.do_debug = false;
    end

    if ~isfield(options, 'force_preprocessing')
        options.force_preprocessing = false;
    end
    
    cmds = cell(size(studies));
    cmd_index = 0;

    for index=1:numel(studies)
        
        study = studies(index);

        filename = fullfile(study.directory, [study.identifier suffix '_preprocessed.mat']);

        if ~exist(filename, 'file') || options.force_preprocessing

            cmd_index = cmd_index + 1;

            cmds{cmd_index} = geospm.schedules.create_cmd(...
                @geospm.reports.build_record_grid, ...
                study.identifier, study.directory, ...
                {study.directory, [study.identifier suffix], ...
                row_field, column_field, grid_options}, ...
                struct());

        end
    end
    
    cmds = cmds(1:cmd_index);
    
    if ~isempty(cmds)

        arguments = {...
            'do_debug', options.do_debug ...
        };

        geospm.schedules.run_parallel_cmds(options.output_dir, cmds, arguments{:});
    end
    
end

