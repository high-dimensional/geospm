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

classdef OrderTest < matlab.unittest.TestCase
 
    properties
        N
        pipelines
        graphs
        seeds
    end
 
    methods(TestMethodSetup)
        
        function create_variables(obj)
            
            rng(9191);
            rng(383831);
            
            obj.N = 1000;
            obj.pipelines = cell(obj.N, 1);
            obj.graphs = cell(obj.N, 1);
            
            obj.seeds = randi(1000000, [obj.N 1]);
            
            for i=1:obj.N
                rng(obj.seeds(i));
                K = randi(100, 1);
                [obj.pipelines{i}, obj.graphs{i}] = obj.random_pipeline(K);
            end
        end
    end
 
    methods(TestMethodTeardown)
    end
 
    methods
        
        function result = find_predecessors(~, G, selector)
            result = sum(G(:, selector), 2)' ~= 0;
        end
        
        function result = find_successors(~, G, selector)
            result = sum(G(selector, :), 1) ~= 0;
        end
        
        function result = find_roots(~, G)
            result = sum(G, 1) == 0;
        end
        
        function result = find_leaves(~, G)
            result = sum(G, 2)' == 0;
        end
        
        function [pipeline, G] = random_pipeline(obj, K)
            
            do_debug = false;
            
            B = hdng.utilities.randacyclicgraph(K, 3);
            
            phase = 0;
            selected_stages = zeros(1, K, 'logical');
            
            active_tier = obj.find_roots(B);
            visited_set = zeros(1, K, 'logical');
            N_stage_sets = 0;
            
            variables = hdng.utilities.randidentifier(3, 8, K);
            stages = cell(K, 1);
            adjacencies = cell(K, 1);
            
            pipeline = hdng.pipeline.Pipeline();

            stage_selector = zeros(1, K, 'logical');
            variable_selector = zeros(1, K, 'logical');

            
            while sum(active_tier)
                
                if do_debug; fprintf('%s\n', '------'); end
                
                selected_stages(active_tier) = phase;
                
                active_indices = find(active_tier);
                N_active = sum(active_tier);
                
                if phase == 0
                    
                    variable_selector = bitor(variable_selector, active_tier);
                    
                    %Variables
                    for i=1:N_active
                        
                        index = active_indices(i);
                        
                        selector = zeros(1, K, 'logical');
                        selector(index) = 1;
                        
                        selected_stages = bitand(stage_selector, obj.find_predecessors(B, selector));
                        
                        
                        if do_debug; fprintf('variable-%s\n', variables{index}); end
                        
                        producers = stages(selected_stages);
                        
                        if numel(producers) > 0
                            %Only pick one producer per variable
                            j = randi(numel(producers), 1);
                            stage = producers{j};
                            if do_debug; fprintf('    %s\n', stage.name); end
                            
                            %Make sure the name of the binding is unique
                            %for its stage.
                            b = numel(fieldnames(stage.bindings_for_category('products'))) + 1;
                            stage.define_binding('products', num2str(b, 'binding_%d'), struct('variable_name', variables{index}));
                        end
                    end
                    
                else
                    
                    N_stage_sets = N_stage_sets + 1;
                    
                    stage_selector = bitor(stage_selector, active_tier);
                    
                    %Stages
                    for i=1:N_active
                        
                        stage = hdng.pipeline.Stage();
                        
                        index = active_indices(i);
                        
                        selector = zeros(1, K, 'logical');
                        selector(index) = 1;
                        
                        stages{index} = stage;
                        stage.name = sprintf('stage-%d', index);
                        
                        if do_debug; fprintf('%s\n', stage.name); end
                        
                        selected_variables = bitand(variable_selector, obj.find_predecessors(B, selector));
                        
                        required_variables = variables(selected_variables);
                        
                        if N_stage_sets ~= 1
                            
                            predecessors = bitand(visited_set, bitand(stage_selector, obj.find_predecessors(B, selected_variables)));
                            
                            predecessors = find(predecessors);
                            adjacencies{index} = predecessors;
                            
                            for j=1:numel(required_variables)
                                if do_debug; fprintf('    %s\n', required_variables{j}); end
                                stage.define_binding('requirements', num2str(j, 'binding_%d'), struct('variable_name', required_variables{j}));
                            end
                        end
                    end
                    
                end
                
                phase = bitand(phase + 1, 1);
                visited_set = bitor(visited_set, active_tier);
                active_tier = bitand(~visited_set, obj.find_successors(B, active_tier));
            end
            
            N_stages = sum(stage_selector);
            
            adjacency_map = zeros(1, K);
            adjacency_map(stage_selector) = 1:N_stages;
            
            indices = find(stage_selector);
            
            G = zeros(N_stages, 'logical');
            
            for i=1:N_stages
                a = adjacencies{indices(i)};
                a = adjacency_map(a);
                G(i, a) = 1;
            end
            
            stages = stages(stage_selector);
            
            permutation = randperm(N_stages);
            
            stages = stages(permutation);
            
            for i=1:N_stages
                pipeline.add_stage(stages{i});
            end
            
            G = G(permutation,permutation);
        end
        
        
        function variable = create_variable(~, name, variable_map)
            
            did_exist = isKey(variable_map, name);

            if ~did_exist
                variable = hdng.pipeline.Variable(name, length(variable_map) + 1);
                variable_map(name) = variable; %#ok<NASGU>
            else
                variable = variable_map(name);
            end
        end
        
        
        
        function verify_sort_order(obj, elements, G)
            
            K = numel(elements);
            predecessors = zeros(1, K, 'logical');
            
            for i=1:K
                index = elements{i};
                matched_predecessors = bitand(predecessors, G(index, :));
                is_valid = sum(xor(matched_predecessors, G(index, :))) == 0;
                
                if ~is_valid
                    obj.verifyFail(sprintf('Element %d is not in order.', index));
                end
                
                predecessors(index) = 1;
            end
            
        end
        
    end
    
    methods(Test)
        
        function stage_order(obj)
            
            variable_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            for i=1:obj.N
                
                fprintf('Seed #%d.\n', obj.seeds(i));
                        
                pipeline = obj.pipelines{i};
                
                requirements = cell(pipeline.N_stages, 1);
                products = cell(pipeline.N_stages, 1);
                
                for j=1:pipeline.N_stages
                    stage = pipeline.stages{j};
                    requirements{j} = stage.bind('requirements', 'consumer', j, @(name) obj.create_variable(name, variable_map));
                    products{j} = stage.bind('products', 'producer', j, @(name) obj.create_variable(name, variable_map));
                end
                
                variables = values(variable_map);
                
                for j=1:numel(variables)
                    variable = variables{j};
                    
                    producers = variable.objects_for_role('producer');
                    
                    if numel(producers) == 0
                        obj.verifyFail(fprintf(['Variable ' variable.name ' [' num2str(j, '%d') '] does not have any producers.\n']));
                    end
                end
                
                permutation = hdng.pipeline.order_stages(pipeline.stages, requirements);
                
                sorted_stages = pipeline.stages(permutation);
                
                %{
                for j=1:pipeline.N_stages
                    fprintf('%s\n', sorted_stages{j}.name);
                end
                %}
                
                graph = obj.graphs{i};
                obj.verify_sort_order(num2cell(permutation), graph);
            end
            
        end
        
    end
end
