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
        
        type
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

        function obj = VariableSpecifier(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'name_or_index_in_file')
                options.name_or_index_in_file = [];
            end

            if ~isfield(options, 'rename_as')
                options.rename_as = '';
            end

            if ~isfield(options, 'type')
                options.type = 'char';
            end

            if ~isfield(options, 'value_options')
                options.value_options = hdng.utilities.ValueOptions.empty;
            end

            if ~isfield(options, 'role')
                options.role = '';
            end

            if ~isfield(options, 'handlers')
                options.handlers = {};
            end

            obj.name_or_index_in_file = options.name_or_index_in_file;
            obj.rename_as = options.rename_as;
            obj.type = options.type;
            obj.value_options = options.value_options;
            obj.role = options.role;
            obj.handlers = options.handlers;
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

            options = setvartype(options, index, obj.type);

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

                %variable = handler(variable);

                variables = tmp;
            end
        end

        function name = resolve_name(obj, default_name)

            name = obj.name_in_file;
            
            if ~isempty(obj.rename_as)
                name = obj.rename_as;
            end

            if isempty(name)
                name = default_name;
            end
        end
    end
end
