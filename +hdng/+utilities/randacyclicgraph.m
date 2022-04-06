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

function graph = randacyclicgraph(N_nodes, max_degree, varargin)

    hdng.utilities.parse_struct_from_varargin(varargin{:});

    graph = zeros(N_nodes, 'logical');
    degrees = min([randi(max_degree + 1, [1 N_nodes]) - 1; (1:N_nodes) - 1]);
    
    for i=1:N_nodes
        
        N_degrees = degrees(i);
        
        if N_degrees == 0
            continue
        end
        
        edges = randperm(i - 1, N_degrees);
        graph(i, edges) = 1;
    end
    
    graph = graph'; %Take the transpose so that it becomes a regular forward graph
    
    permutation = randperm(N_nodes);
    
    graph = graph(permutation, :);
    graph = graph(:, permutation);
end
