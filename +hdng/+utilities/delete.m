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

function delete(do_recycle, varargin)
    
    if do_recycle
        
        try
            svd_recycle_state = recycle('on');
            delete(varargin{:});
            recycle(svd_recycle_state);
        catch
            
            tmp_directory = fullfile(userpath, 'tmp_directory');
            [dirstatus, dirmsg] = mkdir(tmp_directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            tmp_directory = hdng.utilities.make_timestamped_directory(tmp_directory);
            
            for index=1:numel(varargin)
                movefile(varargin{index}, tmp_directory);
            end
        end
        
    else
        svd_recycle_state = recycle('off');
        delete(varargin{:});
        recycle(svd_recycle_state);
    end
end
