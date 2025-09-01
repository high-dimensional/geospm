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

classdef EnumeratedOrder < hdng.diagrams.Order
    %EnumeratedOrder Summary.
    %   Detailed description
    
    
    properties (Dependent, Transient)
        ordered_values
        order_index_map
    end

    properties (Access=private)
        ordered_values_
        order_index_map_
    end
    
    methods
       
        function result = get.ordered_values(obj)
            result = obj.ordered_values_;
        end
        
        function set.ordered_values(obj, value)
            obj.ordered_values_ = value;
            obj.order_index_map_ = [];
        end
        
        function result = get.order_index_map(obj)

            if isnumeric(obj.order_index_map_) && isempty(obj.order_index_map_)
                obj.order_index_map_ = obj.access_order_index_map();
            end

            result = obj.order_index_map_;
        end

        function obj = EnumeratedOrder(varargin)
            obj = obj@hdng.diagrams.Order(varargin{:});
            
        end
        
        %{
        function [sorted_indices, missing_indices] = apply(obj, values)

            lookup = obj.order_index_map;

            sort_values_and_indices = zeros(numel(values), 2);
            sort_value_and_index_count = 0;

            missing_indices = zeros(numel(values), 1);
            missing_index_count = 0;

            for index=1:numel(values)
                value = values{index};
                
                if lookup.isKey(value)
                    sort_value_and_index_count = sort_value_and_index_count + 1;
                    sort_values_and_indices(sort_value_and_index_count, 1) = lookup(value);
                    sort_values_and_indices(sort_value_and_index_count, 2) = index;
                else
                    missing_index_count = missing_index_count + 1;
                    missing_indices(missing_index_count) = index;
                end
            end
            
            direction = 'ascend';
            
            if obj.reverse
                direction = 'descend';
            end
            
            [~, sorted_indices] = sort(sort_values_and_indices(:, 1), direction);
        end
        %}

        function [sorted_indices, missing_indices] = apply(obj, values)

            lookup = obj.order_index_map;

            sort_indices = zeros(numel(values), 2);
            sort_index_count = 0;

            missing_indices = zeros(numel(values), 1);
            missing_index_count = 0;

            for index=1:numel(values)
                value = values{index};
                
                if lookup.isKey(value)
                    sort_index_count = sort_index_count + 1;
                    sort_indices(sort_index_count, 1) = lookup(value);
                    sort_indices(sort_index_count, 2) = index;
                else
                    missing_index_count = missing_index_count + 1;
                    missing_indices(missing_index_count) = index;
                end
            end
            
            direction = 'ascend';
            
            if obj.reverse
                direction = 'descend';
            end
            
            [~, sorted_indices] = sort(sort_indices(:, 1), direction);
        end
    end

    methods (Access=protected)
        
        function result = access_order_index_map(obj)
            result = containers.Map();

            for index=1:numel(obj.ordered_values)
                value = obj.ordered_values{index};
                result(value) = index;
            end
        end

    end
end
