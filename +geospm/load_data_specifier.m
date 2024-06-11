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
    
    if ~isfield(data_specifier, 'variable_selection')
        data_specifier.variable_selection = {};
    end
    
    if ~isfield(data_specifier, 'min_location')
        data_specifier.min_location = [];
    end

    if ~isfield(data_specifier, 'max_location')
        data_specifier.max_location = [];
    end

    if ~isfield(data_specifier, 'min_cutoff')
        data_specifier.min_cutoff = [];
    end
    
    if ~isfield(data_specifier, 'max_cutoff')
        data_specifier.max_cutoff = [];
    end

    if ~isfield(data_specifier, 'cutoff_variables')
        data_specifier.cutoff_variables = {};
    end

    if ~isfield(data_specifier, 'standardise')
        data_specifier.standardise = false;
    end
    
    if ~isfield(data_specifier, 'interactions')
        data_specifier.interactions = [];
    end
    
    if ~isfield(data_specifier, 'add_constant')
        data_specifier.add_constant = false;
    end

    if isfield(data_specifier.file_options, 'skip_rows_with_missing_values')
        skip_rows_with_missing_values = data_specifier.file_options.skip_rows_with_missing_values;
        data_specifier.file_options = rmfield(data_specifier.file_options, 'skip_rows_with_missing_values');
    else
        skip_rows_with_missing_values = true;
    end

    if isfield(data_specifier.file_options, 'skip_columns_with_missing_values')
        skip_columns_with_missing_values = data_specifier.file_options.skip_columns_with_missing_values;
        data_specifier.file_options = rmfield(data_specifier.file_options, 'skip_columns_with_missing_values');
    else
        skip_columns_with_missing_values = true;
    end
    
    arguments = hdng.utilities.struct_to_name_value_sequence(data_specifier.file_options);
    
    cache_key = file_path;

    if isfield(data_specifier.file_options, 'spatial_index_file') ...
            && ~isempty(data_specifier.file_options.spatial_index_file)
        cache_key = [cache_key '::' data_specifier.file_options.spatial_index_file];
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

    missing_values = spatial_data.attachments.missing_values;

    % clipping

    min_location = data_specifier.min_location;
    max_location = data_specifier.max_location;

    if isempty(min_location) ~= isempty(max_location)
        error('Both min_location and max_location must be non-empty when specified.');
    end

    if ~isempty(min_location) && ~isempty(max_location)
        grid = geospm.Grid();
        grid.span_frame(min_location, max_location, [1, 1, 1]);
    
        [~, segment_indices] = spatial_index.project(grid);
        
        if ~isequal(segment_indices, (1:spatial_index.S)')
            spatial_index = spatial_index.select_by_segment(segment_indices);
            spatial_data = spatial_data.select(segment_indices, []);
            missing_values = missing_values(segment_indices, :);
        end
    end

    min_cutoff = data_specifier.min_cutoff;
    max_cutoff = data_specifier.max_cutoff;
    
    if ~isempty(min_cutoff) || ~isempty(max_cutoff)

        if isempty(min_cutoff)
            min_cutoff = 0;
        end

        if isempty(max_cutoff)
            max_cutoff = 1;
        end

        cutoff_columns = [];
        
        for i=1:numel(data_specifier.cutoff_variables)
            name = data_specifier.variable_selection{i};
            index = find(strcmp(name, spatial_data.variable_names));
    
            if isempty(index)
                error('Column ''%s'' not defined in data.', name);
            end
    
            cutoff_columns = [cutoff_columns, index]; %#ok<AGROW>
        end
        
        [spatial_data, cutoff_selection] = spatial_data.remove_outliers(min_cutoff, max_cutoff, cutoff_columns);
        cutoff_selection = find(cutoff_selection);
        spatial_index = spatial_index.select_by_segment(cutoff_selection);
    end

    % filtering
    
    identified_columns = [];
    
    for i=1:numel(data_specifier.variable_selection)
        name = data_specifier.variable_selection{i};
        index = find(strcmp(name, spatial_data.variable_names));

        if isempty(index)
            error('Column ''%s'' not defined in data.', name);
        end

        identified_columns = [identified_columns, index]; %#ok<AGROW>
    end
    
    missing_values = missing_values(:, identified_columns);
    
    if skip_rows_with_missing_values
        rows = ~any(missing_values, 2);
    else
        rows = [];
    end

    columns = [];

    if skip_columns_with_missing_values
        for i=1:numel(identified_columns)
            index = identified_columns(i);
            
            if ~any(missing_values(:, i))
                columns = [columns, index]; %#ok<AGROW>
            end
        end
    else
        columns = identified_columns;
    end

    spatial_data = spatial_data.select(rows, columns, ...
        @(specifier, modifier) transform_spatial_data(specifier, modifier, data_specifier));

    if ~isempty(rows)
        missing_values = missing_values(rows, :);
    end
    
    % if interactions were added, update variable_labels

    if ~isempty(data_specifier.interactions)
        
        variable_labels = add_interaction_labels(...
                variable_labels, data_specifier.interactions);
    end

    spatial_index = spatial_index.select_by_segment(rows);
    
    
    % attachments
    
    spatial_data.attachments.group_identifier = data_specifier.group_identifier;
    spatial_data.attachments.group_label = data_specifier.group_label;
    spatial_data.attachments.variable_labels = variable_labels;
    spatial_data.attachments.missing_values = missing_values;
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
        
        variables = data_specifier.file_options.variables;
        variable_names = arrayfun(@(x) x.resolve_name(), variables, 'UniformOutput', false);

        for index=1:numel(data_specifier.variable_selection)
            name = data_specifier.variable_selection{index};
            variable_index = find(strcmp(name, variable_names), 1);

            if isempty(variable_index)
                continue
            end

            variable = variables(variable_index);
            
            if strcmp(variable.type, 'logical')
                continue;
            end
            
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
