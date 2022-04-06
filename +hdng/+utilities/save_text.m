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

function save_text(text, file_path)

    [directory, ~, ~] = fileparts(file_path);

    [status,msg] = mkdir(directory);
    
    if status ~= 1
        error('save_text(): %s', msg);
    end
    
    h = fopen(file_path, "w", "n", "UTF-8");
    fwrite(h, text, 'char');
	fclose(h);
end
