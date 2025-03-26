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

classdef VariableSpecifier
    %VariableSpecifier Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = public)
        
        name_or_index_in_file
        rename_as
        label
        
        type
        load_type

        value_options
        
        role
        handlers
    end
    
    
    properties (GetAccess = public, SetAccess = private)
    end
    
    properties (Dependent, Transient)
        name_in_file
        index_in_file

        has_name
        has_index

        has_type
        has_load_type

        applicable_load_type
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function result = get.name_in_file(obj)
            
            result = '';

            if ischar(obj.name_or_index_in_file)
                result = obj.name_or_index_in_file;
            end
        end
        
        function result = get.index_in_file(obj)
            
            result = 0;

            if ~ischar(obj.name_or_index_in_file)
                result = cast(obj.name_or_index_in_file, 'double');
            end
        end
        
        function result = get.has_name(obj)
            
            result = ~isempty(obj.name_in_file);
        end
        
        function result = get.has_index(obj)
            
            result = obj.index_in_file ~= 0;
        end

        function result = get.has_type(obj)
            
            result = ~isempty(obj.type);
        end

        function result = get.has_load_type(obj)
            
            result = ~isempty(obj.load_type);
        end

        function result = get.applicable_load_type(obj)

            result = obj.type;

            if obj.has_load_type
                result = obj.load_type;
            end
        end

        function obj = VariableSpecifier(name_or_index_in_file, rename_as, ...
                label, type, load_type, value_options, role, handlers)
            
            if ~exist('rename_as', 'var')
                rename_as = '';
            end

            if ~exist('label', 'var')
                label = '';
            end

            if ~exist('type', 'var')
                type = 'double';
            end

            if ~exist('load_type', 'var')
                load_type = '';
            end

            if ~exist('value_options', 'var')
                value_options = hdng.utilities.ValueOptions.empty;
            end

            if ~exist('role', 'var')
                role = '';
            end

            if ~exist('handlers', 'var')
                handlers = {};
            end

            obj.name_or_index_in_file = name_or_index_in_file;
            obj.rename_as = rename_as;
            obj.label = label;
            obj.type = type;
            obj.load_type = load_type;
            obj.value_options = value_options;
            obj.role = role;
            obj.handlers = handlers;
        end

        function [index, resolved_name] = locate_in(obj, variable_names)
            
            index = 0;
            resolved_name = '';

            if isempty(variable_names) 
                if obj.has_index
                    index = obj.index_in_file;
                    resolved_name = obj.name_in_file;
                end
                return;
            end
            
            if obj.has_index && obj.index_in_file <= numel(variable_names)
                index = obj.index_in_file;
                resolved_name = variable_names{index};
            end

            if obj.has_name
                index = find(strcmp(obj.name_in_file, variable_names));

                if index ~= 0
                    resolved_name = variable_names{index};
                end
            end
        end

        function options = apply(obj, options, index, value_options_by_type)

            options = setvartype(options, index, obj.applicable_load_type);

            applicable_options = hdng.utilities.ValueOptions.empty;

            if isfield(value_options_by_type, obj.type)
                applicable_options = value_options_by_type.(obj.type);
            end

            applicable_options = applicable_options.override_with(obj.value_options);

            if ~isempty(applicable_options)
                options = applicable_options.apply(options, index);
            end
        end

        function variables = transform_variable(obj, variable)
            
            variables = variable;

            for index=1:numel(obj.handlers)
                handler = obj.handlers{index};
                
                tmp = struct.empty;

                for k=1:numel(variables)
                    out = handler(variables(k));
                    tmp = [tmp; out(:)]; %#ok<AGROW>
                end
                
                variables = tmp;
            end
        end

        function name = resolve_name(obj, default_name)

            if ~exist('default_name', '')
                default_name = '';
            end

            name = obj.name_in_file;
            
            if ~isempty(obj.rename_as)
                name = obj.rename_as;
            end

            if isempty(name)
                name = default_name;
            end
        end

        function label = resolve_label(obj, default_label)

            if ~exist('default_label', '')
                default_label = '';
            end
            
            label = obj.label;
            
            if isempty(label)
                label = obj.resolve_name();
            end

            if isempty(label)
                label = default_label;
            end
        end
    end

    methods (Static)
    

        function obj = from(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'name_or_index_in_file')
                options.name_or_index_in_file = [];
            end

            if ~isfield(options, 'rename_as')
                options.rename_as = '';
            end

            if ~isfield(options, 'type')
                options.type = 'double';
            end

            if ~isfield(options, 'load_type')
                options.load_type = '';
            end

            if ~isfield(options, 'value_options')
                options.value_options = hdng.utilities.ValueOptions.empty;
            end

            if ~isfield(options, 'role')
                options.role = '';
            end
            
            if ~isfield(options, 'label')
                options.label = '';
            end

            if ~isfield(options, 'handlers')
                options.handlers = {};
            end

            obj = hdng.utilities.VariableSpecifier( ...
                options.name_or_index_in_file, ...
                options.rename_as, ...
                options.label, ...
                options.type, ...
                options.load_type, ...
                options.value_options, ...
                options.role, ...
                options.handlers ...
            );
        end

        function variable = update_type_flags(variable)

            variable.is_char = isa(variable.data, 'char');
            variable.is_real = isa(variable.data, 'double');
            variable.is_boolean = isa(variable.data, 'logical');
            variable.is_integer = ...
                ~variable.is_char && ~variable.is_real && ~variable.is_boolean;
        end

    end
end
