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

function [result, spatial_index] = load_spatial_data(file_path, varargin)
    %{
        Creates geospm.NumericData and geospm.SpatialIndex objects 
        from a CSV file.

        The following name-value arguments are supported:
        
        -------------------------------------------------------------------
        
        -- General --

        csv_delimiter – The field delimiter character of the CSV file.
        Defaults to ',' (comma).

        -- Coordinates --
        
        crs_identifier – An identifier for a coordinate reference system,
        for example: 'EPSG:27700' If this parameter is not specified and
        no '.prj' sidecar file can be found, a warning will be generated.

        spatial_index_file – The name of a separate file storing the 
        coordinates. If empty or not specified, the coordinates are stored 
        in the same file as the data. Supported formats are either a CSV
        file or a Matlab file produced by SpatialIndex.write_matlab().
        
        x_coordinate – The name of the column that holds the x
        or eastings values of the point data. Defaults to 'x'. Not used if
        the spatial index is in MATLAB format.

        y_coordinate – The name of the column that holds the y
        or northings values of the point data. Defaults to 'y'. Not used if
        the spatial index is in MATLAB format.

        z_coordinate – Optional. The name of the column that holds the z
        values of the point data. Defaults to '', meaning no z coordinate
        is defined. Not used if the spatial index is in MATLAB format.
        
        The following arguments are only relevant if the coordinates are 
        stored in a separate CSV file:

        segment_label – The name of the column whose values uniquely
        identify the segment number an observation belongs to, if 
        coordinates are stored in a separate CSV file. Takes precedence 
        over segment_index.

        segment_index – The index of the column whose values
        identify the segment number an observation belongs to, if 
        coordinates are stored in a separate CSV file. Overridden by 
        segment_label.
        
        -- Data --
        
        variables - An array of hdng.utilities.VariableSpecifiers.

        The following roles are recognised:
        
            '' – default, data
            
            'row_label' – use column as row labels. If not defined for
            any column, the index of each row will be used.

            'segment_number' – use column as segment number. If defined,
            rows will be re-ordered by segment number.
            
        
        value_options_by_type – A struct whose fields are type names providing
        default hdng.utilitiesValueOptions for variables of the
        corresponding type.
        
        skip_rows_with_missing_values – Ignore rows with missing values.
        Defaults to true.

        skip_columns_with_missing_values – Ignore columns with missing
        values. Defaults to true.

        map_variables – A cell array with 2 columns. The first column
        specifies a variable name, the second column specifies a handler
        function, that transforms the data for that variable:
        
        handler(variable, index)

        Also see geospm.auxiliary.parse_spatial_load_options().
    %}

    [options, unused_options] = geospm.auxiliary.parse_spatial_load_options(varargin{:});
    assert_no_unused_options(unused_options);

    spatial_index = [];
    spatial_variables = [];

    if ~isempty(options.spatial_index_file)
        
        [spatial_index_path, ~] = normalise_spatial_index_path(options.spatial_index_file, file_path);
        
        spatial_index = geospm.load_spatial_index(spatial_index_path, varargin{:});
        crs_or_crs_identifier = spatial_index.crs;
    else
        spatial_variables = define_spatial_variables(options);
        crs_or_crs_identifier = get_crs(options, file_path);
    end
    
    loader = hdng.utilities.VariableLoader();
    
    loader.csv_delimiter = options.csv_delimiter;
    loader.value_options_by_type = options.value_options_by_type;
    
    [N_rows, variables, selected_specifiers] = ...
        loader.load_from_file( ...
            file_path, [spatial_variables(:); options.variables(:)]);
    

    role_map = create_role_map(variables);

    row_labels = define_row_labels(variables, N_rows, role_map);
    
    N_spatial_variables = numel(spatial_variables);

    if N_spatial_variables > 0
        N_selected_spatial_variables = sum(selected_specifiers(1:N_spatial_variables));
    
        if N_selected_spatial_variables ~= N_spatial_variables
            [~, file_name, ext] = fileparts(file_path);
            file_name = [file_name, ext];
            error('Some coordinate columns are unavailable in ''%s''.', file_name);
        end
    
        spatial_variables = variables(1:N_spatial_variables);
        spatial_index = create_spatial_index_from_variables(spatial_variables, crs_or_crs_identifier, row_labels);
    end
    
    if ~isKey(role_map, '')
        error('No data variables defined.');
    end
    
    data_variables = variables(role_map(''));

    [data_variables, row_selector] = define_data_variables(data_variables, N_rows, options);

    if ~isempty(row_selector)
        N_available_rows = sum(row_selector);
    
        if N_rows ~= N_available_rows
            N_rows = N_available_rows; %#ok<NASGU>
            row_labels = row_labels(row_selector);
            spatial_index = spatial_index.select_by_segment(row_selector);
        end
    end
    
    check_nans = options.skip_columns_with_missing_values || ...
                 options.skip_rows_with_missing_values;
    
    result = geospm.NumericData(data_variables.matrix, check_nans);

    result.set_variable_names(data_variables.names);
    result.set_labels(row_labels);

    spatial_index = match_spatial_index(spatial_index, row_labels);

    result.attachments.rows_selected_in_file = row_labels;
    result.attachments.missing_values = data_variables.missing_values;
    result.attachments.variable_types = data_variables.types;
end

function spatial_index = match_spatial_index(spatial_index, row_labels)

    N_rows = numel(row_labels);

    segment_labels = spatial_index.segment_labels;
    segment_map = containers.Map('KeyType', 'char', 'ValueType', 'double');

    for index=1:numel(segment_labels)
        label = segment_labels{index};
        segment_map(label) = index;
    end
    
    unmatched_rows = {};
    segment_indices = zeros(N_rows, 1);

    for index=1:numel(row_labels)
        label = row_labels{index};

        if ~isKey(segment_map, label)
            unmatched_rows{end + 1} = label; %#ok<AGROW>
            continue;
        end

        segment_index = segment_map(label);
        segment_indices(index - numel(unmatched_rows)) = segment_index;
    end

    if numel(unmatched_rows) ~= 0

        unmatched_rows = join(unmatched_rows, ', ');
        unmatched_rows = unmatched_rows{1};

        error('Couldn''t match one or more data rows to the spatial index: %s.', unmatched_rows);
    end

    if ~isequal(segment_indices, (1:N_rows)')
        spatial_index = spatial_index.select_by_segment(segment_indices);
    end
end

function assert_no_unused_options(unused_options)
    unused_options = join(fieldnames(unused_options), ', ');
    unused_options = unused_options{1};
    
    if ~isempty(unused_options)
        error('Unknown options: %s', unused_options);
    end
end

function result = get_crs(options, file_path)

    [directory, basename, ~] = fileparts(file_path);
    projection_path = fullfile(directory, [basename '.prj']);
    
    if numel(options.crs_identifier) ~= 0
        result = options.crs_identifier;
    elseif isfile(projection_path)
        result = hdng.SpatialCRS.from_file(projection_path);
    else
        result = hdng.SpatialCRS.empty;
        warning(['No CRS identifier was explicitly' ...
                 ' specified ' newline 'and there appears to be no' ...
                 ' auxiliary ''' basename '.prj'' file.']); 
    end
end

function result = create_handler_map(map_variables)
    
    result = containers.Map('KeyType', 'char', 'ValueType', 'any');

    
    for index=1:2:numel(map_variables)

        variable_name = map_variables{index};
        handler = map_variables{index + 1};
        
        if ~isKey(result, variable_name)
            result(variable_name) = {};
        end
        
        handlers = result(variable_name);
        result(variable_name) = [handlers; {handler}];
    end
end

function variables = apply_handlers(variables, handler_map)

    for index=1:numel(variables)
        variable = variables{index};
        
        if ~isKey(handler_map, variable.name)
           continue;
        end

        handlers = handler_map(variable.name);

        for k=1:numel(handlers)
            handler = handlers{k};
            variable = handler(variable);
        end

        variables{index} = variable;
    end
end

function result = create_role_map(variables)

    result = containers.Map('KeyType', 'char', 'ValueType', 'any');
    
    for index=1:numel(variables)
        variable = variables{index};

        if ~isKey(result, variable.role)
            result(variable.role) = [];
        end

        entries = result(variable.role);

        entries = [entries; index]; %#ok<AGROW>

        result(variable.role) = entries;
    end
end

function row_labels = define_row_labels(variables, N_rows, role_map)

    if ~isKey(role_map, 'row_label')
        row_labels = (1:N_rows)';
    else
        
        row_label_index = role_map('row_label');

        if numel(row_label_index) > 1
            error('Multiple variables defined for role ''role_label''');
        end

        row_labels = variables{row_label_index}.data;
    end
    
    if isnumeric(row_labels)
        
        tmp = cell(N_rows, 1);
        
        for index=1:N_rows
            tmp{index} = sprintf('%d', row_labels(index));
        end

        row_labels = tmp;
    end
end

function result = create_variable_map(variables)
    
    result = containers.Map('KeyType', 'char', 'ValueType', 'any');

    for index=1:numel(variables)
        
        variable = variables{index};

        if ~isKey(result, variable.name)
            result(variable.name) = [];
        end

        indices = result(variable.name);
        result(variable.name) = [indices; index];
    end
end

function [result, row_selector] = define_data_variables(data_variables, N_rows, options)
    
    result = struct();
    
    result.names = cell(1, numel(data_variables));
    result.types = cell(1, numel(data_variables));
    result.matrix = zeros(N_rows, numel(data_variables));
    result.missing_values = zeros(N_rows, numel(data_variables), 'logical');

    row_selector = [];

    num_data_variables = 0;
    
    for index=1:numel(data_variables)
        variable = data_variables{index};
        
        if variable.is_char
            error('Only numeric variables are supported: ''%s''', variable.name);
        end

        if variable.has_missing_values && options.skip_columns_with_missing_values
            continue;
        end

        num_data_variables = num_data_variables + 1;
        
        result.matrix(:, index) = cast(variable.data, 'double');
        result.missing_values(:, index) = variable.is_missing;
        result.names{index} = variable.name;
        result.types{index} = variable.type;
    end

    % Adjust for skipped columns

    result.variables = data_variables(1:num_data_variables);
    result.names = result.names(1:num_data_variables);
    result.types = result.types(1:num_data_variables);
    result.matrix = result.matrix(:, 1:num_data_variables);
    result.missing_values = result.missing_values(:, 1:num_data_variables);
    
    if options.skip_rows_with_missing_values
        row_selector = ~any(result.missing_values, 2);
        N_available_rows = sum(row_selector);

        if N_rows ~= N_available_rows
            N_rows = N_available_rows; %#ok<NASGU>
            result.matrix = result.matrix(row_selector, :);
            result.missing_values = result.missing_values(row_selector, :);
        end
    end

    %{
    if add_constant
        result.matrix = [ones(size(result.matrix, 1), 1), result.matrix];
        result.missing_values = [zeros(size(result.missing_values, 1), 1), result.missing_values];
        result.names = ['constant', result.names];
        result.types = ['int64', result.types];
    end
    %}
end

function specifiers = define_spatial_variables(options)
    
    %opts = str2func('hdng.utilities.ValueOptions');
    var = str2func('hdng.utilities.VariableSpecifier.from');
    
    specifiers = hdng.utilities.VariableSpecifier.empty;

    specifiers(end + 1) = var(...
        'name_or_index_in_file', options.x_coordinate, ...
        'type', 'double', 'role', 'coordinate');

    specifiers(end + 1) = var(...
        'name_or_index_in_file', options.y_coordinate, ...
        'type', 'double', 'role', 'coordinate');
    
    if ~isempty(options.z_coordinate)
        specifiers(end + 1) = var(...
            'name_or_index_in_file', options.z_coordinate, ...
            'type', 'double', 'role', 'coordinate');
    end
end

function result = create_spatial_index_from_variables(variables, crs_or_crs_identifier, row_labels)
    
    x = variables{1}.data;
    y = variables{2}.data;
    z = [];

    if numel(variables) == 3
        z = variables{3}.data;
    end

    result = geospm.SpatialIndex(x, y, z, [], row_labels, crs_or_crs_identifier);
end

function [spatial_index_path, ext] = normalise_spatial_index_path(spatial_index_file, file_path)

    if isempty(spatial_index_file)
        spatial_index_file = file_path;
    end

    [spatial_index_directory, spatial_index_name, ext] = fileparts(spatial_index_file);
    
    spatial_index_name = [spatial_index_name ext];

    if isempty(spatial_index_directory)
        spatial_index_directory = fileparts(file_path);
    end

    spatial_index_path = fullfile(spatial_index_directory, spatial_index_name);
end
