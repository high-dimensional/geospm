function result = render_combined_grid(grid_rows, renderer, resources, render_options)
    
    grid_size = [0, 0];

    labels_fragment = cell([numel(grid_rows), 1]);
    cells_fragment = cell([numel(grid_rows), 1]);

    for index=1:numel(grid_rows)
        grid_row = grid_rows(index);
        grid_size = [max([grid_size(1) grid_row.grid_size(1)]), grid_size(2) + grid_row.grid_size(2)];
        labels_fragment{index} = grid_row.labels;
        cells_fragment{index} = grid_row.cells;
    end
    
    grid_size = grid_size + [0, (numel(grid_rows) - 1) * render_options.cell_spacing(2)];
    
    labels_fragment = join(labels_fragment, '');
    labels_fragment = labels_fragment{1};


    cells_fragment = join(cells_fragment, '');
    cells_fragment = cells_fragment{1};

    legend_fragment = render_legend(grid_size, renderer, render_options);
    
    view_box = [
        0, ...
        0, ... 
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
    shared_fragment = renderer.render_shared_resources(resources, render_options);
    epilogue = sprintf('</svg>');
    
    result = join({prologue ...
                   shared_fragment ...
                   sprintf('<g transform="translate(%d %d)">', render_options.cell_spacing(1), render_options.cell_spacing(2)) ...
                   labels_fragment ...
                   cells_fragment ...
                   legend_fragment ...
                   '</g>' ...
                   epilogue, ...
                   '' ...
                   }, newline);

    result = result{1};

end

function result = render_legend(grid_size, renderer, render_options)
    result = sprintf('<text text-anchor="end" x="%d" y="%d" dy="1.2em">%s</text>', grid_size(1), grid_size(2) + render_options.cell_spacing(2), render_options.slice_name);
end

function result = render_view_box(x, y, width, height)
    result = sprintf('%d %d %d %d', x, y, width, height);
end
