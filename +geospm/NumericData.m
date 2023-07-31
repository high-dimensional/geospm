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

classdef NumericData < handle
    %NumericData Holds observations originating from a set of quantative variables.
    %
    %   The N numeric observations of P variables are stored in a N by P matrix.
    %
    %   Additional metadata can be defined optionally, such as observation
    %   labels, numeric categories and variable names.
    %
    
    properties (SetAccess = immutable)
        
        observations % a N by P matrix of observations, each row corresponds to a joint observation of the variables. 
        did_check_for_nans
    end
    
    properties (SetAccess = private)
        
        labels % a column vector of length N (a N by 1 matrix) of labels
        categories % a column vector of length N (a N by 1 matrix) of categories
        variable_names % a row cell vector of length P (a 1 by P matrix) of variable names
    end
    
    properties (SetAccess = public)
        description
        attachments % a struct for holding arbitrary shared values
    end
    
    properties (Dependent, Transient)
        
        N % number of observations
        P % number of variables
        
        mean % row vector ? mean of the data
        median
        covariance % covariance matrix of the data
    end
    
    properties (GetAccess = private, SetAccess = private)
        N_
        mean_
        median_
        covariance_
        variables_by_name_
    end
    
    methods
        
        function value = get.N(obj)
            value = obj.N_;
        end
        
        function value = get.P(obj)
            value = size(obj.observations, 2);
        end
        
        
        function result = get.mean(obj)
            
            if isempty(obj.mean_)
            	obj.mean_ = mean(obj.observations, 'omitnan'); %#ok<CPROP>
            end
            
            result = obj.mean_;
        end
        
        
        function result = get.median(obj)
            
            if isempty(obj.median_)
            	obj.median_ = median(obj.observations, 'omitnan'); %#ok<CPROP>
            end
            
            result = obj.median_;
        end
        
        
        function result = get.covariance(obj)
            
            if isempty(obj.covariance_)
                obj.covariance_ = cov(obj.observations);
            end
            
            result = obj.covariance_;
        end
        
        
        function obj = NumericData(observations, N, check_nans)
            %Construct a NumericData object from a matrix of observations.
            % observations ? A matrix which is checked for NaN values, which will cause an error to be thrown. 
            
            if ~ismatrix(observations)
                error('''observations'' is not a numeric value; specify ''observations'' as a N x P matrix');
            end
            
            if ~exist('check_nans', 'var')
                check_nans = true;
            end
            
            if check_nans
                [has_nans, message] = hdng.utilities.check_for_NaNs(observations, 'observations');

                if has_nans
                    error(message);
                end
            end
            
            if ~exist('N', 'var')
                N = size(observations, 1);
            end
            
            obj.N_ = N;
            
            obj.observations = observations;
            obj.did_check_for_nans = check_nans;
            obj.attachments = struct();
            obj.description = '';
            
            obj.covariance_ = [];
            
            obj.define_default_labels();
            obj.define_default_categories();
            obj.define_default_variable_names();
        end
        
        function result = count_observations(obj)
            result = size(obj.observations, 1);
        end
        
        function index_or_zero = index_for_variable_name(obj, name)
            %Returns the number of the column in the observations matrix for the variable with the given name.
            % Zero is returned if no variable with the given name exists.
            
            if ~isKey(obj.variables_by_name_, name)
                index_or_zero = 0;
                return
            end
            
            index_or_zero = obj.variables_by_name_(name);
        end
        
        function set_variable_names(obj, new_names)
            %Sets the names of all P variables.
            % names is a cell array of character vectors.
            
            if ~iscell(new_names) || size(new_names, 2) ~= obj.P
                error('''variable_names'' requires a 1 x P cell array');
            end
            
            obj.variable_names = new_names;
            obj.variables_by_name_ = containers.Map('KeyType', 'char','ValueType', 'int32');
            
            for i=1:numel(obj.variable_names)
                name = obj.variable_names{i};
                obj.variables_by_name_(name) = i;
            end
        end
        
        function set_labels(obj, new_labels)
            %Sets the values for all N observation labels.
            % labels is a cell array of label values.
            
            if (~iscell(new_labels)) || size(new_labels, 1) ~= obj.N
                error('''labels'' requires a N x 1 cell array.');
            end
            
            obj.labels = new_labels;
        end
        
        function set_categories(obj, new_categories)
            %Sets the categories for all N observations.
            % new_categories is an array of numeric values.
            
            if (~isnumeric(new_categories)) || size(new_categories, 1) ~= obj.N
                error('''categories'' requires a N x 1 vector.');
            end
            
            obj.categories = new_categories;
        end
        
        function result = row_attachments(obj, row_selection)
            
            if ~exist('row_selection', 'var')
                row_selection = ones(obj.N, 1, 'logical');
            end
            
            result = struct();
            result.labels = obj.labels(row_selection);
            result.categories = obj.categories(row_selection);
        end
        
        function result = column_attachments(obj, column_selection)
            
            if ~exist('column_selection', 'var')
                column_selection = ones(1, obj.P, 'logical');
            end
            
            result = struct();
            result.variable_names = obj.variable_names(column_selection);
        end
        
        function assign_row_attachment_impl(obj, name, from, row_map)
            
            
            K = numel(row_map);
            M = size(obj.(name), 1);
            
            if M < K
                to_values = obj.(name);
                obj.(name) = [to_values(1:M); cell(K - M, 1)];
            end
            
            assign_rows = find(row_map ~= 0);
            from_rows = row_map(assign_rows);
            
            from_values = from.(name);
            from_values = from_values(from_rows, :);
            
            to_values = obj.(name);
            to_values(assign_rows, :) = from_values;
            obj.(name) = to_values;
        end
        
        function assign_row_attachments(obj, from, row_selection, row_map)
            
            % assign_row_attachments  Assign selected row attachments of from to this object using the row map
            %   from - a data object from which row attachments are to be assigned
            %   row_selection - a logical vector of rows or a numeric vector of row indices in from
            %   row_map - a vector of row indices: each entry maps a row in this object to a position in the row selection of from
            
            if ~exist('row_selection', 'var')
                row_selection = ones(from.N, 1, 'logical');
            end
            
            if ~exist('row_map', 'var') || isempty(row_map)
                row_indices = 1:from.N;
                %row_indices = row_indices(row_selection);
                %row_map = 1:numel(row_indices);
                row_map = row_indices(row_selection);
            end
            
            %row_attachments = from.row_attachments(row_selection);
            row_attachments = from.row_attachments;
            
            if isfield(row_attachments, 'labels')
                obj.assign_row_attachment_impl('labels', row_attachments, row_map);
            end
            
            if isfield(row_attachments, 'categories')
                obj.assign_row_attachment_impl('categories', row_attachments, row_map);
            end
        end
        
        function assign_column_attachment_impl(obj, name, from, column_map)
            
            K = numel(column_map);
            M = size(obj.(name), 2);
            
            if M < K
                to_values = obj.(name);
                obj.(name) = [to_values(1:M), cell(1, K - M)];
            end
            
            assign_columns = find(column_map ~= 0);
            from_columns = column_map(assign_columns);
            
            from_values = from.(name);
            from_values = from_values(:, from_columns);
            
            to_values = obj.(name);
            to_values(:, assign_columns) = from_values;
            obj.(name) = to_values;
        end
        
        
        function assign_column_attachments(obj, from, column_selection, column_map)
            % assign_column_attachments  Assign selected column attachments of from to this object using the column map
            %   from - a data object from which column attachments are to be assigned
            %   column_selection - a logical vector of columns or a numeric vector of column indices in from
            %   column_map - a vector of column indices: each entry maps a column in this object to a position in the column selection of from
            
            if ~exist('column_selection', 'var')
                column_selection = ones(1, obj.P, 'logical');
            end
            
            if ~exist('column_map', 'var') || isempty(column_map)
                column_indices = 1:obj.P;
                column_indices = column_indices(column_selection);
                column_map = 1:numel(column_indices);
            end
            
            column_attachments = from.column_attachments(column_selection);
            
            if isfield(column_attachments, 'variable_names')
                obj.assign_column_attachment_impl('variable_names', column_attachments, column_map);
            end
        end
        
        function assign_attachments(obj, from, row_selection, column_selection, row_map, column_map)
            
            if ~exist('row_selection', 'var') || isempty(row_selection)
                row_selection = ones(obj.N, 1, 'logical');
            end
            
            if ~exist('column_selection', 'var') || isempty(column_selection)
                column_selection = ones(1, obj.P, 'logical');
            end
            
            if ~exist('row_map', 'var')
                row_map = 1:numel(row_selection);
            end
            
            if ~exist('column_map', 'var')
                column_map = 1:numel(column_selection);
            end
            
            obj.assign_row_attachments(from, row_selection, row_map);
            obj.assign_column_attachments(from, column_selection, column_map);
        end
        
        function result = concat_variables(obj, variables, variable_names, index)
            
            if ~exist('variable_names', 'var') || isempty(variable_names)
                variable_names = cell(1, size(variables, 2));
            end
            
            if ~exist('index', 'var')
                index = obj.P + 1;
            end
            
            if index > (obj.P + 1) || index <= 0
                error('NumericData.concat_variables(): Invalid index: %d.', index);
            end
            
            row_selection = 1:obj.N;
            column_selection = 1:obj.P;
            
            [result, row_map, column_map] = obj.clone_impl(row_selection, ...
                column_selection, ...
                @(args) obj.add_variables(args, index, variables, variable_names));
            
            result.assign_row_attachments(obj, row_selection, row_map);
            result.assign_column_attachments(obj, column_selection, column_map);
        end
        
        function result = select(obj, row_selection, column_selection, transform)
        
            if ~exist('row_selection', 'var')
                row_selection = [];
            end
            
            if isempty(row_selection)
                row_selection = 1:obj.N;
            end
            
            if ~exist('column_selection', 'var')
                column_selection = [];
            end
            
            if isempty(column_selection)
                column_selection = 1:obj.P;
            end
            
            if ~exist('transform', 'var')
                transform = @(arguments) arguments;
            end
            
            [row_selection, column_selection] = obj.normalise_selection(row_selection, column_selection);
            
            [result, row_map, column_map] = obj.clone_impl(row_selection, column_selection, transform);
            
            result.assign_row_attachments(obj, row_selection, row_map);
            result.assign_column_attachments(obj, column_selection, column_map);
        end
        

        function result = identify_constant_variables(obj, minimum_stddev)
            
            if ~exist('minimum_stddev', 'var')
                minimum_stddev = 0.0;
            end
            
            stddev = std(obj.observations, 0, 1);
            
            result = stddev < minimum_stddev;
        end
        
        function result = format_variable_names(obj, selection, separator, prefix)
            
            if ~exist('separator', 'var') || isempty(separator)
                separator = newline;
            end
            
            if ~exist('prefix', 'var') || isempty(prefix)
                prefix = '';
            end
            
            j = [separator prefix];
            result = j.join(obj.variable_names(selection));
            
            if ~isempty(result)
                result = [prefix result];
            end
            
        end
        
        function result = filter_constant_variables(obj, minimum_stddev, always_create_clone)
            
            if ~exist('minimum_stddev', 'var')
                minimum_stddev = 0.0;
            end
            
            if ~exist('always_create_clone', 'var')
                always_create_clone = true;
            end
            
            constant = obj.identify_constant_variables(minimum_stddev);
            
            if ~always_create_clone && sum(constant) == 0
                result = obj;
            else
                result = obj.select([], ~constant);
            end
        end
        
        function result = as_json_struct(obj, options)
            %Creates a JSON representation of this NumericData object.
            % The following fields can be provided in the options
            % argument:
            % include_categories ? Indicates whether a field named
            % 'categories' should be created in the JSON record.
            % include_labels ? Indicates whether a field named
            % 'labels' shoudl be created in the JSON record.
            
            if ~exist('options', 'var')
                options = struct();
            end
            
            if ~isfield(options, 'include_categories')
                options.include_categories = true;
            end
            
            if ~isfield(options, 'include_labels')
                options.include_labels = true;
            end
            
            if ~isfield(options, 'categories_name')
                options.categories_name = 'categories';
            end
            
            if ~isfield(options, 'labels_name')
                options.labels_name = 'labels';
            end
            
            specifier = struct();
            
            specifier.N = obj.N;
            specifier.P = obj.P;
            specifier.observations = obj.observations;
            
            if options.include_labels
                specifier.(options.labels_name) = obj.labels;
            end
            
            if options.include_categories
                specifier.(options.categories_name) = obj.categories;
            end
            
            specifier.variable_names = obj.variable_names';
            
            result = specifier;
        end
        
        function write_as_json(obj, filepath, options)
            %Writes a JSON representation of this NumericData object to a file.
            % The range of possible options is documented at the as_json_struct() method.
            
            if ~exist('options', 'var')
                options = struct();
            end
            
            json = obj.as_json_struct(options);
            
            [dir, name, ext] = fileparts(filepath);
            
            if ~strcmpi(ext, '.json')
                filepath = fullfile(dir, [name, '.json']);
            end
            
            json = jsonencode(json);
            hdng.utilities.save_text(json, filepath);
        end
        
        function result = as_table(obj, options)
            
            %Creates a Matlab Table object for this NumericData object.
            % The following fields can be provided in the options
            % argument:
            % include_categories ? Indicates whether a field named
            % 'categories' should be created in the table.
            % include_labels ? Indicates whether a field named
            % 'labels' shoudl be created in the table.
            
            if ~exist('options', 'var')
                options = struct();
            end
            
            if ~isfield(options, 'include_categories')
                options.include_categories = true;
            end
            
            if ~isfield(options, 'include_labels')
                options.include_labels = true;
            end
            
            if ~isfield(options, 'categories_name')
                options.categories_name = 'categories';
            end
            
            if ~isfield(options, 'labels_name')
                options.labels_name = 'labels';
            end
            
            N_cols = 0;
            col_names = [];
            p = {};
            
            if options.include_categories
                p = [p class(obj.categories)];
                N_cols = N_cols + 1;
                col_names = [col_names {options.categories_name}];
            end
            
            if options.include_labels
                p = [p class(obj.labels)];
                N_cols = N_cols + 1;
                col_names = [col_names {options.labels_name}];
            end
            
            p = [p repelem({class(obj.observations)}, obj.P)];
            
            N_cols = N_cols + obj.P;
            col_names = [col_names obj.variable_names];
            
            result = table('Size', [obj.N, N_cols], 'VariableTypes', p);
            result.Properties.VariableNames = col_names;
            
            if options.include_categories
                result.categories = obj.categories;
            end
            
            if options.include_labels
                result.labels = obj.labels;
            end
            
            result{:, N_cols + 1 - obj.P:end} = obj.observations;
        end
        
        function write_as_xls(obj, filepath, options)
            %The contents of this NumericData object are written to a Microsoft Excel file.
            % The range of possible options is documented at the as_table() method.
            
            if ~exist('options', 'var')
                options = struct();
            end
            
            data = obj.as_table(options);
            
            [dir, name, ext] = fileparts(filepath);
            
            if ~strcmpi(ext, '.xls')
                filepath = fullfile(dir, [name, '.xls']);
            end
            
            writetable(data, filepath);
        end
        
        function write_as_csv(obj, filepath, options)
            %The contents of this NumericData object are written to a Comma Separated Values (CSV) file.
            % The range of possible options is documented at the as_table() method.
            
            if ~exist('options', 'var')
                options = struct();
            end
            
            data = obj.as_table(options);
            
            [dir, name, ext] = fileparts(filepath);
            
            if ~strcmpi(ext, '.csv')
                filepath = fullfile(dir, [name, '.csv']);
            end
            
            writetable(data, filepath);
        end
    end
    
    methods (Access = protected)
        
        
        function [row_selection, column_selection] = normalise_selection(obj, row_selection, column_selection)
        
            if ~exist('column_selection', 'var') || isempty(column_selection)
                column_selection = 1:obj.P;
            end
            
            if ~exist('row_selection', 'var') || isempty(row_selection)
                row_selection = 1:obj.N;
            end
            
            if ~isnumeric(row_selection)
                
                if islogical(row_selection)
                    if numel(row_selection) ~= obj.N
                        error('NumericData.normalise_selection(): The length of a logical row selection vector must be equal to the number of observations.');
                    end
                else
                    error('NumericData.normalise_selection(): row selection vector must be a numeric or logical array.');
                end
            else
                row_selection = row_selection(:);

                try
                    tmp = (1:obj.N)';
                    tmp = tmp(row_selection); %#ok<NASGU>
                    clear('tmp');
                catch
                    error('NumericData.normalise_selection(): One or more row selection indices are out of bounds.');
                end
            end
            
            
            if ~isnumeric(column_selection)
                
                if islogical(column_selection)
                    if numel(column_selection) ~= obj.P
                        error('NumericData.normalise_selection(): The length of a logical column selection vector must be equal to the number of variables.');
                    end
                else
                    error('NumericData.normalise_selection(): column selection vector must be a numeric or logical array.');
                end
            else
                column_selection = column_selection(:)';

                try
                    tmp = 1:obj.P;
                    tmp = tmp(column_selection); %#ok<NASGU>
                    clear('tmp');
                catch
                    error('NumericData.select(): One or more column selection indices are out of bounds.');
                end
            end
        end
    end
    
    methods (Access=protected)
        
        function result = apply_transform(~, arguments, transform)
            
            result = transform(arguments);
            
            names = fieldnames(arguments);
            
            for i=1:numel(names)
                
                name = names{i};
                
                if isfield(result, name)
                    continue;
                end
                
                result.(name) = arguments.(name);
            end
            
        end
        
        function [row_map, column_map] = clone_maps_from_selection(obj, row_selection, column_selection)
            
            row_indices = 1:obj.N;
            column_indices = 1:obj.P;
            
            row_indices = row_indices(row_selection);
            column_indices = column_indices(column_selection);
            
            row_map = 1:numel(row_indices);
            column_map = 1:numel(column_indices);
        end
        
        function [result, row_map, column_map] = clone_impl(obj, row_selection, column_selection, transform)
            % clone_impl  Clone this data object using the selected rows, columns and transform.
            %   row_selection - a logical vector of rows or a numeric vector of row indices
            %   column_selection - a logical vector of columns or a numeric vector of column indices
            %   transform - a function handle that expects an argument struct and returns a result struct
            %
            %   The transform function is passed a struct with the
            %   following fields:
            %
            %   observations - a numeric matrix of the selected observations
            %   variable_names - a cell array of variable names
            %   check_for_nans - a logical value that indicates if a nan check should be applied when creating the cloned object.
            %   row_map - a vector of row indices: each entry maps a row in the cloned object to a position in the row selection
            %   column_map - a vector of column indices: each entry maps a column in the cloned object to a position in the column selection
            %
            %   A zero index in either the row or column map specified that
            %   the corresponding row or column in the cloned object keeps
            %   its previous attachment
            
            selected_observations = [];
            
            if ~isempty(row_selection) && ~isempty(column_selection)
                selected_observations = obj.observations(row_selection, column_selection);
            end
            
            arguments = struct();
            arguments.observations = selected_observations;
            arguments.variable_names = obj.variable_names(column_selection);
            arguments.check_for_nans = obj.did_check_for_nans;
            
            [arguments.row_map, arguments.column_map] = obj.clone_maps_from_selection(row_selection, column_selection);
            
            arguments = obj.apply_transform(arguments, transform);
            
            result = geospm.NumericData(arguments.observations, ...
                                      size(arguments.observations, 1), ...
                                      arguments.check_for_nans);
            
            result.description = obj.description;
            result.set_variable_names(arguments.variable_names);
            
            row_map = arguments.row_map;
            column_map = arguments.column_map;
        end
    end
    
    methods (Access = private)
        
        function args = add_variables(~, args, index, variables, variable_names)
            
            args.observations = [args.observations(:, 1:index - 1), ...
                                 variables, ...
                                 args.observations(:, index:end)];
             
            args.variable_names = [args.variable_names(1:index - 1), ...
                                   variable_names, ...
                                   args.variable_names(index:end)];
            
            args.column_map = [args.column_map(1:index - 1), ...
                               0, ...
                               args.column_map(index:end)];
        end
        
        function define_default_categories(obj)
            
            obj.categories = zeros(obj.N, 1, 'int64');

            for i=1:obj.N
                obj.categories(i,1) = i;
            end
        end
        
        function define_default_labels(obj)
            
            obj.labels = cell(obj.N, 1);

            for i=1:obj.N
                obj.labels{i,1} = num2str(i);
            end
        end
        
        function define_default_variable_names(obj)
            
            obj.variable_names = cell(1, obj.P);

            for i=1:obj.P
                obj.variable_names{1, i} = strcat('variable_', num2str(i));
            end
            
            obj.variables_by_name_ = containers.Map('KeyType', 'char','ValueType', 'int32');
            
            for i=1:numel(obj.variable_names)
                name = obj.variable_names{i};
                obj.variables_by_name_(name) = i;
            end
        end
    end
end
