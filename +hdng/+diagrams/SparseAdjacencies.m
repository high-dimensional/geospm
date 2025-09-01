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

classdef SparseAdjacencies < hdng.diagrams.Adjacencies
    %SparseAdjacencies Summary.
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (Access=private)
        sparse_matrix
    end

    methods
        
        function obj = SparseAdjacencies(capacity)
            obj@hdng.diagrams.Adjacencies();

            obj.sparse_matrix = sparse(capacity, capacity);
        end
        
        function result = inward(obj, node, base)
            result = base.nodes(find(obj.sparse_matrix(:, node.node_number)));
        end

        function result = outward(obj, node, base)
            result = base.nodes(find(obj.sparse_matrix(node.node_number, :)));
        end
        
        function result = inward_indices(obj, node_number, base)
            result = find(obj.sparse_matrix(:, node_number));
        end

        function result = outward_indices(obj, node_number, base)
            result = find(obj.sparse_matrix(node_number, :));
        end

        function define(obj, from, to, base) %#ok<INUSD>
            obj.sparse_matrix(from.node_number, to.node_number) = 1;
        end

    end
end
