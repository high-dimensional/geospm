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

classdef Generator < handle
    %Generator A mechanism for generating a family of models.
    %   Detailed explanation goes here
    
    properties
        probe_expressions %cell array of expressions returning [x, y, radius] of probe disc
        
        debug_path
    end
    
    properties (SetAccess=private)
        domain
        parameters
        roles
        roles_by_identifier
        bindings
        bindings_per_role
        controls
        expressions
        maps
        
        parameters_by_identifier
    end
    
    properties (Dependent, Transient)
        N_roles
        N_bindings
        N_parameters
        N_controls
        N_expressions
        N_maps
    end
    
    methods
        
        function obj = Generator(domain)
            
            obj.domain = domain;
            obj.roles = cell(0, 1);
            obj.roles_by_identifier = containers.Map('KeyType', 'char','ValueType', 'any');
            
            obj.bindings = cell(0, 1);
            obj.bindings_per_role = cell(0, 1);
            
            obj.parameters = cell(0,1);
            obj.controls = cell(0,1);
            obj.expressions = cell(0,1);
            obj.maps = cell(0,1);
            
            obj.parameters_by_identifier = containers.Map('KeyType', 'char','ValueType', 'any');
            
            obj.probe_expressions = {};
            obj.debug_path = pwd;
        end
        
        function result = get.N_roles(obj)
            result = numel(obj.roles);
        end
        
        function result = get.N_bindings(obj)
            result = numel(obj.bindings);
        end
        
        function result = get.N_parameters(obj)
            result = numel(obj.parameters);
        end
        
        function result = get.N_controls(obj)
            result = numel(obj.controls);
        end
        
        function result = get.N_expressions(obj)
            result = numel(obj.expressions);
        end
        
        function result = get.N_maps(obj)
            result = numel(obj.maps);
        end
        
        function nth_role = add_role(obj, role)
            obj.roles{end + 1} = role;
            nth_role = numel(obj.roles);
            obj.roles_by_identifier(role.identifier) = role;
            obj.bindings_per_role{end + 1} = {};
        end
        
        function nth_binding = add_binding(obj, binding)
            obj.bindings{end + 1} = binding;
            nth_binding = numel(obj.bindings);
            role_bindings = obj.bindings_per_role{binding.role_index};
            role_bindings{end + 1} = binding;
            obj.bindings_per_role{binding.role_index} = role_bindings;
        end
        
        function nth_parameter = add_parameter(obj, parameter)
            obj.parameters{end + 1} = parameter;
            nth_parameter = numel(obj.parameters);
            obj.parameters_by_identifier(parameter.identifier) = parameter;
        end
        
        function nth_control = add_control(obj, control)
            obj.controls{end + 1} = control;
            nth_control = numel(obj.controls);
        end
        
        function nth_expression = add_expression(obj, expression)
            obj.expressions{end + 1} = expression;
            nth_expression = numel(obj.expressions);
        end
        
        function nth_map = add_map(obj, map)
            obj.maps{end + 1} = map;
            nth_map = numel(obj.maps);
        end
        
        function [result, does_exist] = get_parameter_by_identifier(obj, identifier, default_value)
            
            if ~exist('default_value', 'var')
                default_value = struct();
            end
            
            if ~isKey(obj.parameters_by_identifier, identifier)
                does_exist = false;
                result = default_value;
                return;
            end
            
            does_exist = true;
            result = obj.parameters_by_identifier(identifier);
        end
        
        function check_bindings(obj)
            
            for i=1:obj.N_roles
                
                role = obj.roles{i};
                role_bindings = obj.bindings_per_role{i};
                
                if numel(role_bindings) < role.min_bindings && numel(role_bindings) < role.max_bindings
                    error(['Generator.check_bindings(): Too few bindings for role ' role.identifier]);
                end

                if numel(role_bindings) > role.max_bindings
                    error(['Generator.check_bindings(): Too many bindings for role ' role.identifier]);
                end
                
                result = role.check(obj, role_bindings);
                
                if ~result.passed
                    error(['Generator.check_bindings(): One or more bindings for role ' role.identifier ' failed:' newline result.diagnostic]);
                end
            end
            
        end
        
        function binding = bind_parameter(obj, parameter, role_identifier, arguments)
            
            if ~isKey(obj.roles_by_identifier, role_identifier)
                error(['Generator.bind_role(): No role with identifier ''' role_identifier '''']);
            end
            
            if ~exist('arguments', 'var')
                arguments = struct();
            end
            
            role = obj.roles_by_identifier(role_identifier);
            binding = geospm.models.ParameterBinding(obj, role.nth_role, parameter.nth_parameter, arguments);
            
            role.listener(obj, obj.bindings_per_role{role.nth_role}, {binding}, {});
        end
        
        function settings = get_settings(obj)
            
            settings = struct();
            
            for i=1:obj.N_controls
                control = obj.controls{i};
                settings.(control.identifier) = control.value;
            end
        end
        
        function [model, metadata] = render(obj, seed, transform, spatial_resolution, settings) %#ok<INUSD,STOUT>
            error('Generator.render() must be implemented by a subclass.');
        end
    end
    
    methods (Static, Access=public)
        
                        
        function result = create(generator_type, varargin)
            
            builtins = geospm.models.Generator.builtin_generators();
            
            if ~isKey(builtins, generator_type)
                error(['Generator.create(): Unknown builtin generator type: ' generator_type]);
            end
            
            ctor = builtins(generator_type);
            result = ctor(varargin{:});
        end
        
        function result = builtin_generators()
            
            persistent BUILTIN_GENERATORS;
            
            if isempty(BUILTIN_GENERATORS)
            
                where = mfilename('fullpath');
                [base_dir, ~, ~] = fileparts(where);
                regions_dir = fullfile(base_dir, '+generators');

                result = what(regions_dir);
                    
                BUILTIN_GENERATORS = containers.Map('KeyType', 'char','ValueType', 'any');
                
                for i=1:numel(result.m)
                    class_file = fullfile(regions_dir, result.m{i});
                    [~, class_name, ~] = fileparts(class_file);
                    class_type = ['geospm.models.generators.' class_name];

                    if exist(class_type, 'class')
                        identifier = join(lower(hdng.utilities.split_camelcase(class_name)), '_');
                        identifier = identifier{1};
                        BUILTIN_GENERATORS(identifier) = str2func(class_type);
                    end
                end
            end
            
            result = BUILTIN_GENERATORS;
        end
        
        
    end
    
end
