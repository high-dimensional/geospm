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

classdef NodeBase < handle
    %NodeBase Summary.
    %   Detailed description 
    
    properties
    end

    properties (SetAccess=private)
        next_node_number
        nodes
    end
    
    properties (Dependent, Transient)
        node_count
    end
    
    methods

        function result = get.node_count(obj)
            result = numel(obj.nodes);
        end
        
        function obj = NodeBase()
            obj.nodes = {};
            obj.next_node_number = 1;
        end
        
        function permutation = sort_nodes(obj, adjacencies)
            
            permutation = ...
                hdng.utilities.sort_topologically(obj.nodes, ...
                @(~, index) adjacencies.outward_indices(index));
        end

        function add_node(obj, node)
            node.bind(obj.next_node_number);

            obj.next_node_number = obj.next_node_number + 1;
            obj.nodes{end + 1} = node;
        end
    end
end
