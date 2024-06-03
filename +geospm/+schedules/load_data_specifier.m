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

function [spatial_data, spatial_index] = load_data_specifier(data_specifier, cache)

    file_path = data_specifier.file_path;
    
    if ~isfield(data_specifier, 'identifier')
        data_specifier.identifier = '';
    end
    
    if ~isfield(data_specifier, 'label')
        data_specifier.label = data_specifier.identifier;
    end
    
    if ~isfield(data_specifier, 'group_identifier')
        data_specifier.group_identifier = '';
    end
    
    if ~isfield(data_specifier, 'group_label')
        data_specifier.group_label = data_specifier.group_identifier;
    end
    
    if ~isfield(data_specifier, 'variables')
        data_specifier.variables = {};
    end
    
    if ~isfield(data_specifier, 'standardise')
        data_specifier.standardise = true;
    end
    
    if ~isfield(data_specifier, 'interactions')
        data_specifier.interactions = [];
    end
    
    if ~isfield(data_specifier, 'min_location')
        error('data_specifier is missing ''min_location'' field.');
    end

    if isempty(data_specifier.min_location)
        error('data_specifier.min_location cannot be empty.');
    end
    
    if ~isfield(data_specifier, 'max_location')
        error('data_specifier is missing ''max_location'' field.');
    end

    if isempty(data_specifier.max_location)
        error('data_specifier.max_location cannot be empty.');
    end
    
    arguments = hdng.utilities.struct_to_name_value_sequence(data_specifier.file_options);
    
    cache_key = file_path;

    if isfield(data_specifier.file_options, 'spatial_index_file') ...
            && ~isempty(data_specifier.file_options.spatial_index_file)
        cache_key = [cache_key ':' data_specifier.file_options.spatial_index_file];
    end
    
    variable_labels = get_variable_label_map(data_specifier.file_options.variables);
    variable_names = get_variable_names(data_specifier.file_options.variables);
    variable_key = join(variable_names, ':');
    variable_key = variable_key{1};

    cache_key = [cache_key '::' variable_key];
    
    if ~cache.holds_key(cache_key)
        
        [spatial_data, spatial_index] = geospm.load_spatial_data(...
            file_path, ...
            arguments{:}, ...
            'skip_rows_with_missing_values', false, ...
            'skip_columns_with_missing_values', false);

        cache(cache_key) = {spatial_data, spatial_index}; %#ok<NASGU>
    else
        [spatial_data, spatial_index] = cache(cache_key);
    end

    min_location = data_specifier.min_location;

    if isempty(min_location)
        min_location = [-Inf, -Inf, -Inf];
    end

    max_location = data_specifier.max_location;

    if isempty(max_location)
        max_location = [Inf, Inf, Inf];
    end

    grid = geospm.Grid();
    grid.span_frame(min_location, max_location, [1, 1, 1]);

    [~, segment_indices] = spatial_index.project(grid);
    

    if ~isequal(segment_indices, (1:spatial_index.S)')
        spatial_index = spatial_index.select_by_segment(segment_indices);
        spatial_data = spatial_data.select(segment_indices, []);
    end

    if ~isfield(data_specifier.file_options, 'skip_rows_with_missing_values')
        data_specifier.file_options.skip_rows_with_missing_values = true;
    end

    if ~isfield(data_specifier.file_options, 'skip_columns_with_missing_values')
        data_specifier.file_options.skip_columns_with_missing_values = true;
    end
    
    % selection
    
    identified_columns = [];
    
    for i=1:numel(data_specifier.variables)
        variable = data_specifier.variables(i);
        name = variable.resolve_name();
        index = find(strcmp(name, spatial_data.variable_names));

        if isempty(index)
            error('Column ''%s'' not defined in table.', variable.resolve_name());
        end

        identified_columns = [identified_columns, index]; %#ok<AGROW>
    end
    
    missing_values = spatial_data.attachments.missing_values(:, identified_columns);
    rows = ~any(missing_values, 2);
    
    columns = [];

    for i=1:numel(identified_columns)
        index = identified_columns(i);
        
        if ~any(missing_values(:, i))
            columns = [columns, index]; %#ok<AGROW>
        end
    end

    spatial_data = spatial_data.select(rows, columns, ...
        @(specifier, modifier) transform_spatial_data(specifier, modifier, data_specifier));
    
    % interactions

    if ~isempty(data_specifier.interactions)
        
        variable_labels = add_interaction_labels(...
                variable_labels, data_specifier.interactions);
    end

    spatial_index = spatial_index.select_by_segment(rows);
    
    
    % attachments
    
    spatial_data.attachments.group_identifier = data_specifier.group_identifier;
    spatial_data.attachments.group_label = data_specifier.group_label;
    spatial_data.attachments.variable_labels = variable_labels;
end

function result = get_variable_names(variables)
    
    result = cell(numel(variables), 1);

    for index=1:numel(variables)
        variable = variables(index);
        result{index} = variable.resolve_name();
    end
end

function result = get_variable_label_map(variables)
    
    result = struct();

    for index=1:numel(variables)
        variable = variables(index);
        identifier = variable.resolve_name();
        result.(identifier) = variable.resolve_label();
    end
end

function specifier = transform_spatial_data(specifier, modifier, data_specifier)
    
    specifier.check_for_nans = true;

    if data_specifier.standardise
        for index=1:numel(data_specifier.variables)
            variable = data_specifier.variables(index);

            if strcmp(variable.type, 'logical')
                continue;
            end
            
            name = variable.resolve_name();
            variable_index = find(strcmp(name, specifier.per_column.variable_names), 1);
            
            if isempty(variable_index)
                continue;
            end

            values = specifier.data(:, variable_index);
            specifier.data(:, variable_index) = (values - mean(values, 'omitnan')) ./ std(values, 'omitnan');
        end
    end

    if ~isempty(data_specifier.interactions)
        specifier = add_interactions(specifier, modifier, data_specifier.interactions);
    end
end

function specifier = add_interactions(specifier, modifier, pairs)
    
    N = size(pairs, 1);
    P = size(specifier.data, 2);

    interactions = zeros(size(specifier.data, 1), N);
    interaction_labels = cell(1, N);

    for i=1:N
        var1 = pairs{i, 1};
        var2 = pairs{i, 2};

        index1 = find(strcmp(var1, specifier.per_column.variable_names), 1);
        index2 = find(strcmp(var2, specifier.per_column.variable_names), 1);

        if isempty(index1) || isempty(index2)
            error('Couldn''t define interaction.');
        end
        
        interactions(:, i) = specifier.data(:, index1) .* specifier.data(:, index2);
        interaction_labels{i} = [var1 '_x_' var2];
    end
    
    per_column = struct();
    per_column.variable_names = interaction_labels;

    specifier = modifier.insert_columns_op(specifier, P + 1, interactions, per_column);
end

function labels = add_interaction_labels(labels, pairs)

    N = size(pairs, 1);

    for i=1:N
        var1 = pairs{i, 1};
        var2 = pairs{i, 2};
        
        identifier = [var1 '_x_' var2];
        label = [labels.(var1) ' x ' labels.(var2)];
        labels.(identifier) = label;
    end
end
