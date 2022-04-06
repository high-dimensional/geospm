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

classdef StageTest < matlab.unittest.TestCase
 
    properties
        N
        pipeline
    end
 
    methods(TestMethodSetup)
        
        function create_pipeline(obj)
            
            obj.N = 1000;
            obj.pipeline = hdng.pipeline.Pipeline();
            
            for i=1:obj.N
                stage = hdng.pipeline.Stage();
                stage.name = num2str(i, 'stage-%d');
                obj.pipeline.add_stage(stage);
            end
        end
    end
 
    methods(TestMethodTeardown)
    end
 
    methods
        
        function count_map_key(~, map, key)
            
            if ~isKey(map, key)
                count = 0;
            else
                count = map(key);
            end

            count = count + 1;
            map(key) = count; %#ok<NASGU>
        end
        
        function variable = create_variable(~, name, variable_map)
            
            if ~isKey(variable_map, name)
                variable = hdng.pipeline.Variable(name, length(variable_map) + 1);
                variable_map(name) = variable; %#ok<NASGU>
            else
                variable = variable_map(name);
            end
        end
        
    end
    
    methods(Test)
        
        
        function defining_bindings(obj)
            
            
            variable_names = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            variable_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            for i=1:obj.N
                stage = obj.pipeline.stages{i};
                %obj.verifyEqual(stage.nth_stage, i, 'nth_stage property in stage does not match its position in pipeline.stages.');
                
                K = 10;
                
                names = hdng.utilities.randidentifier(3, 8, K);
                identifiers = hdng.utilities.randidentifier(3, 8, K);
                
                for j=1:K
                    stage.define_binding(hdng.pipeline.Stage.REQUIREMENTS_CATEGORY, names{j}, struct(), 'variable_name', identifiers{j});
                    stage.define_binding(hdng.pipeline.Stage.PRODUCTS_CATEGORY, identifiers{j}, struct(), 'variable_name', names{j});
                    
                    obj.count_map_key(variable_names, names{j});
                    obj.count_map_key(variable_names, identifiers{j});
                end
                
                required = stage.bindings_for_category(hdng.pipeline.Stage.REQUIREMENTS_CATEGORY);
                provided = stage.bindings_for_category(hdng.pipeline.Stage.PRODUCTS_CATEGORY);
                
                
                for j=1:K
                    
                    obj.verifyEqual(isfield(required, names{j}), true, ['Expected binding for requirement ''' names{j} ''' is missing in bindings_for_category().']);
                    
                    binding = required.(names{j});
                    
                    obj.verifyEqual(binding.identifier, names{j}, ['Identifier of requirement binding ''' binding.identifier ''' does not match expected value ''' names{j} '''.']);
                    obj.verifyEqual(binding.variable_name, identifiers{j}, ['Variable name of requirement binding ''' binding.variable_name ''' does not match expected value ''' identifiers{j} '''.']);
                    
                    [did_exist, binding_2] = stage.binding_for(hdng.pipeline.Stage.REQUIREMENTS_CATEGORY, names{j});
                    
                    obj.verifyTrue(did_exist, ['Requirement binding ''' names{j} ''' couldn''t be retrieved via binding_for().']);
                    obj.verifyEqual(binding, binding_2, ['Requirement binding ''' names{j} ''' retrieved via binding_for() is not the same as the one retrieved via bindings_for_category().']);
                    
                    obj.verifyEqual(isfield(provided, identifiers{j}), true, ['Expected binding for product ''' names{j} ''' is missing in bindings_for_category().']);
                    
                    binding = provided.(identifiers{j});
                    
                    obj.verifyEqual(binding.identifier, identifiers{j}, ['Identifier of product binding ''' binding.identifier ''' does not match expected value ''' identifiers{j} '''.']);
                    obj.verifyEqual(binding.variable_name, names{j}, ['Variable name of product binding ''' binding.variable_name ''' does not match expected value ''' names{j} '''.']);
                    
                    [did_exist, binding_2] = stage.binding_for(hdng.pipeline.Stage.PRODUCTS_CATEGORY, identifiers{j});
                    
                    obj.verifyTrue(did_exist, ['Requirement binding ''' names{j} ''' couldn''t be retrieved via binding_for().']);
                    obj.verifyEqual(binding, binding_2, ['Product binding ''' identifiers{j} ''' retrieved via binding_for() is not the same as the one retrieved via bindings_for_category().']);
                    
                end
                
                create_variable_handle = @(name) obj.create_variable(name, variable_map);
                
                required = stage.bind(hdng.pipeline.Stage.REQUIREMENTS_CATEGORY, hdng.pipeline.Variable.CONSUMER_ROLE, i, create_variable_handle);
                provided = stage.bind(hdng.pipeline.Stage.PRODUCTS_CATEGORY, hdng.pipeline.Variable.PRODUCER_ROLE, i, create_variable_handle);
                
               
                for j=1:K
                    
                    obj.verifyEqual(isfield(required, names{j}), true, ['Expected binding for requirement ''' names{j} ''' is missing in bind().']);
                    
                    variable = required.(names{j});
                    
                    obj.verifyEqual(variable.name, identifiers{j}, ['Identifier of requirement binding ''' variable.name ''' does not match expected value ''' names{j} '''.']);
                    
                    [~, binding] = stage.binding_for(hdng.pipeline.Stage.REQUIREMENTS_CATEGORY, names{j});
                    bindings = variable.objects_for_role(hdng.pipeline.Variable.CONSUMER_ROLE);
                    
                    result = sum(cellfun(@(x) x.binding==binding, bindings, 'UniformOutput', 1));
                    obj.verifyEqual(result, 1, ['Requirement binding ''' variable.name ''' could not be retrieved from its variable.']);
                    
                    obj.verifyEqual(isfield(provided, identifiers{j}), true, ['Expected binding for product ''' names{j} ''' is missing in bind().']);
                    
                    variable = provided.(identifiers{j});
                    
                    obj.verifyEqual(variable.name, names{j}, ['Identifier of product binding ''' variable.name ''' does not match expected value ''' names{j} '''.']);
                    
                    [~, binding] = stage.binding_for(hdng.pipeline.Stage.PRODUCTS_CATEGORY, identifiers{j});
                    bindings = variable.objects_for_role(hdng.pipeline.Variable.PRODUCER_ROLE);
                    
                    result = sum(cellfun(@(x) x.binding==binding, bindings, 'UniformOutput', 1));
                    obj.verifyEqual(result, 1, ['Product binding ''' variable.name ''' could not be retrieved from its variable.']);
                    
                end
            end
           
            obj.verifyEqual(length(variable_map), length(variable_names), sprintf('The number of bound variables does not match the number of expected variables: %d ~= %d.', length(variable_map), length(variable_names)));
            
            if length(variable_map) == length(variable_names)
                obj.verifyTrue(all(strcmp(keys(variable_map), keys(variable_names))), 'The names of the bound variables does not match the set of expected names.');
            end
        end
        
    end
end
