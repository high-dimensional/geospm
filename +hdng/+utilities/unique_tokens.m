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

function [result, indices] = unique_tokens(tokens)
    
    N = 0;
    K = max(ceil(numel(tokens) / 10), 100);
    result = cell(K, 1);
    indices = zeros(K, 1);

    map = containers.Map('KeyType', 'char', 'ValueType', 'logical');

    for index=1:numel(tokens)
        token = tokens{index};
        
        if ~isKey(map, token)
            map(token) = index;
            
            N = N + 1;
            result{N} = token;
            indices(N) = index;
        end
    end
    
    result = result(1:N);
    indices = indicies(1:N);
end