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

function spatial_index = load_spatial_index(file_path, varargin)
    %{
        Creates a geospm.SpatialIndex from a file.

        The following name-value arguments are supported:
        
        -------------------------------------------------------------------
        
        -- General --

        csv_delimiter – The field delimiter character of the CSV file.
        Defaults to ',' (comma).

        -- Coordinates --
        
        crs_identifier – An identifier for a coordinate reference system,
        for example: 'EPSG:27700' If this parameter is not specified and
        no '.prj' sidecar file can be found, a warning will be generated.
        
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
    
    crs_or_crs_identifier = get_crs(options, file_path);
    
    [spatial_index_path, ext] = normalise_spatial_index_path(options.spatial_index_file, file_path);

    switch lower(ext)
        case '.mat'
            spatial_index = geospm.BaseSpatialIndex.load_from_matlab(spatial_index_path);
        
        case '.csv'
            spatial_index = load_spatial_index_from_csv(spatial_index_path, crs_or_crs_identifier, options);

        otherwise
            error('Unknown file extension ''%s'' for spatial index.', ext);
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

function [result, order] = create_spatial_index_from_variables(variables, crs_or_crs_identifier, row_labels)
    
    x = variables{1}.data;
    y = variables{2}.data;
    z = [];

    if numel(variables) >= 3
        z = variables{3}.data;
    end

    x = cast(x, 'double');
    y = cast(y, 'double');
    z = cast(z, 'double');
    
    if numel(variables) >= 4
        
        segment_index = variables{end};
        segment_index = segment_index.data;
    
        % make sure the segments are arranged in ascending order
        [segment_index, order] = sort(segment_index);
    
        segments = geospm.SpatialIndex.segment_indices_to_segment_sizes(segment_index);
    else
        segments = [];
        order = [];
    end
    
    result = geospm.SpatialIndex(x, y, z, segments, row_labels, crs_or_crs_identifier);
end

function variables = define_segment_variables(variables, options)

    if ~isempty(options.segment_label)
        variables(end + 1) = var(...
            options.segment_label, ...
            '', ...
            'int64');
    else
        
        if isempty(options.segment_index)
            error('Either one of segment_index or segment_label needs to be defined.');
        end

        variables(end + 1) = var(...
            options.segment_index, ...
            '', ...
            'int64');
    end
    
end

function [result, order] = load_spatial_index_from_csv(file_path, crs_or_crs_identifier, options)

    loader = hdng.utilities.VariableLoader();
    
    loader.csv_delimiter = options.csv_delimiter;
    loader.value_options_by_type = options.value_options_by_type;
    
    spatial_variables = define_spatial_variables(options);
    spatial_variables = define_segment_variables(spatial_variables, options);
    
    [~, variables, selected_specifiers] = ...
        loader.load_from_file( ...
            file_path, spatial_variables(:));

    assert_spatial_variables(spatial_variables, selected_specifiers, file_path);
    [result, order] = create_spatial_index_from_variables(variables, crs_or_crs_identifier, row_labels);
end


function assert_spatial_variables(specifiers, selected, file_path)

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

        error('The following coordinate columns are not defined in ''%s'': %s.', ...
            file_name, identifier);
    end
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
