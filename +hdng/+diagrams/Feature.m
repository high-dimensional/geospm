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

classdef Feature < handle
    %Feature Summary.  
    %   Detailed description 
    
    properties
        identifier
        feature_declarator

        data_scope

        children_by_identifier
        children

        values_by_identifier

        scales_by_identifier
        scales

        scaled_values
        constants
    end

    properties (SetAccess=private)
        node_number
    end

    properties (Dependent, Transient)
    end
    
    methods
        
        %{
        function result = get.descendants(obj)
            
            result = {obj};
            index = 1;

            while index <= numel(result)
                feature = result{index};
                index = index + 1;
                
                result = [result; feature.children(:)]; %#ok<AGROW>
            end

        end
        %}
        
        function obj = Feature(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'identifier')
                options.identifier = '';
            end

            if ~isfield(options, 'feature_declarator')
                options.feature_declarator = [];
            end
            
            if ~isfield(options, 'data_scope')
                options.data_scope = [];
            end

            if ~isfield(options, 'children')
                options.children = {};
            end

            if ~isfield(options, 'values_by_identifier')
                options.values_by_identifier = {};
            end

            if ~isfield(options, 'scales')
                options.scales = {};
            end

            obj.identifier = options.identifier;
            obj.feature_declarator = options.feature_declarator;
            obj.data_scope = options.data_scope;

            obj.children_by_identifier = struct();
            obj.children = {};

            obj.node_number = 0;

            obj.values_by_identifier = options.values_by_identifier;

            obj.scales_by_identifier = struct();
            obj.scales = {};

            obj.scaled_values = struct();
            obj.constants = struct();
            
            obj.add_children(options.children{:});
            obj.add_scales(options.scales{:});
        end

        function add_child(obj, child)
            
            obj.children{end + 1} = child;

            if ~isempty(child.identifier)

                list = hdng.utilities.struct_get_value_at_path(obj.children_by_identifier, child.identifier, {});
                list{end + 1} = child;
                
                obj.children_by_identifier.(child.identifier) = list;
            end
        end
        
        function add_children(obj, varargin)
            
            for index=1:numel(varargin)
                child = varargin{index};
                obj.add_child(child);
            end
        end

        function add_scale(obj, scale)
            
            obj.scales{end + 1} = scale;

            if ~isempty(scale.identifier)
                obj.scales_by_identifier.(scale.identifier) = scale;
            end
        end
        
        function add_scales(obj, varargin)
            
            for index=1:numel(varargin)
                scale = varargin{index};
                obj.add_scale(scale);
            end
        end
        
        function bind(obj, node_number)
            obj.node_number = node_number;
        end
        
        function define_dependencies(obj, base, parents, siblings, processing)
            
            if isempty(obj.feature_declarator)
                return;
            end

            expression = obj.feature_declarator.expression;
            
            if isempty(expression)
                return;
            end
            
            dependencies = expression.dependencies_by_identifier;
            
            names = fieldnames(dependencies);

            for n_index=1:numel(names)
                name = names{n_index};

                if strcmp(name, 'grandparent')
                    continue;
                end

                feature = obj.resolve_dependency(name, base, parents, siblings);

                if feature ~= obj
                    processing.define(obj, feature, base);
                end

                dependency_names = dependencies.(name);
                
                feature.check_expression_names(dependency_names, true);
            end
        end

        function update_scaled_values(obj, scale_identifier, values_by_attribute, constants)
            obj.scaled_values.(scale_identifier) = values_by_attribute;
            obj.constants.(scale_identifier) = constants;
        end

        function update_expressions(obj, base, parents, siblings)
            
            if isempty(obj.feature_declarator) || isempty(obj.feature_declarator.expression)
                return;
            end

            context = struct();
            context.self = obj;
            context.previous = obj.resolve_dependency('previous', base, parents, siblings, false);
            context.next = obj.resolve_dependency('next', base, parents, siblings, false);
            context.parent = obj.resolve_dependency('parent', base, parents, siblings, false);
            context.grandparent = obj.resolve_dependency('grandparent', base, parents, siblings, false);

            expression = obj.feature_declarator.expression;
            expression.compute(context, obj.scaled_values, obj.constants);
        end

        function result = is_last_visit(obj, n_visit)
            result = n_visit == numel(obj.children) + 1;
        end

        function next_child = render(obj, n_visit, render_context, base, parents, siblings)
            
            if n_visit <= numel(obj.children)
                next_child = obj.children{n_visit};
            else
                next_child = [];
            end
            
            if isempty(obj.feature_declarator)
                return;
            end

            context = struct();
            context.n_visit = n_visit;
            context.render_context = render_context;
            context.base = base;
            context.parents = parents;
            context.siblings = siblings;
            
            if n_visit == 1
                for index=1:numel(obj.feature_declarator.directives)
                    directive = obj.feature_declarator.directives{index};
                    
                    directive.invoke_in_render(obj, context);
                end
                
                if isfield(obj.values_by_identifier, 'x') || isfield(obj.values_by_identifier, 'y')
                    
                    x = hdng.utilities.struct_get_value_at_path(obj.values_by_identifier, 'x', 0.0);
                    y = hdng.utilities.struct_get_value_at_path(obj.values_by_identifier, 'y', 0.0);
                    
                    render_context.renderer.begin_group(x, y, render_context);
                end

            end
            
            if obj.is_last_visit(n_visit)
                
                if isfield(obj.values_by_identifier, 'x') || isfield(obj.values_by_identifier, 'y')
                    
                    x = hdng.utilities.struct_get_value_at_path(obj.values_by_identifier, 'x', 0.0);
                    y = hdng.utilities.struct_get_value_at_path(obj.values_by_identifier, 'y', 0.0);

                    render_context.renderer.end_group(x, y, render_context);
                end

                for index=1:numel(obj.feature_declarator.directives)
                    directive = obj.feature_declarator.directives{index};
                    
                    directive.invoke_in_render(obj, context);
                end
            end


        end
    end

    methods (Access=protected)

        function [scale, scale_feature] = lookup_scale(~, identifier, parent_stack)
        
            scale = [];
            scale_feature = [];
            
            for index=numel(parent_stack):-1:1
                
                parent_feature = parent_stack{index};

                if isfield(parent_feature.scales_by_identifier, identifier)
                    scale = parent_feature.scales_by_identifier.(identifier);
                    scale_feature = parent_feature;
                    break;
                end
            end
        end
        
        function feature = resolve_dependency(obj, identifier, base, parents, siblings, throw_exception)
            
            feature = [];

            if ~exist('throw_exception', 'var')
                throw_exception = true;
            end

            switch identifier
                case 'self'
                    features = {obj};

                case 'previous'
                    features = siblings.inward(obj, base);
                 
                case 'next'
                    features = siblings.outward(obj, base);

                case 'parent'
                    features = parents.inward(obj, base);

                case 'grandparent'
                    features = parents.inward(obj, base);

                    if ~isempty(features)
                        features = parents.inward(features{1}, base);
                    end
                
                otherwise
                    if throw_exception
                        error('Feature:UnknownDependency', 'Unknown dependency %s', identifier);
                    else
                        features = {[]};
                    end
            end

            if ~isempty(features)
                feature = features{1};
            end
        end

        function result = check_expression_names(obj, names, throw_exception)

            result = zeros(numel(names), 1);

            for d_index=1:numel(names)
                expr_name = names{d_index};
                expression = obj.feature_declarator.expression;
                
                result(d_index) = isfield(obj.values_by_identifier, expr_name);

                if ~result(d_index) && ~isempty(expression)
                    result(d_index) = any(strcmp(expr_name, expression.assigned_identifiers));
                end

                if throw_exception && ~result(d_index)
                    error('Feature:UndefinedExpressionName', 'No expression ''%s'' found for feature', expr_name);
                end
            end
        end
        
        function result = define_render_options(obj)
            
            result = struct();

            if isfield(obj.values_by_identifier, 'class')
                if ~isempty(obj.values_by_identifier.class)
                    result.class = obj.values_by_identifier.class;
                end
            end
            

            if isfield(obj.values_by_identifier, 'style')
                if ~isempty(obj.values_by_identifier.style)
                    result.style = obj.values_by_identifier.style;
                end
            end
            

            if isfield(obj.values_by_identifier, 'fill')
                if ~isempty(obj.values_by_identifier.fill)
                    result.fill = obj.values_by_identifier.fill;
                end
            end
            
            if isfield(obj.values_by_identifier, 'stroke')
                if ~isempty(obj.values_by_identifier.stroke)
                    result.stroke = obj.values_by_identifier.stroke;
                end
            end

            if isfield(obj.values_by_identifier, 'stroke_width')
                if ~isempty(obj.values_by_identifier.stroke_width)
                    result.stroke_width = obj.values_by_identifier.stroke_width;
                end
            end
            
            if isfield(obj.values_by_identifier, 'stroke_linecap')
                if ~isempty(obj.values_by_identifier.stroke_linecap)
                    result.stroke_linecap = obj.values_by_identifier.stroke_linecap;
                end
            end
            
            if isfield(obj.values_by_identifier, 'stroke_linejoin')
                if ~isempty(obj.values_by_identifier.stroke_linejoin)
                    result.stroke_linejoin = obj.values_by_identifier.stroke_linejoin;
                end
            end
        end

    end
end
