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

classdef Pipeline < hdng.pipeline.Stage
    %Pipeline Runs computations as a sequence of stages.
        
    properties (SetAccess=private)
        diagnostics
        stages
    end
    
    properties (Dependent, Transient)
        N_stages
    end
    
    properties (GetAccess=private, SetAccess=private)
        twin
    end
    
    methods
        
        function obj = Pipeline(options, varargin)
            %Creates a new Pipeline object.
            %
            % options - A structure of options. 
            % varargin - An arbitrary number of Name, Value pairs specifying
            % additional options which override any settings given in the 
            % options structure.
            %
            % The following options are currently defined:
            %
            %  diagnostics - A structure holding diagnostics settings.
            %
            %  diagnostics.active - A global on/off switch for all
            %  diagnostic settings (default boolean value is false);
            %
            
            if ~exist('options', 'var') || isempty(options)
                options = struct();
            end
            
            additional_options = hdng.utilities.parse_struct_from_varargin(varargin{:});
           
            names = fieldnames(additional_options);
            
            for i=1:numel(names)
                name = names{i};
                options.(name) = additional_options.(name);
            end
            
            if ~isfield(options, 'diagnostics')
                options.diagnostics = struct();
            end
            
            if ~isfield(options.diagnostics, 'active')
                options.diagnostics.active = false;
            end
            
            obj = obj@hdng.pipeline.Stage();
            
            obj.diagnostics = options.diagnostics;
            obj.twin = hdng.pipeline.Stage();
            
            obj.stages = cell(0, 1);
        end
        
        function result = get.N_stages(obj)
            result = numel(obj.stages);
        end
        
        function add_stage(obj, stage)
            obj.stages{end + 1} = stage;
        end
        
        function remove_stage(obj, stage)
            
            index = cellfun(@(x) x==stage, obj.stages, 'UniformOutput', 1);
            
            if index
                obj.stages{index, :} = [];
            end
        end
        
        
        function output_values = run(obj, input_values)
            
            REQUIREMENTS_CATEGORY = hdng.pipeline.Stage.REQUIREMENTS_CATEGORY;
            PRODUCTS_CATEGORY = hdng.pipeline.Stage.PRODUCTS_CATEGORY;
            
            CONSUMER_ROLE = hdng.pipeline.Variable.CONSUMER_ROLE;
            PRODUCER_ROLE = hdng.pipeline.Variable.PRODUCER_ROLE;
            INPUT_ROLE = hdng.pipeline.Variable.INPUT_ROLE;
            OUTPUT_ROLE = hdng.pipeline.Variable.OUTPUT_ROLE;
            
            variable_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
            create_variable = @(name) obj.create_variable(name, variable_map);
            
            input_variables = obj.twin.bind(REQUIREMENTS_CATEGORY, INPUT_ROLE, 1, create_variable);
            output_variables = obj.twin.bind(PRODUCTS_CATEGORY, OUTPUT_ROLE, 1, create_variable);
            
            required_variables = obj.bind_stages(REQUIREMENTS_CATEGORY, CONSUMER_ROLE, create_variable);
            provided_variables = obj.bind_stages(PRODUCTS_CATEGORY, PRODUCER_ROLE, create_variable);
            
            obj.check_variables(values(variable_map));
            
            permutation = hdng.pipeline.order_stages(obj.stages, required_variables);
            ordered_stages = obj.stages(permutation);
            
            variables = cell(length(variable_map), 1);
            variables = hdng.pipeline.read_variables(variables, input_variables, input_values);
            
            for i=1:numel(ordered_stages)
                
                stage = ordered_stages{i};
                
                required = required_variables{stage.nth_stage};
                provided = provided_variables{stage.nth_stage};
                
                arguments = hdng.pipeline.write_variables(variables, required);
                arguments = obj.write_stage_defaults(stage, required, arguments, input_values);
                
                result = stage.run(arguments);
                
                variables = hdng.pipeline.read_variables(variables, provided, result);
            end
            
            output_values = hdng.pipeline.write_variables(variables, output_variables);
        end
       
        function [binding, options] = define_binding(obj, category, identifier, options, varargin)
            
            [binding, options] = define_binding@hdng.pipeline.Stage(obj, category, identifier, options, varargin{:});
            
            if ~isfield(options, 'internal_variable_name')
                options.internal_variable_name = options.variable_name;
            end
            
            options.variable_name = options.internal_variable_name;
            
            obj.twin.define_binding(category, identifier, options);
        end
        
        function delete_binding(obj, category, identifier)
            
            delete_binding@hdng.pipeline.Stage(obj, category, identifier);
            obj.twin.delete_binding(category, identifier);
        end
        
    end
    
    methods (Access = private)
        
        function interface_value_map = write_stage_defaults(~, stage, interface, interface_value_map, input_values)
            
            bindings = stage.bindings_for_category(hdng.pipeline.Stage.REQUIREMENTS_CATEGORY);
            names = fieldnames(bindings);
            
            for i=1:numel(names)
                name = names{i};
                binding = bindings.(name);
                
                if ~binding.is_optional
                    continue
                end
                
                variable = interface.(binding.variable_name);
                
                producers = variable.objects_for_role(hdng.pipeline.Variable.PRODUCER_ROLE);
                input = variable.objects_for_role(hdng.pipeline.Variable.INPUT_ROLE);

                if numel(producers) == 0 && (numel(input) == 0 || ~isfield(input_values, variable.name))
                    interface_value_map.(name) = binding.default_value;
                end
            end
        end
        
        function check_variables(~, variables)
        
            for i=1:numel(variables)
                
                variable = variables{i};
                
                producers = variable.objects_for_role(hdng.pipeline.Variable.PRODUCER_ROLE);
                consumers = variable.objects_for_role(hdng.pipeline.Variable.CONSUMER_ROLE);
                
                inputs = variable.objects_for_role(hdng.pipeline.Variable.INPUT_ROLE);
                
                N_producers = numel(producers);
                
                if N_producers == 0
                    
                    if numel(inputs) == 0
                        
                        for j=1:numel(consumers)
                            consumer = consumers{j};
                            
                            if ~consumer.binding.is_optional
                                error(['hdng.pipeline.Pipeline.check_variables(): Binding ''' consumer.binding.identifier ''' to variable ''' variable.name ''' does not provide default value.']);
                            end
                        end
                        
                        %warning(['hdng.pipeline.Pipeline.run(): Variable ''' variable.name ''' is not provided by any stage.']);
                    end
                elseif N_producers > 1
                    
                    error(['hdng.pipeline.Pipeline.run(): Variable ''' variable.name ''' is provided by more than one stage.']);
                end
                
                N_consumers = numel(consumers);
                
                if N_consumers == 0
                    
                    if numel(inputs) == 0
                        %warning(['hdng.pipeline.Pipeline.run(): Variable ''' variable.name ''' is not used by any stage.']);
                    end
                end
            end
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
        
        function stage_maps = bind_stages(obj, ...
                    category, role, create_variable)
            
            stage_maps = cell(obj.N_stages, 1);
            
            for i=1:obj.N_stages
                stage = obj.stages{i};
                stage_maps{i} = stage.bind(category, role, i, create_variable);
            end
        end
        
    end
    
end
