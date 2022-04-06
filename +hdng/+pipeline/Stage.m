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

classdef Stage < handle
    
    properties (Constant)
        REQUIREMENTS_CATEGORY = 'requirements'
        PRODUCTS_CATEGORY = 'products'
    end
    
    properties
        name
    end
    
    properties (GetAccess=private, SetAccess=private)
        bindings_by_category
    end
    
    methods
        
        function obj = Stage()
            obj.name = '';
            obj.bindings_by_category = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end
        
        function result = bind(obj, category, role, nth_stage, acquire_variable)
            
            result = struct();

            group = obj.bindings_for_category(category);
            ids = fieldnames(group);
            N_bindings = numel(ids);
            
            for i=1:N_bindings
                
                identifier = ids{i};
                binding = group.(identifier);
                variable_name = binding.variable_name;
                variable = acquire_variable(variable_name);
                
                entry = struct();
                entry.binding = binding;
                entry.stage = obj;
                entry.nth_stage = nth_stage;
                
                variable.register_object(entry, role);
                
                result.(identifier) = variable;
            end
        end
        
        function result = bindings_for_category(obj, category)
            
            result = struct();
            
            if ~isKey(obj.bindings_by_category, category)
                return
            end
            
            result = obj.bindings_by_category(category);
        end
        
        function [did_exist, binding] = binding_for(obj, category, identifier)
            bindings = obj.bindings_for_category(category);
            
            binding = [];
            did_exist = isfield(bindings, identifier);
            
            if ~did_exist
                return
            end
            
            binding = bindings.(identifier);
        end
        
        function output_values = run(obj, input_values) %#ok<STOUT,INUSD>
            error('hdng.pipeline.Stage.run() must be implemented by a subclass.');
        end
        
        function [binding, options] = define_binding(obj, category, identifier, options, varargin)
            
            if ~exist('options', 'var')
                options = struct();
            end
            
            additional_options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            names = fieldnames(additional_options);
            
            for i=1:numel(names)
                option_name = names{i};
                
                options.(option_name) = additional_options.(option_name);
            end
            
            if ~isfield(options, 'is_optional')
                options.is_optional = false;
            end
            
            if ~isfield(options, 'variable_name')
                options.variable_name = identifier;
            end
            
            if ~isfield(options, 'default_value')
                options.default_value = [];
            end
            
            if ~isvarname(identifier)
                error(['Stage.define_interface_binding(): ''' identifier ''' is not a valid MATLAB identifier.']);
            end
            
            if ~isKey(obj.bindings_by_category, category)
                group = struct();
            else
                group = obj.bindings_by_category(category);
            end
            
            binding = hdng.pipeline.Binding(identifier, options.is_optional);
            
            group.(identifier) = binding;
            obj.bindings_by_category(category) = group;
            
            binding.set_variable_name(options.variable_name);
            binding.set_default_value(options.default_value);
        end
        
        function delete_binding(obj, category, identifier)
            
            if ~isKey(obj.bindings_by_category, category)
                return
            end
            
            group = obj.bindings_by_category(category);
            group = rmfield(group, identifier);
            
            if numel(fieldnames(group))
                remove(obj.bindings_by_category, category);
            else
                obj.bindings_by_category(category) = group;
            end
        end
        
    end
end
