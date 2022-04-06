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

function result = iterate_spm_directories(directory_path)
    [~, subdirectories] = hdng.utilities.list_files(directory_path);
    
    result = cell(numel(subdirectories), 1);
    result_length = 0;
    
    for index=1:numel(subdirectories)
        path = subdirectories{index};
        
        [~, name, ext] = fileparts(path);
        
        name = [name ext]; %#ok<AGROW>
        value = str2double(name);
        
        if isnan(value)
            continue
        end
    
        path = [path filesep 'spm_output']; %#ok<AGROW>
        
        if ~exist(path, 'dir')
            continue
        end
        
        result_length = result_length + 1;
        result{result_length} = path;
    end
    
    result = result(1:result_length);
end
