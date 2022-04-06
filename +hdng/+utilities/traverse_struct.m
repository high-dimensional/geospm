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

function result = traverse_struct(S, visit, visitor_state)
%traverse_struct Summary of this function goes here
%   function results = visit(visitor_state, path, value, n_visit, results)
%   
    
    root = struct('index', 1, 'scope', S);
    root.names = fieldnames(S);
    
    stack = {root};
    results = {cell(0,1); cell(0, 1)};
    path = {''};
    
    results = visit(visitor_state, path, S, 1, results);
    
    while numel(stack) > 0
        
        state = stack{end};
        do_pop_state = true;
        
        while state.index <= numel(state.names)
            name = state.names{state.index};
            value = state.scope.(name);
            
            path{end + 1, 1} = name; %#ok<AGROW>
            results{end + 1, 1} = cell(0, 1); %#ok<AGROW>
            
            results = visit(visitor_state, path, value, 1, results);
            
            state.index = state.index + 1;
            stack{end} = state;
            
            if isstruct(value)
                state = struct('index', 1, 'scope', value);
                state.names = fieldnames(value);
                stack{end + 1} = state; %#ok<AGROW>
                do_pop_state = false;
                break;
            else
                
                results = visit(visitor_state, path, value, 2, results);
                
                path = path(1:end - 1);
                results = results(1: end - 1);
            end
        end
        
        if do_pop_state
            results = visit(visitor_state, path, state.scope, 2, results);

            path = path(1:end - 1);
            results = results(1: end - 1);
            
            stack = stack(1:end - 1);
        end
    end
    
    results = results{1};
    result = results{1};
    
end
