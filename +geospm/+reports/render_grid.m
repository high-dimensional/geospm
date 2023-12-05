function result = render_grid(grid_cell_contexts, row_values, column_values, renderer, resources, render_options)
    
    row_labels = cellfun(@(x) x.label, row_values, 'UniformOutput', false);
    column_labels = cellfun(@(x) x.label, column_values, 'UniformOutput', false);
    
    [~, row_sizes, column_sizes, grid_size] = ...
           geospm.reports.compute_cell_sizes(grid_cell_contexts);
    
    grid_size = grid_size + [(size(grid_cell_contexts, 1) - 1) * render_options.cell_spacing(1), ...
                             (size(grid_cell_contexts, 1) - 1) * render_options.cell_spacing(2)];
    
    grid_cell_contents = geospm.reports.render_grid_cells(grid_cell_contexts, row_sizes, column_sizes, renderer, render_options);
    
    cells_fragment = join(grid_cell_contents(:), newline);
    cells_fragment = cells_fragment{1};
    
    label_attributes = hdng.utilities.Dictionary();
    label_attributes('font-family') = 'Barlow, sans';
    label_attributes('font-weight') = '600';


    coords = hdng.one_struct('x', render_options.origin(1), ...
                             'y', render_options.origin(2));
    
    row_labels_fragment = geospm.reports.render_labels(...
                                row_labels, ...
                                row_sizes, ...
                                'y', ...
                                coords, ...
                                render_options.cell_spacing(2), ...
                                label_attributes);
    
    column_labels_fragment = {};

    for index=1:size(grid_cell_contexts, 1)
        column_labels_fragment{index} = geospm.reports.render_labels(...
                                    column_labels, ...
                                    column_sizes, ...
                                    'x', ...
                                    coords, ...
                                    render_options.cell_spacing(1), ...
                                    label_attributes); %#ok<AGROW>
        
        if ~render_options.per_row_column_labels
            break;
        end

        coords.y = coords.y + row_sizes(index) + render_options.cell_spacing(2);
    end

    column_labels_fragment = join(column_labels_fragment, newline);
    column_labels_fragment = column_labels_fragment{1};

    legend_fragment = render_legend(grid_size, renderer, render_options);
    
    view_box = [
        -render_options.cell_spacing(1), ...
        -render_options.cell_spacing(2), ... 
        grid_size(1) + 2 * render_options.cell_spacing(1), ...
        grid_size(2) + 2 * render_options.cell_spacing(2)];
    
    svg_attributes = hdng.utilities.Dictionary();
    svg_attributes('xmlns') = 'http://www.w3.org/2000/svg';
    svg_attributes('xmlns:xlink') = 'http://www.w3.org/1999/xlink';
    svg_attributes('xml:space') = 'preserve';
    svg_attributes('version') = '1.1';
    svg_attributes('viewBox') = render_view_box(view_box(1), view_box(2), view_box(3), view_box(4));
    svg_attributes('preserveAspectRatio') = 'xMidYMid meet';
    svg_attributes('width') = sprintf('%d', view_box(3));
    svg_attributes('height') = sprintf('%d', view_box(4));
    
    svg_attributes = geospm.reports.render_markup_attributes(svg_attributes);

    prologue = sprintf('<svg %s>', svg_attributes);
    shared_fragment = renderer.render_shared_resources(resources);
    epilogue = sprintf('</svg>');
    
    result = join({prologue ...
                   shared_fragment ...
                   column_labels_fragment ...
                   row_labels_fragment ...
                   cells_fragment ...
                   legend_fragment ...
                   epilogue, ...
                   '' ...
                   }, newline);

    result = result{1};

end

function result = render_legend(grid_size, renderer, render_options)
    result = sprintf('<text text-anchor="end" x="%d" y="%d" dy="1.2em">%s</text>', grid_size(1), grid_size(2) + render_options.cell_spacing(2), renderer.slice_name);
end

function result = render_view_box(x, y, width, height)
    result = sprintf('%d %d %d %d', x, y, width, height);
end
