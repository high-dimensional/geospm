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

classdef CSVLoader < handle
    %CSVLoader Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = public)
        ignore_label_case
        explicit_missing_value_symbol
        true_value_symbol
        false_value_symbol
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
        
        function obj = CSVLoader()
            obj.explicit_missing_value_symbol = [];
            obj.true_value_symbol = [];
            obj.false_value_symbol = [];
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
        
        function [N_rows, expected_data, additional_columns] = load_csv(obj, file_path)
        
            %Interpret the first line as a header
            header = readcell(file_path, 'Range', '1:1', 'DatetimeType', 'text', 'DurationType', 'text');
            
            file_cells = readcell(file_path, 'NumHeaderLines', 1, 'DatetimeType', 'text', 'DurationType', 'text');
            
            N_rows = size(file_cells, 1);
            
            expected_data = cell(length(obj.expected_columns), 1);
            additional_columns = cell(size(file_cells, 2), 1);
            N_additional_columns = 0;
            
            for i=1:numel(header)
                
                label = header{i};
                
                if obj.ignore_label_case
                    label = lower(label);
                end
                
                column_data = file_cells(:, i);
                
                is_column_data_numeric = true;
                is_column_data_integer = true;
                is_column_data_boolean = false;
                missing_selector = zeros(N_rows, 1, 'logical');
                
                for k=1:N_rows
                    value = column_data{k};

                    if strcmp(value, obj.explicit_missing_value_symbol)
                        value = missing;
                    elseif strcmp(value, obj.true_value_symbol)
                        value = 1;
                    elseif strcmp(value, obj.false_value_symbol)
                        value = 0;
                    end
                    
                    missing_selector(k) = ismissing(value);
                    
                    if ~missing_selector(k)
                        
                        contains_decimal_point = contains(value, '.');
                        value = str2double(value);
                        
                        if ~isnan(value)
                            is_column_data_numeric = false;
                        else
                            is_column_data_integer = is_column_data_integer && ~contains_decimal_point && cast(cast(value, 'int64'), 'double') == value;
                            is_column_data_boolean = is_column_data_integer && (value == 1 || value == 0);
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
                        
                        column_data{missing_selector} = column.missing_value;
                        
                        expected_data{column.index} = column_data;
                    end
                else
                    N_additional_columns = N_additional_columns + 1;
                    
                    column = obj.create_column_specifier(i, header{i}, i, false, false);
                    
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
                    
                    additional_columns{N_additional_columns} = column;
                end
                
                additional_columns = additional_columns(1:N_additional_columns);
            end
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
