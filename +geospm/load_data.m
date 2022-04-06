% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2020,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function result = load_data(file_path, varargin)
    
    %{
        include
        exclude
        crs_identifier
        eastings_label
        northings_label
        csv_delimiter
        row_identifier_index
        row_identifier_label
        add_constant
        mask_rows_with_missing_values
        mask_columns_with_missing_values
    %}

    [options, unused_options] = geospm.auxiliary.parse_load_options(varargin{:});
    
    unused_options = join(fieldnames(unused_options), ', ');
    unused_options = unused_options{1};
    
    if ~isempty(unused_options)
        error('geospm.load_data(): Unknown options: %s', unused_options);
    end
    
    if numel(options.include) ~= 0 ...
       && numel(options.exclude) ~= 0
        error(['geospm.load_data(): Include and exclude options'...
               ' cannot be specified at the same time.']);
    end
    
    include = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    exclude = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    
    for i=1:numel(options.include)
        include(lower(options.include{i})) = 1;
    end
    
    for i=1:numel(options.exclude)
        exclude(lower(options.exclude{i})) = 1;
    end
    
    loader = hdng.utilities.DataLoader();
    loader.csv_delimiter = options.csv_delimiter;
    
    [N_rows, ~, additional_columns] = loader.load_from_file(file_path);
    
    [directory, basename, ~] = fileparts(file_path);
    projection_path = fullfile(directory, [basename '.prj']);
    
    if numel(options.crs_identifier) ~= 0
        crs_or_crs_identifier = options.crs_identifier;
    elseif isfile(projection_path)
        crs_or_crs_identifier = hdng.SpatialCRS.from_file(projection_path);
    else
        crs_or_crs_identifier = hdng.SpatialCRS.empty;
        warning(['geospm.load_data(): No CRS identifier was explicitly'...
                 ' specified ' newline 'and there appears to be no' ...
                 ' auxiliary ''' basename '.prj'' file.']); 
    end
    
        
    if isfield(options, 'row_identifier_label' )

        for i=1:numel(additional_columns)
            column = additional_columns{i};

            if strcmp(column.identifier, options.row_identifier_label)
                options.row_identifier_index = i;
                break;
            end
        end
    end

    if isfield(options, 'row_identifier_index' )
        
        if ~isempty(options.row_identifier_index) && ...
           options.row_identifier_index >= 1 && ...
           options.row_identifier_index <= numel(additional_columns)

            eid = additional_columns{options.row_identifier_index};
            variable_columns = [additional_columns(1:options.row_identifier_index - 1) ...
                                additional_columns(options.row_identifier_index + 1:end)];
        else
            options = rmfield(options, 'row_identifier_index');
        end
    end
    
    if ~isfield(options, 'row_identifier_index') && ~isfield(options, 'row_identifier_label')
        eid = struct();
        eid.data = (1:N_rows)';
        variable_columns = additional_columns;
    end
    
    variable_names = cell(numel(variable_columns), 1);
    variable_types = cell(numel(variable_columns), 1);
    
    variable_matrix = zeros(N_rows, numel(variable_columns));
    not_missing = zeros(1, numel(variable_columns) ,'logical');
    missing_values_matrix = zeros(N_rows, numel(variable_columns) ,'logical');
    
    index = 1;
    x = [];
    y = [];
    
    rows_without_location = zeros(N_rows, 1, 'logical');
    
    for i=1:numel(variable_columns)
        column = variable_columns{i};
        
        if ~isempty(include) && ~isKey(include, lower(column.label))
            continue;
        end
        
        if ~isempty(exclude) && isKey(exclude, lower(column.label))
            continue;
        end
        
        if strcmpi(column.label, options.eastings_label)
            x = cast(column.data, 'double');
            rows_without_location = bitor(rows_without_location, column.is_missing);
            continue;
        end
        
        if strcmpi(column.label, options.northings_label)
            y = cast(column.data, 'double');
            rows_without_location = bitor(rows_without_location, column.is_missing);
            continue;
        end
        
        not_missing(index) = ~column.has_missing_values;
        missing_values_matrix(:, index) = column.is_missing;
        variable_matrix(:, index) = column.data;
        variable_matrix(column.is_missing, index) = NaN;
        variable_names{index} = column.label;
        
        if column.is_boolean
            variable_types{index} = 'logical';
        elseif column.is_integer
            variable_types{index} = 'int64';
        elseif column.is_real
            variable_types{index} = 'double';
        else
            variable_types{index} = 'char';
        end
        
        index = index + 1;
    end
    
    selected_rows = ~rows_without_location;
    
    variable_matrix = variable_matrix(:, 1:index - 1);
    variable_names = variable_names(1:index - 1);
    variable_types = variable_types(1:index - 1);
    not_missing = not_missing(1:index - 1);
    
    variable_matrix = variable_matrix(selected_rows, :);
    x = x(selected_rows);
    y = y(selected_rows);
    
    if options.mask_columns_with_missing_values
        variable_matrix = variable_matrix(:, not_missing);
        variable_names = variable_names(not_missing);
        variable_types = variable_types(not_missing);
        missing_values_matrix = missing_values_matrix(:, not_missing);
    end
    
    if ~options.mask_columns_with_missing_values && options.mask_rows_with_missing_values
        
        complete_rows = sum(missing_values_matrix, 2) == 0;
        
        variable_matrix = variable_matrix(complete_rows, :);
        missing_values_matrix = missing_values_matrix(complete_rows, :);
        
        x = x(complete_rows);
        y = y(complete_rows);
        
        selected_rows = bitand(selected_rows, complete_rows);
    end
    
    if options.add_constant
        variable_matrix = [ones(size(variable_matrix, 1), 1), variable_matrix];
        variable_names = ['constant'; variable_names];
        variable_types = ['int64'; variable_types];
    end
    
    result = geospm.SpatialData(x, y, [], variable_matrix, crs_or_crs_identifier, ...
               options.mask_columns_with_missing_values || ...
               options.mask_rows_with_missing_values);
    
    result.set_variable_names(variable_names');
    
    label_chars = num2str(eid.data(selected_rows), '%d');
    labels = cell(size(label_chars, 1), 1);
    
    for i=1:numel(labels)
        labels{i} = label_chars(i, :);
    end
    
    result.set_labels(labels);
    result.attachments.missing_values = missing_values_matrix;
    result.attachments.variable_types = variable_types;
end
