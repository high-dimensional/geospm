function result = render_shape(shape, transform)
    result = '';

    if ~exist('transform', 'var')
        transform = eye(2, 3);
    end

    T = eye(3);
    T(1:2, 1:3) = transform;

    switch shape.Geometry
        case 'Polygon'
            result = render_polygon(shape, T);
        otherwise

    end
end

function result = render_polygon(shape, transform)
    
    rings = {};
    ring_start = 1;

    while ring_start <= numel(shape.X)

        if isnan(shape.X(ring_start))
            ring_start = ring_start + 1;
            continue
        end
        
        for ring_end=ring_start:1 + numel(shape.X)
            if ring_end > numel(shape.X) || isnan(shape.X(ring_end))
                break
            end
        end
        
        ring_end = ring_end - 1;
        
        if ring_end - ring_start >= 2

            x = shape.X(ring_start:ring_end);
            y = shape.Y(ring_start:ring_end);
            
            T = transform * [x; y; ones(1, numel(x))];
            
            x = T(1, :);
            y = T(2, :);

            if x(1) == x(end) && y(1) == y(end)
                x = x(1:end - 1);
                y = y(1:end - 1);
            end
    
            fragments = cell(numel(x), 1);
    
            for i=1:numel(x)
                fragments{i} = sprintf('%g,%g', x(i), y(i));
            end
    
            coords = join(fragments, ' ');
            rings{end + 1} = sprintf('M %sZ', coords{1}); %#ok<AGROW>
        end

        ring_start = ring_end + 1;
    end
    
    %{
    result = '';
    breaks = isnan(shape.X);
    
    %X = shape.X(~breaks);
    %Y = shape.Y(~breaks);
    
    N_rings = any(~breaks) + sum(breaks(2:end - 1));
    
    ring_indices = [1 find(breaks(2:end - 1)) + 1];
    
    rings = cell(N_rings, 1);

    for r=1:N_rings
        ring_start = ring_indices(r);

        if r + 1 <= numel(ring_indices)
            ring_end = ring_indices(r + 1) - 1;
        else
            ring_end = 0;
        end

    end

    for r=1:numel(ring_indices)
        ring_start = ring_indices(r) + 1;

        if r + 1 <= numel(ring_indices)
            ring_end = ring_indices(r + 1) - 1;
        else
            ring_end = 0;
        end

        if ring_start >= ring_end
            rings{r} = '';
            continue;
        end

        x = shape.X(ring_start:ring_end);
        y = shape.Y(ring_start:ring_end);
        
        T = transform * [x; y; ones(1, numel(x))];
        
        x = T(1, :);
        y = T(2, :);

        fragments = cell(ring_end - ring_start - 1, 1);

        for i=1:numel(x)
            fragments{i} = sprintf('%g,%g', x(i), y(i));
        end

        coords = join(fragments, ' ');
        rings{r} = sprintf('M %sZ', coords{1});
    end
    
    if numel(rings) == 1 && strcmp(rings{1}, '')
        return;
    end
    
    %}
    
    if isempty(rings)
        result = '';
        return;
    end
    
    rings = join(rings, ' ');
    rings = rings{1};

    result = sprintf('<path d="%s"/>', rings);
end

