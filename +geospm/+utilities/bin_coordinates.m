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

function update_state = bin_coordinates(update, X, update_state)
    
    D = size(X, 2);

    start_state = struct();
    start_state.dimension = 1;
    start_state.indices = (1:size(X, 1))';
    
    stack = {start_state};
    coordinates = zeros(D, 1);
    
    while ~isempty(stack)
        state = stack{end};
        
        if state.dimension > D
            update_state = update(update_state, coordinates, state.indices);
            
            % pop
            stack = stack(1:end - 1);
            continue
        end
        
        if ~isfield(state, 'bins')
            values = X(state.indices, state.dimension);
            state.bins = bin_values(values, state.indices);
            state.bin_values = state.bins.keys();
            state.bin_index = 1;
        elseif state.bin_index > length(state.bins)
            % pop
            stack = stack(1:end - 1);
            continue
        end
        
        coordinate = state.bin_values{state.bin_index};
        coordinates(numel(stack)) = coordinate;
        
        new_state = struct();
        new_state.dimension = state.dimension + 1;
        new_state.indices = state.bins(coordinate);
        
        state.bin_index = state.bin_index + 1;
        
        stack{end} = state;
        stack{end + 1} = new_state; %#ok<AGROW>
    end
end


function bins = bin_values(x, indices)
    
    N = numel(x);
    
    bins = containers.Map('KeyType', 'double', 'ValueType', 'any');
    
    for i=1:N
        
        xi = x(i);
        index = indices(i);
        
        if ~isKey(bins, xi)
            bins(xi) = [];
        end
        
        bins(xi) = [bins(xi); index];
    end
end
