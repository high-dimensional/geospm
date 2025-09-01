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

classdef FeatureModule < handle
    %FeatureModule Summary.
    %   Detailed description 
    
    properties
    end

    properties (GetAccess=public, SetAccess=private)
        definitions_by_uuid
        root_definitions_by_category
        root_feature_declarator
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = FeatureModule()

            obj.definitions_by_uuid = struct();
            obj.root_definitions_by_category = struct();
            obj.root_feature_declarator = hdng.diagrams.FeatureDeclarator();
        end

        function add_definition(obj, definition)
            
            list = hdng.utilities.struct_get_value_at_path(...
                obj.root_definitions_by_category, definition.category, {});
            list{end + 1} = definition;

            obj.root_definitions_by_category.(definition.category) = list;
            
            if isa(definition, 'hdng.diagrams.FeatureDeclarator')
                obj.root_feature_declarator.add_child(definition);
            end

            queue = {definition};

            while ~isempty(queue)
                
                d = queue{1};
                queue = queue(2:end);
    
                obj.definitions_by_uuid = ...
                    hdng.utilities.struct_set_value_at_path(...
                        obj.definitions_by_uuid, ...
                        [d.category '.uuid_' d.uuid_as_identifier], d);

                queue = [queue; d.nested_definitions]; %#ok<AGROW>
            end
        end

        function add_definitions(obj, varargin)
            
            for index=1:numel(varargin)
                definition = varargin{index};
                obj.add_definition(definition);
            end
        end

        function result = build_features(obj, data_descriptor)
            
            data_module = data_descriptor.data_module;
            data_root = data_descriptor.root_scope;
            data_level_parents = data_descriptor.data_level_parents;

            feature_map = cell(data_descriptor.base.node_count, 1);

            root_feature = [];
            base = hdng.diagrams.NodeBase();

            parent_pairs = {};
            sibling_pairs = {};

            obj.bind_feature_declarators(data_module);
            
            stack = {};
            queue = {{{data_root}, [], 1}};
            
            while ~isempty(queue)
                
                visit = queue{1}; queue = queue(2:end);
                scopes = visit{1};
                parent_feature = visit{2};
                parent_depth = visit{3};

                stack{parent_depth} = parent_feature; %#ok<AGROW>
                
                feature_one_before = [];

                for index=1:numel(scopes)
                    
                    current_scope = scopes{index};

                    data_level = current_scope.data_level;
                    
                    if ~isempty(data_level.identifier)
                        declarator = hdng.utilities.struct_get_value_at_path( ...
                             obj.root_feature_declarator.children_by_identifier, ...
                             data_level.identifier, {});
                        
                        feature = declarator.generate_feature(current_scope, stack);
                    else
                        feature = hdng.diagrams.Feature(...
                            'data_scope', current_scope, ...
                            'feature_declarator', hdng.diagrams.FeatureDeclarator());
                    end
                    
                    feature_map{current_scope.node_number} = feature;

                    [parent_pairs, sibling_pairs] = ...
                        obj.link_features(feature, base, parent_pairs, sibling_pairs);
                    
                    if ~isempty(parent_feature)
                        parent_feature.add_child(feature);

                        parent_pairs{end + 1} = {parent_feature, feature}; %#ok<AGROW>
                    else
                        root_feature = feature;
                    end

                    if ~isempty(feature_one_before)
                        sibling_pairs{end + 1} = {feature_one_before, feature}; %#ok<AGROW>
                    end

                    feature_one_before = feature;
                    
                    queue = [queue; {{current_scope.children, feature, parent_depth + 1}}]; %#ok<AGROW>
                end
            end
            
            parents = hdng.diagrams.SparseAdjacencies(numel(base.nodes));
            siblings = hdng.diagrams.SparseAdjacencies(numel(base.nodes));
            
            for index=1:numel(parent_pairs)
                pair = parent_pairs{index};
                parents.define(pair{1}, pair{2}, base);
            end

            for index=1:numel(sibling_pairs)
                pair = sibling_pairs{index};
                siblings.define(pair{1}, pair{2}, base);
            end

            %{
            declarators = hdng.utilities.struct_get_value_at_path(...
                obj.root_definitions_by_category, ...
                'feature_declarator', ...
                {});
            %}

            groups = hdng.diagrams.EvaluationGroup.gather_evaluation_groups(root_feature);
            usages = hdng.diagrams.ScaleUsage.gather_scale_usages(groups, base, parents);
            obj.compute_scaled_values(usages, true);

            result.root_feature = root_feature;
            result.feature_map = feature_map;
            result.base = base;
            result.parents = parents;
            result.siblings = siblings;
        end
    end

    methods (Access=protected)
        
        function compute_scaled_values(obj, usages, do_calibrate)
            
            if ~do_calibrate
    
                for index=1:numel(usages)
                    usage = usages{index};
                    
                    [~, values] = usage.gather_values();
                    values = usage.compute_scaled_values(values);

                    constants = usage.gather_constants();
                    constants = hdng.one_struct(usage.scale_identifier, constants);
                    constants = usage.compute_scaled_values(constants);
                    constants = constants.(usage.scale_identifier);

                    usage.update_scaled_values(values, constants);
                end
                
                return;
            end

            usage_map = obj.compute_scale_usage_map(usages);
            
            feature_identifiers = fieldnames(usage_map);

            for f_index=1:numel(feature_identifiers)
                feature_identifier = feature_identifiers{f_index};
                scale_map = usage_map.(feature_identifier);

                scale_identifiers = fieldnames(scale_map);

                for s_index=1:numel(scale_identifiers)
                    scale_identifier = scale_identifiers{s_index};
                    scale_usages = scale_map.(scale_identifier);

                    scale_flat_values = [];
                    scale_stratified_values = {};
                    
                    scale_flat_constants = [];

                    scale = [];

                    for u_index=1:numel(scale_usages)
                        usage = scale_usages{u_index};
                        scale = usage.scale;
                        
                        [flat_values, stratified_values] = usage.gather_values();

                        scale_flat_values = [scale_flat_values; flat_values]; %#ok<AGROW>
                        scale_stratified_values = [scale_stratified_values; {stratified_values}]; %#ok<AGROW>

                        flat_constants = usage.gather_constants();
                        scale_flat_constants = [scale_flat_constants; flat_constants]; %#ok<AGROW>
                    end
                    
                    if ~isempty(scale)

                        scale.calibrate([scale_flat_values; scale_flat_constants]);
                        
                        for u_index=1:numel(scale_usages)
                            usage = scale_usages{u_index};
                            
                            stratified_values = scale_stratified_values{u_index};

                            if ~isempty(stratified_values)
                                stratified_values = usage.compute_scaled_values(stratified_values);
                            else
                                stratified_values = struct();
                            end
                            
                            flat_constants = usage.gather_constants();

                            if ~isempty(flat_constants)
                                stratified_constants = hdng.one_struct(scale_identifier, flat_constants);
                                stratified_constants = usage.compute_scaled_values(stratified_constants);
                                flat_constants = stratified_constants.(scale_identifier);
                            end

                            usage.update_scaled_values(stratified_values, flat_constants);
                        end
                    end
                end
            end
        end

        function usage_map = compute_scale_usage_map(~, usages)

            usage_map = struct();
            
            for index=1:numel(usages)
                usage = usages{index};
                
                path = sprintf('feature_%d.%s', usage.scale_feature.node_number, usage.scale_identifier);
                
                scale_usages = hdng.utilities.struct_get_value_at_path(...
                    usage_map, path, {});

                scale_usages{end + 1} = usage; %#ok<AGROW>

                usage_map = hdng.utilities.struct_set_value_at_path(...
                    usage_map, path, scale_usages);
            end
        end

        function result = bind_feature_declarators(obj, data_module)
            
            result = {};

            obj.root_feature_declarator.generating_data_level = ...
                data_module.root_data_level;
            
            
            declarators = hdng.utilities.struct_get_value_at_path(...
                obj.root_definitions_by_category, ...
                'feature_declarator', ...
                {});
            
            for index=1:numel(declarators)
                
                declarator = declarators{index};

                data_level = hdng.utilities.struct_get_value_at_path(...
                    data_module.data_level_by_identifier, ...
                    declarator.identifier, ...
                    []);

                declarator.generating_data_level = data_level;

                if ~isempty(data_level)
                    result{end + 1} = declarator; %#ok<AGROW>
                end
            end
        end
    end


    methods (Static, Access=protected)
        
        function [parent_pairs, sibling_pairs] = ...
                link_features(feature_root, base, parent_pairs, sibling_pairs)
        
            traversal = {{feature_root, [], []}};
            t_index = 1;
            
            while t_index <= numel(traversal)
                
                t_state = traversal{t_index};
                t_index = t_index + 1;
                
                f = t_state{1};

                base.add_node(f);

                p = t_state{2};
                b = t_state{3};

                if ~isempty(p)
                    parent_pairs{end + 1} = {p, f}; %#ok<AGROW>
                end
                
                if ~isempty(b)
                    sibling_pairs{end + 1} = {b, f}; %#ok<AGROW>
                end

                b_child = [];

                for c_index=1:numel(f.children)
                    child = f.children{c_index};
                    
                    traversal{end + 1} = {child, f, b_child}; %#ok<AGROW>
                    b_child = child;
                end
            end
        end
    end

end
