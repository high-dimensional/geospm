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

function [load_options, other_options] = parse_spatial_load_options(varargin)

    load_options = struct();
    other_options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    if ~isfield(other_options, 'csv_delimiter')
        load_options.csv_delimiter = ',';
    else
        load_options.csv_delimiter = other_options.csv_delimiter;
        other_options = rmfield(other_options, 'csv_delimiter');
    end

    if ~isfield(other_options, 'spatial_index_file')
        load_options.spatial_index_file = '';
    else
        load_options.spatial_index_file = other_options.spatial_index_file;
        other_options = rmfield(other_options, 'spatial_index_file');
    end
    
    if ~isfield(other_options, 'x_coordinate')
        load_options.x_coordinate = 'x';
    else
        load_options.x_coordinate = other_options.x_coordinate;
        other_options = rmfield(other_options, 'x_coordinate');
    end
    
    if ~isfield(other_options, 'y_coordinate')
        load_options.y_coordinate = 'y';
    else
        load_options.y_coordinate = other_options.y_coordinate;
        other_options = rmfield(other_options, 'y_coordinate');
    end
    
    if ~isfield(other_options, 'z_coordinate')
        load_options.z_coordinate = '';
    else
        load_options.z_coordinate = other_options.z_coordinate;
        other_options = rmfield(other_options, 'z_coordinate');
    end
    
    if isfield(other_options, 'segment_index')
        load_options.segment_index = other_options.segment_index;
        other_options = rmfield(other_options, 'segment_index');
    end
    
    if isfield(other_options, 'segment_label')
        load_options.segment_label = other_options.segment_label;
        other_options = rmfield(other_options, 'segment_label');
    end
    
    
    if ~isfield(other_options, 'crs_identifier')
        load_options.crs_identifier = '';
    else
        load_options.crs_identifier = other_options.crs_identifier;
        other_options = rmfield(other_options, 'crs_identifier');
    end
    
    if ~isfield(other_options, 'variables')
        load_options.variables = {};
    else
        load_options.variables = other_options.variables;
        other_options = rmfield(other_options, 'variables');
    end
    
    if ~isfield(other_options, 'value_options_by_type')
        load_options.value_options_by_type = struct();
    else
        load_options.value_options_by_type = other_options.value_options_by_type;
        other_options = rmfield(other_options, 'value_options_by_type');
    end
    
    if ~isfield(other_options, 'add_constant')
        load_options.add_constant = false;
    else
        load_options.add_constant = other_options.add_constant;
        other_options = rmfield(other_options, 'add_constant');
    end
    
    if ~isfield(other_options, 'map_variables')
        load_options.map_variables = {};
    else
        load_options.map_variables = other_options.map_variables;
        other_options = rmfield(other_options, 'map_variables');
    end
    
    if ~isfield(other_options, 'skip_columns_with_missing_values')
        load_options.skip_columns_with_missing_values = false;
    else
        load_options.skip_columns_with_missing_values = other_options.skip_columns_with_missing_values;
        other_options = rmfield(other_options, 'skip_columns_with_missing_values');
    end
    
    if ~isfield(other_options, 'skip_rows_with_missing_values')
        load_options.skip_rows_with_missing_values = true;
    else
        load_options.skip_rows_with_missing_values = other_options.skip_rows_with_missing_values;
        other_options = rmfield(other_options, 'skip_rows_with_missing_values');
    end
end
