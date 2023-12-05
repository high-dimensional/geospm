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

classdef PresentationStack < handle
    %PresentationStack Summary.
    %   Detailed description 
    
    properties
    end

    properties (Dependent, Transient)
        layers
        layer_views

        magnification

        content_size
        size

        selected_layer_categories
        selected_layers
        selected_layer_views
    end

    properties (GetAccess=private, SetAccess=private)
        layers_

        magnification_

        content_size_
        size_

        selected_layer_categories_
        selected_layers_
    end

    methods
        
        function obj = PresentationStack(layers, selected_layer_categories, magnification)
            geospm.validation.PresentationStack.build(obj, layers, selected_layer_categories, magnification); 
        end
        
        function result = get.layers(obj)
            result = obj.layers_;
        end
        
        function result = get.selected_layers(obj)
            result = obj.selected_layers_;
        end

        function result = get.content_size(obj)
            result = obj.content_size_;
        end

        function result = get.size(obj)
            result = obj.size_;
        end

        function result = get.selected_layer_categories(obj)
            result = obj.selected_layer_categories_;
        end

        function set.selected_layer_categories(obj, value)
            geospm.validation.PresentationStack.build(obj, obj.layers, value, obj.magnification);
        end

        function result = get.magnification(obj)
            result = obj.magnification_;
        end

        function set.magnification(obj, value)
            geospm.validation.PresentationStack.build(obj, obj.layers, obj.selected_layer_categories, value);
        end
    end
    
    methods (Static)
        
        
        function build(obj, layers, selected_layer_categories, magnification)

            obj.layers_ = layers;

            obj.selected_layer_categories_ = selected_layer_categories;
            obj.selected_layers_ = geospm.validation.PresentationStack.compute_layer_selection(obj.layers_, obj.selected_layer_categories_);
            
            obj.magnification_ = magnification;
            obj.content_size_ = geospm.validation.PresentationStack.compute_content_size(obj.selected_layers_);
            obj.size_ = geospm.validation.PresentationStack.compute_size(obj.content_size_, obj.magnification_);
        end
        
        function selected_layers = compute_layer_selection(layers, selected_layer_categories)
        
            category_map = struct();
            
            function assign_category(category)
                category_map.(category) = true;
            end

            cellfun(@(category) assign_category(category), selected_layer_categories);
            
            selected_layers = {};

            for index=1:numel(layers)
                layer = layers{index};

                if ~isfield(category_map, layer.category)
                    continue
                end

                selected_layers{end + 1} = layer; %#ok<AGROW>
            end
            
            orders = {
                selected_layer_categories
            };

            selected_layers = geospm.validation.PresentationStack.sort_elements(selected_layers, orders, @(layer) {layer.category, layer.priority});
        end

        function result = sort_elements(elements, orders, get_key_values)
            
            for index=1:numel(orders)

                order_values = orders{index};
                order_map = struct();

                for k=1:numel(order_values)
                    order_map.(order_values{k}) = k;
                end

                orders{index} = order_map;
            end

            key_values = {};

            for index=1:numel(elements)
                element = elements{index};
                key_values = [key_values; get_key_values(element)]; %#ok<AGROW>
            end

            for index=1:numel(orders)

                order_map = orders{index};

                order_values = key_values(:, index);

                for k=1:numel(order_values)
                    order_value = order_values{k};

                    if isfield(order_map, order_value)
                        order_value = order_map.(order_value);
                    end

                    order_values{k} = order_value;
                end

                key_values(:, index) = order_values; %#ok<AGROW>
            end

            [~, sort_order] = sortrows(key_values, 1:size(key_values, 2));

            result = elements(sort_order);
        end
        
        function [x, y] = compute_size_from_layers(layers)

            function result = add_dimensions(a, b)
                if isempty(a)
                    result = b;
                    return
                end

                if isempty(b)
                    result = a;
                    return
                end

                result = a + b;
            end

            function result = clip_dimension(a, min, max)
                if isempty(a)
                    result = [];
                    return
                end

                if ~isempty(min) && a < min
                    result = min;
                    return
                end

                if ~isempty(max) && a > max
                    result = max;
                    return
                end

                result = a;
            end

            function result = greater_dimension(a, b)

                if isempty(a)
                    result = b;
                    return
                end

                if isempty(b)
                    result = a;
                    return
                end

                if a >= b
                    result = a;
                else
                    result = b;
                end
            end
            
            function [x, y] = add_layer_size(x, y, layer)
                
                layer_x = [];
                
                if isprop(layer, 'x')
                    layer_x = layer.x;
                end
                
                layer_width = [];
                
                if isprop(layer, 'width')
                    layer_width = layer.width;
                end
                
                layer_y = [];
                
                if isprop(layer, 'y')
                    layer_y = layer.y;
                end
                
                layer_height = [];
                
                if isprop(layer, 'height')
                    layer_height = layer.height;
                end

                x = greater_dimension(x, clip_dimension(add_dimensions(layer_x, layer_width), 0, []));
                y = greater_dimension(y, clip_dimension(add_dimensions(layer_y, layer_height), 0, []));
            end
            
            x = [];
            y = [];

            for index=1:numel(layers)
                layer = layers{index};
                [x, y] = add_layer_size(x, y, layer);
            end
        end

        function result = compute_content_size(layers)

            [x, y] = geospm.validation.PresentationStack.compute_size_from_layers(layers);

            if isempty(x)
                x = 100;
            end

            if isempty(y)
                y = 100;
            end

            result = [x, y];
        end
        
        function result = compute_size(content_size, magnification)
            result = [floor(content_size(1) * magnification), ...
                      floor(content_size(2) * magnification)];
        end
    end
end
