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

classdef ImplicitOrdinalScale < hdng.diagrams.OrdinalScale
    %ImplicitOrdinalScale Summary.
    %   Detailed description
    
    properties
        squash
    end
    
    properties (Dependent, Transient)
        ordered_values
        order_index_map
    end

    properties (Access=private)

        domain_is_numeric

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

        function obj = ImplicitOrdinalScale(varargin)
            obj = obj@hdng.diagrams.OrdinalScale(varargin{:});

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'ordered_values')
                options.ordered_values = {};
            end

            if ~isfield(options, 'squash')
                options.squash = false;
            end

            if ~isfield(options, 'domain_is_numeric')
                options.domain_is_numeric = false;
            end

            obj.squash = options.squash;
            obj.domain_is_numeric = options.domain_is_numeric;
            obj.ordered_values = options.ordered_values;
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

            if obj.squash
                result = num2cell((1:numel(result))');
            end
        end
    end

    methods (Access=protected)
        
        function result = access_order_index_map(obj)

            keyType = 'double';

            if ~obj.domain_is_numeric
                keyType = 'char';
            end

            result = containers.Map('KeyType', keyType, 'ValueType', 'double');

            for index=1:numel(obj.ordered_values)
                value = obj.ordered_values{index};
                result(value) = index;
            end
        end


    
        function result = access_defined_domain(obj)
            result = obj.ordered_values;
        end

        function result = access_calibrated_domain(obj)
            result = obj.defined_domain;
        end
    
        function update_defined_domain(obj, value)
            obj.domain_ = value;
        end

    end
end
