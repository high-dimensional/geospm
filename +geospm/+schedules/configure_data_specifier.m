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

function result = configure_data_specifier(file_path, file_options, ...
    identifier, label, varargin)

    options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    if isempty(file_options)
        file_options = struct();
    end

    if ~isfield(options, 'group_identifier')
        options.group_identifier = '';
    end

    if ~isfield(options, 'group_label')
        options.group_label = options.group_identifier;
    end

    if ~isfield(options, 'variables')
        options.variables = {};
    end

    if ~isfield(options, 'standardise')
        options.standardise = false;
    end

    if ~isfield(options, 'interactions')
        options.interactions = {};
    end
    
    if ~isfield(options, 'min_location')
        options.min_location = [-Inf, -Inf, -Inf];
    end
    
    if ~isfield(options, 'max_location')
        options.max_location = [Inf, Inf, Inf];
    end

    result = struct();

    result.file_path = file_path;
    result.file_options = file_options;

    result.identifier = identifier;
    result.label = label;

    result.group_identifier = options.group_identifier;
    result.group_label = options.group_label;

    result.variables = options.variables;

    result.standardise = options.standardise;
    result.interactions = options.interactions;

    result.min_location = options.min_location;
    result.max_location = options.max_location;
end
