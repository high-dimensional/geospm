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

classdef DataLoader < handle
    %DataLoader Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = public)
        ignore_label_case
        
        ignore_n_lines_at_beginning
        have_names_row
        
        text_encoding
        
        missing_symbols % Cell array of missing value indicators
        true_symbols
        false_symbols
        case_sensitive_symbols
        
        exponent_character 
        decimal_separator
        thousands_separator
        
        csv_delimiter
    end
    
    
    properties (GetAccess = public, SetAccess = private)
        expected_columns
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
        expected_labels_
    end
    
    methods
        
        function obj = DataLoader()
            
            
            obj.ignore_n_lines_at_beginning = 0;
            obj.have_names_row = true;
        
            obj.text_encoding = 'UTF-8';
            
            obj.missing_symbols = { 'NaN', 'NULL' };
            
            obj.true_symbols = { 'true', 't' };
            obj.false_symbols = { 'false', 'f' };
            
            obj.case_sensitive_symbols = false;

            obj.exponent_character = 'E';
            obj.decimal_separator = '.';
            obj.thousands_separator = ',';
            
            obj.csv_delimiter = ',';

            obj.ignore_label_case = true;
            
            obj.expected_columns = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.expected_labels_ = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end
        
        function define_column(obj, label, position, is_real, is_integer, missing_value)
            
            if ~exist('missing_value', 'var')
                missing_value = missing();
            end
            
            column = obj.create_column_specifier(length(obj.expected_columns) + 1, label, position, is_real, is_integer, missing_value);
            obj.expected_columns(column.label) = column;
            
            label = lower(label);
            
            if ~isKey(obj.expected_labels_, label)
                obj.expected_labels_(label) = {};
            end
            
            obj.expected_labels_(label) = [obj.expected_labels_(label), {label}];
        end
        
        function [N_rows, expected_data, additional_columns] = load_from_file(obj, file_path)
            
            [~, ~, ext] = fileparts(file_path);
            
            if obj.have_names_row
                
                options = {};
                options{end + 1} = 'Range';
                options{end + 1} = [num2str(1 + obj.ignore_n_lines_at_beginning) ':' num2str(1 + obj.ignore_n_lines_at_beginning)];
                
                if ~isempty(obj.text_encoding)
                    options{end + 1} = 'Encoding';
                    options{end + 1} = obj.text_encoding;
                end
                
                options{end + 1} = 'DatetimeType';
                options{end + 1} = 'text';
                options{end + 1} = 'DurationType';
                options{end + 1} = 'text';
                
                variable_names = readcell(file_path, options{:});
                
                for i=1:numel(variable_names)
                    name = variable_names{i};
                    
                    if isnumeric(name)
                        name = num2str(name, '%d');
                    end
                    variable_names{i} = name;
                end
            
             else
                variable_names = {};
            end
            
            options = {};
            
            options{end + 1} = 'Range';
            
            first = 1 + obj.ignore_n_lines_at_beginning;
            
            options{end + 1} = first;
            
            options{end + 1} = 'ReadVariableNames';
            options{end + 1} = obj.have_names_row;
            
            if ~isempty(obj.text_encoding)
                options{end + 1} = 'Encoding';
                options{end + 1} = obj.text_encoding;
            end
            
            options{end + 1} = 'MissingRule';
            options{end + 1} = 'fill';
            options{end + 1} = 'ImportErrorRule';
            options{end + 1} = 'error';
            
            if strcmpi(ext, '.csv')
                options{end + 1} = 'Delimiter';
                options{end + 1} = obj.csv_delimiter;
            end
            
            opts = detectImportOptions(file_path, options{:});
            
            opts = setvartype(opts, 'char');
            opts = setvaropts(opts, 'TreatAsMissing', obj.missing_symbols);
            opts = setvaropts(opts, 'FillValue', missing);
            
            N_columns = numel(getvaropts(opts));
            
            file_cells = cell(1, N_columns);
            [file_cells{:}] = readvars(file_path, opts);
            
            N_rows = numel(file_cells{1});
            
            expected_data = cell(length(obj.expected_columns), 1);
            additional_columns = cell(size(file_cells, 2), 1);
            N_additional_columns = 0;
            
            for i=1:N_columns
                
                if ~isempty(variable_names)
                    label = variable_names{i};
                else
                    label = '';
                end
                
                if obj.ignore_label_case
                    label = lower(label);
                end
                
                column_data = file_cells{i};
                
                is_column_data_numeric = true;
                is_column_data_integer = true;
                is_column_data_boolean = true;
                
                missing_selector = zeros(N_rows, 1, 'logical');
                
                for k=1:N_rows
                    
                    value = column_data{k};
                    
                    missing_selector(k) = all(ismissing(value));
                    
                    if ~missing_selector(k)
                        
                        contains_decimal_point = contains(value, '.');
                        
                        if ~obj.case_sensitive_symbols
                            lowercase_value = lower(value);
                        else
                            lowercase_value = value;
                        end
                        
                        if any(strcmp(lowercase_value, obj.true_symbols))
                            value = '1';
                        elseif any(strcmp(lowercase_value, obj.false_symbols))
                            value = '0';
                        end
                        
                        double_value = str2double(value);
                        
                        if isnan(double_value)
                            is_column_data_numeric = false;
                            is_column_data_integer = false;
                            is_column_data_boolean = false;
                        else
                            value = double_value;
                            is_column_data_integer = is_column_data_integer && ~contains_decimal_point && cast(cast(value, 'int64'), 'double') == value;
                            is_column_data_boolean = is_column_data_boolean && is_column_data_integer && (value == 1 || value == 0);
                        end
                    end
                    
                    column_data{k} = value;
                end
                
                if is_column_data_numeric
                    column_data(missing_selector) = {NaN};
                end
                
                if isKey(obj.expected_labels_, label)
                    
                    columns = obj.expected_labels_(label);
                    
                    for j=1:numel(columns)
                        
                        column = columns{j};
                        
                        if column.position ~= 0 && column.position ~= i
                            continue
                        end
                        
                        if column.is_real || column.is_integer || column.is_boolean
                            column_data = cell2mat(column_data);
                        end
                        
                        if column.is_integer
                            column_data = cast(column_data, 'int64');
                        end
                        
                        if column.is_boolean
                            column_data = cast(column_data, 'logical');
                        end
                        
                        column_data{missing_selector} = column.missing_value;
                        expected_data{column.index} = column_data;
                    end
                else
                    N_additional_columns = N_additional_columns + 1;
                    
                    column = obj.create_column_specifier(i, label, i, false, false);
                    
                    if is_column_data_numeric
                        column_data = cell2mat(column_data);
                        column.is_real = true;
                    end
                    
                    if is_column_data_integer
                        column_data = cast(column_data, 'int64');
                        column.is_real = false;
                        column.is_integer = true;
                    end
                    
                    if is_column_data_boolean
                        column_data = cast(column_data, 'logical');
                        column.is_real = false;
                        column.is_integer = false;
                        column.is_boolean = true;
                    end
                    
                    column.data = column_data;
                    column.is_missing = missing_selector;
                    column.has_missing_values = any(missing_selector);
                    
                    additional_columns{N_additional_columns} = column;
                end
            end
                
            additional_columns = additional_columns(1:N_additional_columns);
        end
    end
    
    methods (Access = protected)
        
        function column = create_column_specifier(~, index, label, position, is_real, is_integer, missing_value)
            
            if ~exist('missing_value', 'var')
                missing_value = missing();
            end
            
            column = struct();
            column.index = index;
            column.label = label;
            column.position = position;
            column.is_real = is_real;
            column.is_integer = is_integer;
            column.is_boolean = false;
            column.missing_value = missing_value;
        end
        
    end
end
