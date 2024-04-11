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

classdef NumericData < geospm.TabularData
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
    
    properties (SetAccess = protected)
        
        labels % a column vector of length N (a N by 1 matrix) of labels
        categories % a column vector of length N (a N by 1 matrix) of categories
        variable_names % a row cell vector of length P (a 1 by P matrix) of variable names
    end
    
    properties (SetAccess = public)
        description
        attachments % a struct for holding arbitrary shared values
    end
    
    properties (Dependent, Transient)
        
        P % number of variables == number of columns
        
        mean % row vector ? mean of the data
        median
        covariance % covariance matrix of the data
    end
    
    properties (GetAccess = private, SetAccess = private)
        mean_
        median_
        covariance_
        variables_by_name_
    end
    
    methods

        function value = get.P(obj)
            value = obj.C;
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
            
            if ~exist('N', 'var') || isempty(N)
                N = size(observations, 1);
            end
            
            obj = obj@geospm.TabularData(N, size(observations, 2));
            
            obj.observations = observations;
            obj.did_check_for_nans = check_nans;
            obj.attachments = struct();
            obj.description = '';
            
            obj.covariance_ = [];
            
            obj.define_default_labels();
            obj.define_default_categories();
            obj.define_default_variable_names();
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
            
            result = obj.select([], [], ...
               @(specifier, modifier) obj.add_variables(specifier, modifier, index, variables, variable_names));
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
    
    methods (Access=protected)
        
        function assign_property(obj, name, values)
            obj.(name) = values;
        end

        function [specifier, modifier] = define_clone_specifier(obj)
            
            [specifier, modifier] = define_clone_specifier@geospm.TabularData(obj);
            
            specifier.data = obj.observations;
            
            specifier.per_column.variable_names = obj.variable_names;
            specifier.per_row.labels = obj.labels;
            specifier.per_row.categories = obj.categories;

            specifier.check_for_nans = obj.did_check_for_nans;
            
        end

        function result = create_clone_from_specifier(obj, specifier)
            
            result = geospm.NumericData(specifier.data, ...
                                        [], ...
                                        specifier.check_for_nans);
            
            result.set_variable_names(specifier.per_column.variable_names);
            result.set_labels(specifier.per_row.labels);
            result.set_categories(specifier.per_row.categories);

            result.description = obj.description;
        end

    end
    
    methods (Access = private)
        
        function specifier = add_variables(~, specifier, modifier, index, variables, variable_names)
            
            extra = struct();
            extra.variable_names = variable_names;
            
            specifier = modifier.insert_columns_op(specifier, index, variables, extra);
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
