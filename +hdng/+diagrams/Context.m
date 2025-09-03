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

classdef Context < handle
    %Context Summary.
    %   Detailed description 
    
    properties
    end

    properties (GetAccess=public, SetAccess=private)
        data_module
        records

        feature_module
    end

    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Context(data_module, records, feature_module)

            if ~exist('records', 'var')
                records = hdng.utilities.RecordTable();
            end

            if ~exist('feature_module', 'var')
                feature_module = hdng.diagrams.FeatureModule();
            end
            
            obj.data_module = data_module;
            obj.records = records;

            obj.feature_module = feature_module;
        end
        
        function feature_descriptor = compile(obj)
            
            data_descriptor = ...
                obj.data_module.build_data_scopes(obj.records);

            feature_descriptor = obj.feature_module.build_features(...
                data_descriptor);

        end

        function layout(~, descriptor)
        
            processing = hdng.diagrams.SparseAdjacencies(numel(descriptor.base.nodes));

            queue = {descriptor.root_feature};
            
            while ~isempty(queue)
                feature = queue{1}; queue = queue(2:end);

                feature.define_dependencies(descriptor.base, descriptor.parents, descriptor.siblings, processing);

                queue = [queue; feature.children(:)]; %#ok<AGROW>
            end
            
            order = descriptor.base.sort_nodes(processing);

            sorted_nodes = descriptor.base.nodes(order);

            for index=1:numel(sorted_nodes)
                feature = sorted_nodes{index};
                feature.update_expressions(descriptor.base, descriptor.parents, descriptor.siblings);
            end
        end

        function render(~, descriptor, context, varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'root_directives')
                options.root_directives = {};
            end
            
            %{
            if ~isfield(options, 'context')
                options.context = hdng.diagrams.rendering.RenderContext(...
                    'renderer', renderer);
            end

            context = options.context;
            %}

            root_declarator = descriptor.root_feature.feature_declarator;
            saved_directives = root_declarator.directives;
            root_declarator.add_directives(options.root_directives{:});

            stack = {{descriptor.root_feature, 0}};
            
            %{
            while ~isempty(stack)

                state = stack{end};

                feature = state{1};
                n_visit = state{2};

                n_visit = n_visit + 1;

                if n_visit == 1 || feature.is_last_visit(n_visit) % == numel(feature.children) + 1
                    feature.render(n_visit, context, descriptor.base, ...
                        descriptor.parents, descriptor.siblings);
                end

                if n_visit > numel(feature.children)
                    stack = stack(1:end - 1);
                else
                    state{2} = n_visit;
                    stack{end} = state;

                    state{1} = feature.children{n_visit};
                    state{2} = 0;

                    stack{end + 1} = state; %#ok<AGROW>
                end
            end
            %}

            while ~isempty(stack)

                state = stack{end};

                feature = state{1};
                n_visit = state{2};

                n_visit = n_visit + 1;

                next_child = feature.render(n_visit, context, descriptor.base, ...
                        descriptor.parents, descriptor.siblings);
                
                if isempty(next_child)
                    stack = stack(1:end - 1);
                else
                    state{2} = n_visit;
                    stack{end} = state;

                    state{1} = next_child;
                    state{2} = 0;

                    stack{end + 1} = state; %#ok<AGROW>
                end
            end

            root_declarator.clear_directives();
            root_declarator.add_directives(saved_directives);
        end
    end
end
