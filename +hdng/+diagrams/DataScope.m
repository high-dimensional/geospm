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

classdef DataScope < handle
    %DataScope Summary.
    %   Detailed description 
    
    properties
        data_level
        attributes
        records
        children
        children_by_data_level
        
        uuid
        node_number
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = DataScope(data_level, attributes, records)
            obj.data_level = data_level;
            obj.attributes = attributes;
            obj.records = records;
            obj.children = {};
            obj.children_by_data_level = struct();

            obj.uuid = replace(char(java.util.UUID.randomUUID), '-', '');
            obj.node_number = 0;
        end
        
        function add_child(obj, child)
            
            obj.children{end + 1} = child;

            list = hdng.utilities.struct_get_value_at_path(...
                obj.children_by_data_level, ...
                child.data_level.identifier, {});
            
            list{end + 1} = child;
            
            obj.children_by_data_level.(child.data_level.identifier) = list;
        end
        
        function add_children(obj, varargin)
            
            for index=1:numel(varargin)
                child = varargin{index};
                obj.add_child(child);
            end
        end
        
        function bind(obj, node_number)
            obj.node_number = node_number;
        end

        function compute_assignments(obj, base, parents, siblings)
            assignments = obj.data_level.assignments;

            for index=1:numel(assignments)
                assignment = assignments{index};
                assignment.perform(obj, base, parents, siblings);
            end
        end
    end
end
