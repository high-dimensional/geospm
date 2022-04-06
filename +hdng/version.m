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

function varargout = version()
    
    source_version = hdng.utilities.SourceVersion(...
        fileparts(mfilename('fullpath')));
    
    if nargout == 0
        
        fprintf([newline 'HDNG ' source_version.release ' [build ' source_version.build_number ...
                 ', ' source_version.date ']' newline newline ...
                 'https://github.com/high-dimensional/hdng' ...
                 newline ...
                 'https://github.com/high-dimensional/hdng/commit/' ...
                 source_version.hash...
                 newline ...
                 newline]);
    else
        varargout = {source_version};
    end
end
