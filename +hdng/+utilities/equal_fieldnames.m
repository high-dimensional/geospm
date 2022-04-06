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

function result = equal_fieldnames(L, R)
%equal_fieldnames Checks whether L and R have identical field names.
%   
    L_names = fieldnames(L);
    R_names = fieldnames(R);
    
    result = numel(L_names) == numel(R_names);
    
    if ~result
        return;
    end
    
    L_names = sort(L_names);
    R_names = sort(R_names);
    
    for i=1:numel(L_names)
        
        result = strcmp(L_names{i}, R_names{i});
        
        if ~result
            return;
        end
    end
end
