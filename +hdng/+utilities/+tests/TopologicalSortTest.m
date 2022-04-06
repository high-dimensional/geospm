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

classdef TopologicalSortTest < matlab.unittest.TestCase
 
    properties
        N
        graphs
    end
 
    methods(TestMethodSetup)
        
        function create_graphs(obj)
            
            obj.N = 10000;
            obj.graphs = cell(obj.N, 1);
            
            K = randi(100, [obj.N 1]);
            D = randi(3, [obj.N 1]);
            
            for i=1:obj.N
                obj.graphs{i} = hdng.utilities.randacyclicgraph(K(i), D(i))'; 
            end
        end
    end
 
    methods(TestMethodTeardown)
    end
 
    methods
        
        function verify_sort_order(obj, elements, G)
            
            K = numel(elements);
            predecessors = zeros(1, K, 'logical');
            
            for i=1:K
                index = elements{i};
                matched_predecessors = predecessors & G(index, :);
                is_valid = sum(xor(matched_predecessors, G(index, :))) == 0;
                
                if ~is_valid
                    obj.verifyFailed(sprintf('Element %d is not in order.', index));
                end
                
                predecessors(index) = 1;
            end
            
        end
        
    end
    
    methods(Test)
        
        function sort(obj)
            
            for i=1:obj.N
                G = obj.graphs{i};
                k = size(G, 1);

                elements = num2cell(1:k);
                [permutation, requirements] = ...
                    hdng.utilities.sort_topologically(elements, @(index, ~) find(G(index, :)));

                sorted_elements = elements(permutation);
                obj.verify_sort_order(sorted_elements, G);

                for j=1:k
                    required = zeros(1, k);
                    required(requirements{j}) = 1;
                    obj.verifyTrue(isequal(G(j, :), required), sprintf('Incorrect requirements returned by sort_topologically() for node %d in graph %d', j, i));
                end
            end
        end
        
        
    end
end
