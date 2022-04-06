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

function result = isnumerictypename(name, include_logical)

    if ~exist('include_logical', 'var')
        include_logical = true;
    end
    
    persistent numericTypeSet;
    
    if isempty(numericTypeSet)
        numericTypeNames = {
            'double', 'single', ...
            'int8', 'int16', 'int32', 'int64', ...
            'uint8', 'uint16', 'uint32', 'uint64' ...
            };
        
        numericTypeSet = containers.Map('KeyType', 'char', 'ValueType', 'logical');
        
        for i=1:numel(numericTypeNames)
            name = numericTypeNames{i};
            numericTypeSet(name) = 1;
        end
    end
    
    name_arg = lower(name);
    result = isKey(numericTypeSet, name_arg);
    
    if include_logical
        result = result | strcmp(name_arg, 'logical');
    end
end
