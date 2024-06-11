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

%{
        Creates a data specifier struct for the given file path and
        options.

        The following name-value arguments are supported:
        
        -------------------------------------------------------------------
        
        -- General --
        
        variable_selection - A cell array of variable names to use from the loaded
        file.
        
        min_location, max_location – Only include observations within the
        region spanned from min_location to max_location.

        min_cutoff, max_cutoff – Only include observations within the
        provided percentile range. If both min_cutoff and max_cutoff are
        empty, no cutoff is applied.

        cutoff_variables – A cell array of names to which the cutoff should
        be applied. If empty, apply to all numeric variables.
        
        standardise – If true, standardise all numeric variables.

        interactions – A K x 2 cell array of variable names. A new variable
        will be defined for each pair in the array as the product of said 
        variables.
        
        add_constant – Adds a column of all ones. Defaults to false.
        
        Also see geospm.auxiliary.parse_spatial_load_options().
    %}

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

    if ~isfield(options, 'variable_selection')
        options.variable_selection = {};
    end

    if ~isfield(options, 'min_location')
        options.min_location = [-Inf, -Inf, -Inf];
    end
    
    if ~isfield(options, 'max_location')
        options.max_location = [Inf, Inf, Inf];
    end
    
    if ~isfield(options, 'min_cutoff')
        options.min_cutoff = [];
    end
    
    if ~isfield(options, 'max_cutoff')
        options.max_cutoff = [];
    end

    if ~isfield(options, 'cutoff_variables')
        options.cutoff_variables = {};
    end
    
    if ~isfield(options, 'standardise')
        options.standardise = false;
    end

    if ~isfield(options, 'interactions')
        options.interactions = {};
    end
    
    if ~isfield(options, 'add_constant')
        options.add_constant = false;
    end

    result = struct();

    result.file_path = file_path;
    result.file_options = file_options;

    result.identifier = identifier;
    result.label = label;

    result.group_identifier = options.group_identifier;
    result.group_label = options.group_label;

    result.variable_selection = options.variable_selection;
    
    result.min_location = options.min_location;
    result.max_location = options.max_location;

    result.standardise = options.standardise;
    result.interactions = options.interactions;
    result.add_constant = options.add_constant;
end
