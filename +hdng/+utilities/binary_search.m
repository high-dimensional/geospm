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

function [index_or_zero, insert_at] = binary_search(cells_or_numeric, value)

    index_or_zero = 0;   
    insert_at = 0;
    
    N = cast(numel(cells_or_numeric), 'int64');
    two = cast(2, 'int64');

    start = cast(1, 'int64');
    limit = cast(N + 1, 'int64');
    
    
    if ~ischar(value)
        canonicalise = @(x) x;
    else
        canonicalise = @(x) string(x);
    end
    
    function result = direct_access(x, index)
        result = x(index);
    end
    
    function result = indirect_access(x, index)
        result = x{index};
    end
    
    if iscell(cells_or_numeric)
        access = @indirect_access;
    else
        access = @direct_access;
    end
    
    value = canonicalise(value);
    
    while start < limit

        pivot = start + idivide(limit - start, two, 'floor');

        if value <= canonicalise(access(cells_or_numeric, pivot))
            limit = pivot;
        else
            start = pivot + 1;
        end
    end

    start = cast(start, 'double');
    
    if start <= N && value == canonicalise(access(cells_or_numeric, start))
        index_or_zero = start;
    else
        insert_at = start;
    end
end
