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

classdef ScheduleIterator < handle
    %ScheduleIterator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        schedule
    end
    
    properties (GetAccess=public, SetAccess=private)
        N_variables
        variables
        constants
        iteration_order
        requirements
        
        value_generators
        values
        iterators
        
        configuration_number
        update_index
        
        is_done
    end
    
    properties (Dependent, Transient)
        variable_names
    end
    
    methods
        
        function obj = ScheduleIterator(schedule, constants)
            
            obj.schedule = schedule;
            obj.constants = constants;
            obj.N_variables = schedule.N_variables;
            
            [obj.variables, obj.iteration_order, obj.requirements] = schedule.order_variables();

            obj.value_generators = cell(obj.N_variables, 1);
            obj.values = hdng.utilities.Dictionary();
            obj.iterators = cell(obj.N_variables, 1);
            
            for index=1:obj.N_variables
                obj.value_generators{index} = obj.variables{index}.value_generator;
                obj.values(obj.variables{index}.identifier) = [];
            end
            
            constant_names = fieldnames(obj.constants);
            
            for index=1:numel(constant_names)
                constant_name = constant_names{index};
                constant = obj.constants.(constant_name);
                obj.values(constant_name) = constant;
            end
            
            obj.configuration_number = 0;
            obj.update_index = 1;
            obj.is_done = false;
        end
        
        function result = get.variable_names(obj)
            
            result = cell(obj.N_variables, 1);
            
            for index=1:obj.N_variables
                result{index} = obj.variables{index}.identifier;
            end
        end
        
        function [is_valid, result] = next(obj)
            
            is_valid = false;
            result = hdng.experiments.Configuration();
            
            if obj.is_done
                return
            end

            
            for v_index=obj.update_index:obj.N_variables

                %fprintf('Updating variable %s\n', obj.variables{v_index}.identifier);
                
                arguments = struct();

                for r_index=1:numel(obj.requirements{v_index})
                    identifiers = obj.requirements{v_index};
                    identifier = identifiers{r_index};
                    value = obj.values(identifier);
                    
                    if isa(value, 'hdng.experiments.SkipValue')
                        continue
                    end
                    
                    arguments.(identifier) = value;
                end
                
                constant_names = fieldnames(obj.constants);

                for index=1:numel(constant_names)
                    constant_name = constant_names{index};
                    constant = obj.constants.(constant_name);
                    arguments.(constant_name) = constant;
                end
                
                %fprintf('Updating variable: %s\n', obj.variables{v_index}.identifier);
                
                obj.iterators{v_index} = obj.value_generators{v_index}(arguments);
                [is_valid, obj.values(obj.variables{v_index}.identifier)] = obj.iterators{v_index}.next();

                if ~is_valid
                    error('Value generator for variable ''%s'' must produce at least one value.', obj.variables{v_index}.identifier);
                end
            end
            
            obj.configuration_number = obj.configuration_number + 1;
            
            result.number = obj.configuration_number;
            result.schedule = obj.schedule;
            result.values = obj.values.copy();
            
            result_keys = result.values.keys();
            
            for r_index=1:numel(result_keys)
                key = result_keys{r_index};
                value = result.values(key);
                
                if isa(value, 'hdng.experiments.SkipValue')
                    result.values.remove(key);
                end
            end
            
            for v_index=obj.N_variables:-1:1
                
                [is_valid, obj.values(obj.variables{v_index}.identifier)] = obj.iterators{v_index}.next();

                if is_valid
                    obj.update_index = v_index + 1;
                    break
                end

                if v_index == 1
                    obj.is_done = true;
                    break
                end
            end

            is_valid = true;
        end
        
    end
    
    methods (Static, Access=private)
    end
    
end
