% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2021,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function [groups, group_values, row_values, column_values] = ...
    grid_cells_from_records(records, row_field, column_field, varargin)
    
    options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    if ~isfield(options, 'group_field')
        options.group_field = '';
    end
    
    if ~isfield(options, 'unnest_field')
        options.unnest_field = '';
    end
    
    if ~isfield(options, 'cell_selector')
        options.cell_selector = [];
    end

    if ~isfield(options, 'column_order')
        options.column_order = {};
    end
    
    if ~isempty(options.unnest_field)
        unnested_records = hdng.experiments.unnest_records(records, ...
            options.unnest_field, {}, {}, [options.unnest_field '.']);
    else
        unnested_records = records;
    end
    
    if ~isempty(options.group_field)
        group_values = unnested_records.value_index_for_name(options.group_field, true).values;
    else
        group_values = {hdng.experiments.Value.from('All')};
    end
    
    group_indices = hdng.utilities.Dictionary();

    for index=1:numel(group_values)
        value = group_values{index};
        group_indices(value.label) = index;
    end
    
    row_values = unnested_records.value_index_for_name(row_field, true).values;
    column_values = unnested_records.value_index_for_name(column_field, true).values;

    row_indices = hdng.utilities.Dictionary();

    for index=1:numel(row_values)
        value = row_values{index};
        row_indices(value.label) = index;
    end

    %{
    interactions = contains(cellfun(@(x) x.label, column_values(:), 'UniformOutput', false), ' x ');

    main_values = column_values(~interactions);
    [~, column_order] = sort(cellfun(@(x) x.label, main_values, 'UniformOutput', false));
    main_values = main_values(column_order);

    interaction_values = column_values(interactions);
    [~, column_order] = sort(cellfun(@(x) x.label, interaction_values, 'UniformOutput', false));
    interaction_values = interaction_values(column_order);
    
    column_values = [main_values; interaction_values];
    %}
    
    [~, column_order] = sort(cellfun(@(x) x.label, column_values, 'UniformOutput', false));
    column_values = column_values(column_order);

    column_order = hdng.utilities.Dictionary();
    
    for index=1:numel(options.column_order)
        value = options.column_order{index};
        column_order(value) = index;
    end

    column_positions = zeros(size(column_values));
    
    for index=1:numel(column_values)
        value = column_values{index};
        position = column_order.length + index;
        
        if column_order.holds_key(value.label)
            position = column_order(value.label);
        end
        
        column_positions(index) = position;
    end
    
    [~, column_order] = sort(column_positions);
    column_values = column_values(column_order);

    column_indices = hdng.utilities.Dictionary();

    for index=1:numel(column_values)
        value = column_values{index};
        column_indices(value.label) = index;
    end

    groups = cell(numel(group_values), 1);
    
    for record_index=1:numel(unnested_records.records)

        record = unnested_records.records{record_index};

        if ~isempty(options.group_field)
            group_value = record(options.group_field);
        else
            group_value = group_values{1};
        end
        
        group_index = group_indices(group_value.label);

        group = groups{group_index};

        if isempty(group)
            group = create_group(group_index, group_value, row_values, column_values);
            groups{group_index} = group;
        end
        
        row_value = record(row_field);
        column_value = record(column_field);
        
        row_index = row_indices(row_value.label);
        column_index = column_indices(column_value.label);
        
        group.row_value_selector(row_index) = 1;
        group.column_value_selector(column_index) = 1;

        cell_records = group.grid_cells{row_index, column_index};
        
        if isempty(cell_records)
            cell_records = hdng.experiments.RecordArray();
        end

        cell_records.include_record(record);

        group.grid_cells{row_index, column_index} = cell_records;

        groups{group_index} = group;
    end

    column_weights = zeros(size(column_values));

    for index=1:numel(groups)
        group = groups{index};

        cell_selector = cellfun(@(x) ~isempty(x), group.grid_cells);
        
        group_column_weights = sum(cell_selector, 1)';

        column_weights = column_weights + group_column_weights;
    end

    [~, column_order] = sort(column_weights, 'descend');
    column_values = column_values(column_order);


    for index=1:numel(groups)
        group = groups{index};
        
        % group_column_order = cumsum(group.column_value_selector);
        % group_column_order = group_column_order(column_order);
        
        group.column_value_selector = group.column_value_selector(column_order);
        
        % group_column_order = group_column_order(group.column_value_selector);
        
        group.grid_cells = group.grid_cells(:, column_order);
        
        groups{index} = group;
    end
end

function result = create_group(group_index, group_value, row_values, column_values)
    result = struct();
    result.group_index = group_index;
    result.group_value = group_value;
    result.grid_cells = cell(numel(row_values), numel(column_values));
    result.row_value_selector = zeros(size(row_values), 'logical');
    result.column_value_selector = zeros(size(column_values), 'logical');
end
