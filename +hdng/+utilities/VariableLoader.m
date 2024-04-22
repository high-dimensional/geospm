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

classdef VariableLoader < handle
    %VariableLoader Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = public)

        ignore_label_case
        
        ignore_n_lines_at_beginning
        have_names_row

        skip_empty_lines
        
        text_encoding
        
        exponent_character 
        decimal_separator
        thousands_separator
        
        csv_delimiter

        value_options_by_type
    end
    
    methods
        
        function obj = VariableLoader()
            
            obj.ignore_n_lines_at_beginning = 0;
            obj.have_names_row = true;

            obj.skip_empty_lines = false;
        
            obj.text_encoding = 'UTF-8';

            obj.exponent_character = 'E';
            obj.decimal_separator = '.';
            obj.thousands_separator = ',';
            
            obj.csv_delimiter = ',';
            
            obj.ignore_label_case = true;

            obj.value_options_by_type = struct();
        end
        
        function  [N_rows, variables, specifier_selector] = load_from_file(obj, file_path, variable_specifiers)
            
            variables = {};
            import_args = obj.define_import_arguments(file_path);

            options = detectImportOptions(file_path, import_args{:});
            variable_names = options.VariableNames';

            specifier_selector = zeros(numel(variable_specifiers), 1, 'logical');
            selected_columns = zeros(numel(variable_specifiers), 1);
            num_selected_columns = 0;

            for index=1:numel(variable_specifiers)
                specifier = variable_specifiers(index);
                variable_index = specifier.locate_in(variable_names);
                specifier_selector(index) = variable_index ~= 0;

                if variable_index ~= 0
                    num_selected_columns = num_selected_columns + 1;
                    selected_columns(num_selected_columns) = variable_index;
                end
            end
            
            selected_columns = selected_columns(1:num_selected_columns);

            if isempty(selected_columns)
                return;
            end
            
            options.SelectedVariableNames = selected_columns;
            
            selected_specifiers = variable_specifiers(specifier_selector);

            options = obj.apply_options(options, selected_specifiers, selected_columns);
            
            columns = cell(1, num_selected_columns);
            [columns{:}] = readvars(file_path, options);
            
            options = obj.apply_raw_options(options, selected_specifiers, selected_columns);

            raw_columns = cell(1, num_selected_columns);
            [raw_columns{:}] = readvars(file_path, options);
            
            N_rows = numel(raw_columns{1});
            output_index = 1;

            for index=1:numel(raw_columns)
                raw_column = raw_columns{index};
                specifier = selected_specifiers(index);
                
                variable = struct();

                default_name = sprintf('Column-%d', selected_columns(index));
                variable.name = specifier.resolve_name(default_name);
                
                variable.data = columns{index};
                variable.type = specifier.type;
                variable.role = specifier.role;

                variable.is_char = isa(variable.data, 'char');
                variable.is_real = isa(variable.data, 'double');
                variable.is_boolean = isa(variable.data, 'logical');
                variable.is_integer = ~variable.is_char && ~variable.is_real && ~variable.is_boolean;
                variable.is_missing = obj.find_null_strings(raw_column);
                variable.has_missing_values = any(variable.is_missing);

                transformed = specifier.transform_variable(variable);
                
                for k=1:numel(transformed)
                    variables{output_index} = transformed(k); %#ok<AGROW>
                    output_index = output_index + 1;
                end
            end
            
        end
    end
    
    methods (Access = protected)

        function missing_selector = find_null_strings(~, raw_variable)
            missing_selector = strcmp(char(0), raw_variable);
        end

        function options = apply_options(obj, options, variables, variable_map)

            for index=1:numel(variables)
                variable_index = variable_map(index);
                variable = variables(index);

                options = variable.apply(options, variable_index, obj.value_options_by_type);
            end
        end

        function options = apply_raw_options(~, options, variables, variable_map)

            for index=1:numel(variables)
                variable_index = variable_map(index);
                variable = variables(index);

                missing_symbols = {''};

                if ~isempty(variable.value_options)
                    missing_symbols = variable.value_options.missing_symbols;
                end
                
                options = setvartype(options, variable_index, 'char');
                options = setvaropts(options, variable_index, 'TreatAsMissing', missing_symbols);
                options = setvaropts(options, variable_index, 'FillValue', char(0));
            end
        end
        
        function result = define_import_arguments(obj, file_path)

            [~, ~, ext] = fileparts(file_path);
            
            result = {};
            

            if obj.have_names_row
                result{end + 1} = 'VariableNamingRule';
                result{end + 1} = 'preserve';
            end

            result{end + 1} = 'Range';
            first = 1 + obj.ignore_n_lines_at_beginning;
            result{end + 1} = first;
            
            result{end + 1} = 'ReadVariableNames';
            result{end + 1} = obj.have_names_row;
            
            if ~isempty(obj.text_encoding)
                result{end + 1} = 'Encoding';
                result{end + 1} = obj.text_encoding;
            end
            
            result{end + 1} = 'EmptyLineRule';
            
            if obj.skip_empty_lines
                result{end + 1} = 'skip';
            else
                result{end + 1} = 'read';
            end


            result{end + 1} = 'MissingRule';
            result{end + 1} = 'fill';

            result{end + 1} = 'ImportErrorRule';
            result{end + 1} = 'error';
            
            if strcmpi(ext, '.csv')
                result{end + 1} = 'Delimiter';
                result{end + 1} = obj.csv_delimiter;
            end
        end
    end
end
