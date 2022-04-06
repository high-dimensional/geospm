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

function directory = make_timestamped_directory(parent_directory)
    
    timestamp = datetime('now', 'TimeZone', 'local', 'Format', 'yyyy_MM_dd_HH_mm_ss');

    if ~exist('parent_directory', 'var') || numel(parent_directory) == 0
        parent_directory = pwd;
    end
    
    directory = fullfile(parent_directory, char(timestamp));
    [dirstatus, dirmsg] = mkdir(directory);
    if dirstatus ~= 1; error(dirmsg); end
    
end
