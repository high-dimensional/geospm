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
        
        add_constant – Adds a column of all ones. Defaults to false.
        
        map_variables – A cell array with 2 columns. The first column
        specifies a variable name, the second column specifies a handler
        function, that transforms the data for that variable:
        
        handler(variable_name, column_index, variable_matrix, variable_name_map)
        handler(variable, index)

        skip_rows_with_missing_values – Ignore rows with missing values.
        Defaults to true.

        skip_columns_with_missing_values – Ignore columns with missing
        values. Defaults to true.

        Also see geospm.auxiliary.parse_load_options().
    %}

    [options, unused_options] = geospm.auxiliary.parse_spatial_load_options(varargin{:});
    
    assert_no_unused_options(unused_options);
    
    crs_or_crs_identifier = get_crs(options, file_path);
    
    spatial_index = [];
    spatial_variables = [];

    if ~isempty(options.spatial_index_file)
        [spatial_index_directory, spatial_index_name, ext] = fileparts(options.spatial_index_file);
        
        spatial_index_name = [spatial_index_name ext];

        if isempty(spatial_index_directory)
            spatial_index_directory = fileparts(file_path);
        end

        spatial_index_path = fullfile(spatial_index_directory, spatial_index_name);

        switch lower(ext)
            case '.mat'
                spatial_index = geospm.SpatialIndex.load_from_matlab(spatial_index_path);
            
            case '.csv'
                spatial_index = load_spatial_index_from_csv(spatial_index_path, crs_or_crs_identifier, options);

            otherwise
                error('Unknown file extension ''%s'' for spatial index.', ext);
        end
    else
        spatial_variables = define_spatial_variables(options);
    end
    
    loader = hdng.utilities.VariableLoader();
    
    loader.csv_delimiter = options.csv_delimiter;
    loader.value_options_by_type = options.value_options_by_type;
    
    [N_rows, variables, selected_specifiers] = ...
        loader.load_from_file( ...
            file_path, [spatial_variables(:); options.variables(:)]);

    N_spatial_variables = numel(spatial_variables);

    if N_spatial_variables > 0
        N_selected_spatial_variables = sum(selected_specifiers(1:N_spatial_variables));
    
        if N_selected_spatial_variables ~= N_spatial_variables
            [~, file_name, ext] = fileparts(file_path);
            file_name = [file_name, ext];
            error('Some coordinate columns are unavailable in ''%s''.', file_name);
        end
    
        spatial_variables = variables(1:N_spatial_variables);
        variables = variables(N_spatial_variables + 1:end);
        selected_specifiers = selected_specifiers(N_spatial_variables + 1:end);

        spatial_index = create_spatial_index_from_variables(spatial_variables, crs_or_crs_identifier);
    end
    
    %{
    handler_map = create_handler_map(options.map_variables);
    variables = apply_handlers(variables, handler_map);
    %}

    variable_map = create_variable_map(variables);
    role_map = create_role_map(variables);
    
    if ~isKey(role_map, '')
        error('No data variables defined.');
    end
    
    if ~isKey(role_map, 'row_label')
        row_labels = (1:N_rows)';
    else
        
        row_label_index = role_map('row_label');

        if numel(row_label_index) > 1
            error('Multiple variables defined for role ''role_label''');
        end

        row_labels = variables{row_label_index}.data;
    end
    
    data_variables = variables(role_map(''));
    data_variable_names = cell(1, numel(data_variables));
    data_variable_types = cell(1, numel(data_variables));
    data_matrix = zeros(N_rows, numel(data_variables));
    missing_values = zeros(N_rows, numel(data_variables), 'logical');

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

        data_matrix(:, index) = cast(variable.data, 'double');
        missing_values(:, index) = variable.is_missing;
        data_variable_names{index} = variable.name;
        data_variable_types{index} = variable.type;
    end

    % Adjust for skipped columns

    data_variables = data_variables(1:num_data_variables);
    data_variable_names = data_variable_names(1:num_data_variables);
    data_variable_types = data_variable_types(1:num_data_variables);
    data_matrix = data_matrix(:, 1:num_data_variables);
    missing_values = missing_values(:, 1:num_data_variables);

    
    if options.add_constant
        data_matrix = [ones(size(data_matrix, 1), 1), data_matrix];
        missing_values = [zeros(size(missing_values, 1), 1), missing_values];
        data_variable_names = ['constant', data_variable_names];
        data_variable_types = ['int64', data_variable_types];
    end
    
    if options.skip_rows_with_missing_values
        row_selector = ~any(missing_values, 2);
    else
        row_selector = [];
    end

    if ~isempty(row_selector)
        N_rows = sum(row_selector);
        data_matrix = data_matrix(row_selector, :);
        missing_values = missing_values(row_selector, :);
    else
        row_selector = ones(N_rows, 1, 'logical');
    end

    check_nans = options.skip_columns_with_missing_values || ...
                 options.skip_rows_with_missing_values;
    
    result = geospm.NumericData(data_matrix, check_nans);
    result.set_variable_names(data_variable_names);
    
    if isnumeric(row_labels)
        
        tmp = cell(N_rows, 1);
        
        for index=1:N_rows
            tmp{index} = sprintf('%d', row_labels(index));
        end

        row_labels = tmp;
    end

    result.set_labels(row_labels);
    
    rows_selected_in_file = (1:numel(row_selector))';
    rows_selected_in_file = rows_selected_in_file(row_selector);

    if numel(row_selector) ~= N_rows
        spatial_index = spatial_index.select_by_segment(rows_selected_in_file);
    end

    result.attachments.rows_selected_in_file = rows_selected_in_file;
    result.attachments.missing_values = missing_values;
    result.attachments.variable_types = data_variable_types;
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

function specifiers = define_spatial_variables(options)

    %opts = str2func('hdng.utilities.ValueOptions');
    var = str2func('hdng.utilities.VariableSpecifier');
    
    specifiers = hdng.utilities.VariableSpecifier.empty;

    specifiers(end + 1) = var(...
        'name_or_index_in_file', options.x_coordinate, ...
        'type', 'double');

    specifiers(end + 1) = var(...
        'name_or_index_in_file', options.y_coordinate, ...
        'type', 'double');

    if ~isempty(options.z_coordinate)
        specifiers(end + 1) = var(...
            'name_or_index_in_file', options.z_coordinate, ...
            'type', 'double');
    end
end

function result = create_spatial_index_from_variables(variables, crs_or_crs_identifier)
    
    x = variables{1}.data;
    y = variables{2}.data;
    z = [];

    if numel(variables) == 3
        z = variables{3}.data;
    end

    result = geospm.SpatialIndex(x, y, z, [], [], crs_or_crs_identifier);
end

function [result, order] = load_spatial_index_from_csv(file_path, options)

    loader = hdng.utilities.VariableLoader();
    
    loader.csv_delimiter = options.csv_delimiter;
    loader.value_options_by_type = options.value_options_by_type;
    
    specifiers = define_spatial_variables(options);

    if ~isempty(options.segment_label)
        specifiers(end + 1) = var(...
            'name_or_index_in_file', options.segment_label, ...
            'type', 'int64');
    else
        
        if isempty(options.segment_index)
            error('Either one of segment_index or segment_label needs to be defined.');
        end

        specifiers(end + 1) = var(...
            'name_or_index_in_file', options.segment_index, ...
            'type', 'int64');
    end
    
    [~, variables, selected] = loader.load_from_file(file_path, crs_or_crs_identifier, specifiers);

    if sum(selected) ~= numel(specifiers)
        unavailable = specifiers(~selected);
        identifiers = {};
        

        for index=1:numel(unavailable)
            identifier = unavailable.name_or_index_in_file;
            if isnumeric(identifier)
                identifier = sprintf('%d', identifier);
            end

            identifiers{index} = identifier; %#ok<AGROW>
        end

        identifiers = join(identifiers, ', ');
        identifier = identifiers{1};
        [~, file_name, ext] = fileparts(file_path);
        file_name = [file_name, ext];

        error('The following columns are not defined in ''%s'': %s.', ...
            file_name, identifier);
    end

    x = variables{1};
    y = variables{2};
    z = [];

    if ~isempty(options.z_coordinate)
        z = variables{3};
    end

    x = cast(x, 'double');
    y = cast(y, 'double');
    z = cast(z, 'double');

    segment_index = variables{end};
    segment_index = segment_index.data;
    
    % make sure the segments are arranged in ascending order
    [segment_index, order] = sort(segment_index);

    segments = geospm.SpatialIndex.segment_indices_to_segment_sizes(segment_index);
    result = geospm.SpatialIndex(x, y, z, segments, [], crs_or_crs_identifier);
end
