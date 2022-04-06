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

function [result, additional_attributes] = collection_from_csv(file_path, varargin)

    options = hdng.utilities.parse_struct_from_varargin(varargin{:});

    if ~isfield(options, 'geometry_column_label')
        options.geometry_column_label = 'geometry';
    end

    if ~isfield(options, 'missing_geometry_rule')
        options.missing_geometry_rule = 'fill';
    end

    if ~isfield(options, 'broken_geometry_rule')
        options.broken_geometry_rule = 'fill';
    end

    if ~isfield(options, 'geometry_fill_type')
        options.geometry_fill_type = hdng.geometry.Polygon.empty;
    end

    if strcmpi(options.missing_geometry_rule, 'fill')
        missing_geometry_rule = @(line) options.geometry_fill_type;
    elseif strcmpi(options.missing_geometry_rule, 'error')
        missing_geometry_rule = @(line) error('Collection.from_csv(): Missing geometry in line %d.', line);
    else
        error(['Collection.from_csv(): Unknown specifier for missing_geometry_rule: ''' options.missing_geometry_rule '''.']);
    end


    if strcmpi(options.broken_geometry_rule, 'fill')
        broken_geometry_rule = @(line) options.geometry_fill_type;
    elseif strcmpi(options.broken_geometry_rule, 'error')
        broken_geometry_rule = @(line) error('Collection.from_csv(): Couldn''t parse geometry in line %d.', line);
    else
        error(['Collection.from_csv(): Unknown specifier for broken_geometry_rule: ''' options.broken_geometry_rule '''.']);
    end

    loader = hdng.utilities.DataLoader();

    [N_rows, ~, columns] = loader.load_from_file(file_path);

    geometry_column = struct.empty;
    additional_attributes = {};

    for i=1:numel(columns)

        column = columns{i};

        if isempty(geometry_column) && strcmpi(options.geometry_column_label, column.label)
            geometry_column = column;
        else
            additional_attributes{end + 1} = column; %#ok<AGROW>
        end
    end

    if isempty(geometry_column)
        error('Collection.from_csv(): Couldn''t locate geometry column in csv file.');
    end

    if ~iscell(geometry_column.data)
        error('Collection.from_csv(): Couldn''t parse geometry column in csv file.');
    end

    geometry_values = cell(N_rows, 1);

    for i=1:N_rows

        if geometry_column.is_missing(i)
            value = missing_geometry_rule(i);
        else

            wkt_geometry = geometry_column.data{i};
            wkt_geometry = hdng.wkt.WKTGeometry.from_chars(wkt_geometry);

            if ~isempty(wkt_geometry.errors)
                value = broken_geometry_rule(i);
            else
                value = wkt_geometry.value;
            end
        end

        geometry_values{i} = value;
    end

    result = hdng.geometry.utilities.collect_primitives(geometry_values);
end
