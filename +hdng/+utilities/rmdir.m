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

function rmdir(directory_path, delete_contents, do_recycle)
   
     if ~exist(directory_path, 'dir')
         return;
     end

    if ~exist('do_recycle', 'var')
        do_recycle = true;
    end
    
    arguments = {};
    
    if delete_contents
        arguments = [arguments; {'s'}];
    end
    
    if do_recycle
        
        try
            svd_recycle_state = recycle('on');
            rmdir(directory_path, arguments{:});
            recycle(svd_recycle_state);
        catch

            tmp_directory = fullfile(userpath, 'tmp_directory');
            [dirstatus, dirmsg] = mkdir(tmp_directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            tmp_directory = hdng.utilities.make_timestamped_directory(tmp_directory);
            
            movefile(directory_path, tmp_directory);
        end
        
    else
        rmdir(directory_path, arguments{:});
    end
end
