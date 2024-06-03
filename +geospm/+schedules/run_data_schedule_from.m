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

function run_data_schedule_from(command_file)
    args = load(command_file);
    
    optional_args = hdng.utilities.struct_to_name_value_sequence(args.options);

    geospm.schedules.run_data_schedule(...
        args.study_random_seed, ...
        args.study_directory, ...
        args.data_specifiers, ...
        args.run_mode, ...
        optional_args{:});
end
