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

function [load_options, other_options] = parse_load_options(varargin)

    load_options = struct();
    other_options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    if ~isfield(other_options, 'csv_delimiter')
        load_options.csv_delimiter = ',';
    else
        load_options.csv_delimiter = other_options.csv_delimiter;
        other_options = rmfield(other_options, 'csv_delimiter');
    end
    
    if ~isfield(other_options, 'crs_identifier')
        load_options.crs_identifier = '';
    else
        load_options.crs_identifier = other_options.crs_identifier;
        other_options = rmfield(other_options, 'crs_identifier');
    end
    
    if ~isfield(other_options, 'eastings_label')
        load_options.eastings_label = 'x';
    else
        load_options.eastings_label = other_options.eastings_label;
        other_options = rmfield(other_options, 'eastings_label');
    end
    
    if ~isfield(other_options, 'northings_label')
        load_options.northings_label = 'y';
    else
        load_options.northings_label = other_options.northings_label;
        other_options = rmfield(other_options, 'northings_label');
    end
    
    if isfield(other_options, 'row_identifier_index')
        load_options.row_identifier_index = other_options.row_identifier_index;
        other_options = rmfield(other_options, 'row_identifier_index');
    end
    
    if isfield(other_options, 'row_identifier_label')
        load_options.row_identifier_label = other_options.row_identifier_label;
        other_options = rmfield(other_options, 'row_identifier_label');
    end
    
    if ~isfield(other_options, 'mask_columns_with_missing_values')
        load_options.mask_columns_with_missing_values = true;
    else
        load_options.mask_columns_with_missing_values = other_options.mask_columns_with_missing_values;
        other_options = rmfield(other_options, 'mask_columns_with_missing_values');
    end
    
    if ~isfield(other_options, 'mask_rows_with_missing_values')
        load_options.mask_rows_with_missing_values = true;
    else
        load_options.mask_rows_with_missing_values = other_options.mask_rows_with_missing_values;
        other_options = rmfield(other_options, 'mask_rows_with_missing_values');
    end
    
    if ~isfield(other_options, 'add_constant')
        load_options.add_constant = false;
    else
        load_options.add_constant = other_options.add_constant;
        other_options = rmfield(other_options, 'add_constant');
    end
    
    if ~isfield(other_options, 'include')
        load_options.include = {};
    else
        load_options.include = other_options.include;
        other_options = rmfield(other_options, 'include');
    end
    
    if ~isfield(other_options, 'exclude')
        load_options.exclude = {};
    else
        load_options.exclude = other_options.exclude;
        other_options = rmfield(other_options, 'exclude');
    end
end
