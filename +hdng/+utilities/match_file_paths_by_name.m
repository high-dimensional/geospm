% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2019,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function [file_paths, file_tokens] = match_file_paths_by_name(file_paths, name_pattern)

    N_file_paths = numel(file_paths);
    file_tokens = cell(N_file_paths, 1);
    N_results = 0;

    for i=1:N_file_paths

        file_path = file_paths{i};

        [~, file_name, file_ext] = fileparts(file_path);

        file_name = [file_name, file_ext]; %#ok<AGROW>

        [start, tokens] = regexp(file_name, name_pattern, 'start', 'tokens');

        if isempty(start)
            continue
        end

        N_results = N_results + 1;

        file_paths{N_results, 1} = file_path;
        file_tokens{N_results, 1} = tokens;
    end

    file_paths = file_paths(1:N_results);
    file_tokens = file_tokens(1:N_results);
end
