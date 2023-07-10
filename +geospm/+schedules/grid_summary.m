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

function grid_summary(records, row_field, column_field, output_file, varargin)
    
    options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    
    if ~isfield(options, 'group_field')
        options.group_field = '';
    end
    

    if ~isfield(options, 'unnest_field')
        options.unnest_field = '';
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
        group_values = {};
    end

    row_values = unnested_records.value_index_for_name(row_field, true).values;
    column_values = unnested_records.value_index_for_name(column_field, true).values;
    
    grid_cells = cell(numel(row_values), numel(column_values));
    
    for row=1:numel(row_values)
        row_value = row_values{row};

        for col=1:numel(column_values)
            column_value = column_values{col};
            
            match = hdng.utilities.Dictionary();
            match(row_field) = row_value;
            match(column_field) = column_value;
            
            cell_records = unnested_records.select(match);
            grid_cells{row, col} = cell_records;
        end
    end

    options = struct();
    options.compression = true;
    options.base64 = true;
    
    format = hdng.experiments.JSONFormat();
    
    html = hdng.documents.renderers.HTMLContext();
    
    attributes = hdng.one_struct('rel', 'stylesheet', 'type', 'text/css', 'href', 'geospm_volume_viewer.css');
    html.simple_tag('link', attributes, hdng.documents.renderers.HTMLContext.HEAD_SECTION);
    
    attributes = hdng.utilities.Dictionary();
    attributes('data-initiator-create') = 'geospm_volume_viewer.cells.RecordTablePanel';
    attributes('data-cell-selection-fields') = ...
        '[&quot;result.terms.threshold_or_statistic&quot;]';
    attributes('data-cell-content-fields') = ...
        '[&quot;result.terms.contrast&quot;, &quot;result.terms.map&quot;, &quot;result.terms.mask_traces&quot;]';
    
    html.open_tag('div', attributes);
    html.close_tag('div');

    attributes = hdng.utilities.Dictionary();
    attributes('data-initiator-create') = 'geospm_volume_viewer.cells.RecordTable';
    attributes('class') = 'record-table';
        
    html.open_tag('table', attributes);
    
    html.open_tag('tr');

    html.open_tag('th');
    html.close_tag('th');

    for col=1:numel(column_values)
        column_value = column_values{col};
        
        attributes = hdng.one_struct('class', 'column-header');

        html.open_tag('th', attributes);
        html.open_tag('div');
        html.text_fragment(column_value.label);
        html.close_tag('div');
        html.close_tag('th');
    end
    
    html.close_tag('tr');

    for row=1:numel(row_values)

        html.open_tag('tr');

        row_value = row_values{row};


        attributes = hdng.one_struct('class', 'row-header');
        
        html.open_tag('th', attributes);
        html.open_tag('div');
        html.text_fragment(row_value.label);
        html.close_tag('div');
        html.close_tag('th');
        
        for col=1:numel(column_values)
            column_value = column_values{col};
            
            cell_records = grid_cells{row, col};
        
            cell_record_bytes = format.encode(cell_records.records, cell_records.attribute_map, ...
                                  cell_records.attachments, ...
                                  @(name) value_index_for_name(name, cell_records), ...
                                  options);
            
            cell_record_text = native2unicode(cell_record_bytes, 'UTF-8');
            
            attributes = hdng.utilities.Dictionary();
            attributes('data-row-value') = row_value.serialised;
            attributes('data-column-value') = column_value.serialised;

            html.open_tag('td', attributes);
            % html.text_fragment(sprintf('%d records.', cell_records.length));
            
            
            html.open_tag('div', hdng.one_struct('class', 'cell-content'));
            html.close_tag('div');

            attributes = hdng.utilities.Dictionary();
            attributes('type') = 'application/gzip';
            
            html.open_tag('script', attributes);
            
            fragment_size = 32;
            N_fragments = floor(cell_record_text / fragment_size);

            formatted_record_text = '';

            for fragment=1:N_fragments
                fragment_text = cell_record_text((fragment - 1) * fragment_size + 1:fragment * fragment_size);
                formatted_record_text = [formatted_record_text, newline, fragment_text]; %#ok<AGROW> 
            end
            
            fragment_text = cell_record_text(N_fragments * fragment_size + 1:end);
            formatted_record_text = [formatted_record_text, newline, fragment_text, newline]; %#ok<AGROW> 
            
            html.text_fragment(formatted_record_text);

            html.close_tag('script');
            html.close_tag('td');
        end

        html.close_tag('tr');
    end

    html.close_tag('table');
    
    html.open_tag('script', hdng.one_struct('src', 'js_initiator.js'));
    html.close_tag('script');
    html.open_tag('script', hdng.one_struct('src', 'adede.js'));
    html.close_tag('script');
    html.open_tag('script', hdng.one_struct('src', 'geospm_volume_viewer.js'));
    html.close_tag('script');

    html.open_tag('script', hdng.one_struct('type', 'text/javascript'));
    html.text_fragment('window.initiator.initialiseAll();');
    html.close_tag('script');
    
    html.save_output([output_file '.html']);
end


function result = value_index_for_name(name, records)
    result = records.value_index_for_name(name);
end
