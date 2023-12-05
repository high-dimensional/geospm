function grid_cell_contents = render_grid_cells(grid_cell_contexts, row_sizes, column_sizes, renderer, render_options)

    render_options = geospm.reports.grid_render_options(render_options);
        
    grid_cell_contents = cell(size(grid_cell_contexts));

    cell_spacing = render_options.cell_spacing;
    origin = render_options.origin;
    
    row_offset = origin(2);

    for row_index=1:size(grid_cell_contexts, 1)
        
        col_offset = origin(1);

        for col_index=1:size(grid_cell_contexts, 2)

            cell_context = grid_cell_contexts{row_index, col_index};

            if ~isempty(cell_context)
                cell_context.origin = [col_offset, row_offset];
                cell_context.magnification = render_options.magnification;
                cell_context.slice_name = render_options.slice_name;
                cell_content = renderer.render_loaded_context(cell_context);
                cell_content = sprintf('%s<g>%s<rect class="volume-background" x="%d" y="%d" width="%d" height="%d"/>%s%s</g>', newline, newline, col_offset, row_offset, cell_context.stack.size(1), cell_context.stack.size(2), cell_content, newline);
            else
                cell_content = '';
            end

            grid_cell_contents{row_index, col_index} = cell_content;
            col_offset = col_offset + column_sizes(col_index) + cell_spacing(1);
        end

        row_offset = row_offset + row_sizes(row_index) + cell_spacing(2);
    end



%{


    serviceIdle(service) {
        if( service.stoppedRequests < service.requests.length ) return;
        service.unregisterServiceHandler(this);

        const rowLabels = [];

        for( let rowIndex = 0; rowIndex < service.context.contextsByRow.length; rowIndex++ ) {
            const contextRow = service.context.contextsByRow[rowIndex];
            const row = service.context.cellsByRow[rowIndex];

            for( let columnIndex = 0; columnIndex < contextRow.length; columnIndex++ ) {
                const cellContexts = contextRow[columnIndex];
                let cellContent = "";

                for( let context of cellContexts ) {
                    cellContent = cellContent + service.renderer.renderLoadedContext(context);
                }

                service.context.cellContentsByRow[rowIndex][columnIndex] = cellContent;

                const cell = row[columnIndex];

                if( columnIndex === 0 ) rowLabels.push(cell.rowValue.label);
            }
        }

        const columnLabels = [];

        const firstRow = service.context.cellsByRow[0];

        if( firstRow ) {

            for( let columnIndex = 0; columnIndex < firstRow.length; columnIndex++ ) {

                const cell = firstRow[columnIndex];
                columnLabels.push(cell.columnValue.label);
            }
        }


        service.context.columnLabels = columnLabels;
        service.context.rowLabels = rowLabels;
        service.context.sharedRendering = service.renderer.renderSharedResources(service.context.resources);
        service.context.sliceName = service.renderer.sliceName;

        this.didRenderCellsAsSVG(service.context);
    };


    didRenderCellsAsSVG(context) {

        const fontAttributes = {};
        let labels = '';
        const origin = Array.from(context.origin);

        fontAttributes["font-family"] = "Barlow, sans";
        fontAttributes["font-weight"] = "600";

        for( let index = 0; index < context.columnLabels.length; index++ ) {
            const columnLabel = escapeForHTML(context.columnLabels[index]);
            
            labels += `<text text-anchor="middle" x="${origin[0] + context.columnSizes[index] / 2.0}" y="${origin[1]}" ${renderProperties(fontAttributes)}>${columnLabel}</text>\n`
            origin[0] += context.columnSizes[index] + context.cellSpacing[0];
        }

        origin[0] = context.origin[0];

        for( let index = 0; index < context.rowLabels.length; index++ ) {
            const rowLabel = escapeForHTML(context.rowLabels[index]);

            labels += `<text text-anchor="end" x="${origin[0]}" y="${origin[1] + context.rowSizes[index] / 2.0}" ${renderProperties(fontAttributes)}>${rowLabel}</text>\n`
            origin[1] += context.rowSizes[index] + context.cellSpacing[1];
        }

        let cells = '';

        for( let row of context.cellContentsByRow ) {
            for( let cell of row ) {
                cells = cells + cell + '\n';
            }
        }

        let legend = '';

        legend += `<text text-anchor="end" x="${context.gridSize[0].toString()}" y="${context.gridSize[1].toString()}" dy="1.2em" ${renderProperties(fontAttributes)}>${context.sliceName}</text>`;

        const viewBoxCoordinates = [0, 0,
                                    context.gridSize[0],
                                    context.gridSize[1]];

        const viewBox = `${viewBoxCoordinates[0].toString()} ${viewBoxCoordinates[1].toString()} ${viewBoxCoordinates[2].toString()} ${viewBoxCoordinates[3].toString()}`;

        const result = `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
                 version="1.1"
                 viewBox="${viewBox}"
                 xml:space="preserve"
                 preserveAspectRatio="xMidYMid meet"
                 width="${viewBoxCoordinates[2].toString()}"
                 height="${viewBoxCoordinates[3].toString()}"
            >
            <style>
            .volume-background {
                --colour-1: #F8F8F8;
                --colour-2: #F0F0F0;
                --size: 5px;
            
                background-color: var(--colour-1);
            
                background-image:  repeating-linear-gradient(45deg, var(--colour-2) 25%, transparent 25%, transparent 75%, var(--colour-2) 75%, var(--colour-2)), repeating-linear-gradient(45deg, var(--colour-2) 25%, var(--colour-1) 25%, var(--colour-1) 75%, var(--colour-2) 75%, var(--colour-2));
                background-position: 0 0, var(--size) var(--size);
                background-size: calc(var(--size) * 2) calc(var(--size) * 2);
            }
            </style>
            ${context.sharedRendering}
            ${labels}
            ${cells}
            ${legend}
            </svg>`;

        downloadText(result, 'text/svg', 'geospm_grid.svg');
    }


%}
end