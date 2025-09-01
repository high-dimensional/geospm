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

classdef DataModule < handle
    %DataModule Summary.
    %   Detailed description 
    
    properties
    end

    properties (GetAccess=public, SetAccess=private)
        definitions_by_uuid
        root_definitions_by_category
        
        root_data_level
        
        data_level_by_identifier
    end

    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = DataModule()

            obj.definitions_by_uuid = struct();
            obj.root_definitions_by_category = struct();

            obj.root_data_level = hdng.diagrams.DataLevel();
            obj.data_level_by_identifier = struct();
        end

        function add_definition(obj, definition)
            

            list = hdng.utilities.struct_get_value_at_path(obj.root_definitions_by_category, definition.category, {});
            list{end + 1} = definition;

            obj.root_definitions_by_category.(definition.category) = list;
            
            if isa(definition, 'hdng.diagrams.DataLevel')
                obj.root_data_level.add_child(definition);
            end

            queue = {definition};

            while ~isempty(queue)
                
                d = queue{1};
                queue = queue(2:end);
    
                obj.definitions_by_uuid = ...
                    hdng.utilities.struct_set_value_at_path(...
                        obj.definitions_by_uuid, ...
                        [d.category '.uuid_' d.uuid_as_identifier], d);
    
                if isa(d, 'hdng.diagrams.DataLevel')
                    obj.data_level_by_identifier.(d.identifier) = d;
                end

                queue = [queue; d.nested_definitions]; %#ok<AGROW>
            end


            %{
            obj.definitions = ...
                hdng.utilities.struct_set_value_at_path(...
                    obj.definitions, ...
                    [definition.category '.uuid_' definition.uuid_as_identifier], ...
                    definition);
            %}
        end

        function add_definitions(obj, varargin)
            
            for index=1:numel(varargin)
                definition = varargin{index};
                obj.add_definition(definition);
            end
        end

        function result = format_attributes(~, attributes)

            names = fieldnames(attributes);
            
            summary = '';

            for index=1:numel(names)
                name = names{index};
                value = attributes.(name);

                format = '';

                if isa(value, 'char')
                    format = '%s';
                elseif isa(value, 'double')
                    format = '%.2f';
                elseif isa(value, 'logical')
                    format = '%d';
                elseif isa(value, 'int64')
                    format = '%d';
                end

                summary = sprintf(['%s\n  %s=' format], summary, name, value);
            end

            result = sprintf([summary '\n\n']);
        end

        
        function result = build_data_scopes(obj, records)
            
            base = hdng.diagrams.NodeBase();
            parent_pairs = {};
            sibling_pairs = {};

            data_level_parents = struct();

            root_scope = hdng.diagrams.DataScope(obj.root_data_level, struct(), records);
            
            queue = {root_scope};
            
            while ~isempty(queue)
                
                current_scope = queue{1}; queue = queue(2:end);
                base.add_node(current_scope);
                
                for index=1:numel(current_scope.data_level.children)

                    data_level = current_scope.data_level.children{index};

                    nested_scopes = data_level.generate_scopes_from(current_scope);

                    %fprintf('Generated %d nested scopes at data level %s\n', numel(nested_scopes), data_level.identifier);
                    
                    current_scope.add_children(nested_scopes{:});
                    
                    previous_sibling = [];

                    for c_index=1:numel(nested_scopes)
                        nested_scope = nested_scopes{c_index};
                        parent_pairs{end + 1} = {current_scope, nested_scope}; %#ok<AGROW>

                        if ~isempty(previous_sibling)
                            sibling_pairs{end + 1} = {previous_sibling, nested_scope}; %#ok<AGROW>
                        end

                        previous_sibling = nested_scope;
                    end

                    parents = hdng.utilities.struct_get_value_at_path(...
                        data_level_parents, data_level.identifier, ...
                        {});

                    parents{end + 1} = current_scope; %#ok<AGROW>

                    data_level_parents.(data_level.identifier) = parents;

                    queue = [queue; nested_scopes]; %#ok<AGROW>
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

            stack = {{root_scope, 0}};

            while ~isempty(stack)
                visit = stack{end};
                scope = visit{1};
                child_index = visit{2} + 1;

                visit{2} = child_index;
                stack{end} = visit;

                if child_index > numel(scope.children)

                    scope.compute_assignments(base, parents, siblings);

                    stack = stack(1:end - 1);
                    continue;
                end

                child = scope.children{child_index};
                stack = [stack; {{child, 0}}]; %#ok<AGROW>
            end

            result = struct();
            result.data_module = obj;
            result.root_scope = root_scope;
            result.base = base;
            result.parents = parents;
            result.siblings = siblings;
            result.data_level_parents = data_level_parents;
        end
    end
end
