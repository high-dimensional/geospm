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

classdef ExplicitOrdinalScale < hdng.diagrams.OrdinalScale
    %ExplicitOrdinalScale Summary.
    %   Detailed description
    
    properties
    end

    properties (Dependent, Transient)
        ordered_values
        order_index_map
    end

    properties (Access=private)
        order_index_map_
    end
    
    methods
       
        function result = get.ordered_values(obj)
            result = obj.order_index_map_.keys();
        end
        
        function result = get.order_index_map(obj)
            result = obj.order_index_map_;
        end
        
        function set.order_index_map(obj, value)

            if iscell(value)
                tmp = containers.Map('KeyType', 'char', 'ValueType', 'any');

                for index=1:size(value, 1)
                    key = value{index, 1};
                    index_value = value{index, 2};

                    tmp(key) = index_value;
                end
                
                value = tmp;
            end

            obj.order_index_map_ = value;
        end

        function obj = ExplicitOrdinalScale(varargin)
            obj = obj@hdng.diagrams.OrdinalScale(varargin{:});
            
        end
        
        function [result, indices, clipped] = apply(obj, values)

            lookup = obj.order_index_map;

            indices = zeros(numel(values), 1);
            result = cell(numel(values), 1);
            result_count = 0;

            clipped = zeros(numel(values), 1);
            clipped_count = 0;

            for index=1:numel(values)
                value = values{index};
                
                if lookup.isKey(value)
                    result_count = result_count + 1;
                    result{result_count} = lookup(value);
                    indices(result_count) = index;
                else
                    clipped_count = clipped_count + 1;
                    clipped(clipped_count) = index;
                end
            end
        end
    end

    methods (Access=protected)
        
        function result = access_defined_domain(obj)
            result = obj.ordered_index_map.keys();
        end

        function result = access_calibrated_domain(obj)
            result = obj.defined_domain;
        end
    end
end
