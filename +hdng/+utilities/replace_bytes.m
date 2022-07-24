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

function result = replace_bytes(data, old_bytes, new_bytes)
    
    offset = 1;

    locations = strfind(data, old_bytes);
    result = [];
    
    for index=1:numel(locations)
        l = locations(index);
        
        result = [result, data(offset:l - 1), new_bytes]; %#ok<AGROW>
        
        offset = l + numel(old_bytes);
    end
    
    result = [result, data(offset:end)];
end
