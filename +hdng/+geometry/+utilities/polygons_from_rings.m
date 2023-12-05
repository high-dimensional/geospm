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

function [coords, rings, polygons] = polygons_from_rings(points, rings)
    
    if size(points, 1) == 0
        coords = [];
        rings = [];
        polygons = [];
        return;
    end

    vertices = hdng.geometry.Vertices.define(cast(points, 'double'), 1);
    
    N_rings = numel(rings);
    holes = zeros(1, N_rings, 'logical');
    
    safe_rings = cat(1, rings, vertices.N_vertices + 1);
    
    for i=1:N_rings
        
        first = safe_rings(i);
        last = safe_rings(i + 1) - 2;
        holes(i) = ~vertices.is_clockwise_xy(first, last);
    end
    
    extents = compute_ring_extents(rings, vertices);

    % This is just an estimate of containment, as we are only checking
    % bounding boxes, not the polygons themselves

    C = compute_containment_matrix(extents);
    
    % Make sure that rings which are not holes are not marked as being
    % contained

    C = C & repmat(holes, N_rings, 1);

    C = fix_containment_matrix(C, points, safe_rings);

    all_ones = ones(N_rings, N_rings, 'logical');
    available = ones(1, N_rings, 'logical');
    
    tops = [];
    
    state = create_state(points, safe_rings);
    
    while true
        
        if isempty(tops)
            
            tops = ~any(C) & available;
            
            orphaned_tops = tops & holes;
            
            if any(orphaned_tops)
                warning('polygons_from_rings(): Encountered one or more orphaned holes. Converting to exterior boundaries.');
                holes = holes & ~orphaned_tops;
            end
            
            tops = find(tops);
            
            if isempty(tops)
                break;
            end
        end
        
        %index = first available top ring
        index = tops(1);
        tops = tops(2:end);
        available(index) = false;
        
        %Candidates is a bit mask of holes which are contained in ring[index]
        candidates = C(index, :) & holes & available;
        
        %CC is the containment matrix of the candidates
        CC = C & all_ones * diag(candidates) & diag(candidates) * all_ones;
        
        %Children is a bit mask of all direct children of the current top
        %ring that are holes
        children = ~any(CC) & candidates;
        
        
        C = C & all_ones * diag(~children);
        available(children) = false;
        
        children = find(children);
        
        state = define_polygon(index, children, state);
    end
    
    coords   = state.target_coords;
    rings    = state.target_rings;
    polygons = state.target_polygons;
end

function state = create_state(coords, rings)
    state = struct();
    
    state.source_coords = coords;
    state.source_rings = rings;
    
    state.target_coords = [];
    state.target_polygons = [];
    state.target_rings = [];
end

function state = define_polygon(index, children, state)

    state.target_polygons = [state.target_polygons; size(state.target_rings, 1) + 1];
    state = copy_ring(index, state);
    
    for i=1:numel(children)
        child = children(i);
        state = copy_ring(child, state);
    end
end

function state = copy_ring(index, state)

    first = state.source_rings(index);
    last  = state.source_rings(index + 1) - 1;
    
    state.target_rings = [state.target_rings; size(state.target_coords, 1) + 1];
    state.target_coords = [state.target_coords; state.source_coords(first:last, :)];
end

function extents = compute_ring_extents(rings, vertices)
    
    N_rings = numel(rings);
    rings = [rings; vertices.N_vertices + 1];
    
    extents = zeros(N_rings, 4);
    
    for i=1:N_rings
        
        first = rings(i);
        last = rings(i + 1) - 1;
        
        [min_coords, max_coords] = vertices.extent(first, last);
        
        extents(i, 1:2) = min_coords(1:2);
        extents(i, 3:4) = max_coords(1:2);
    end
end

function result = compute_containment_matrix(extents)
    
    N = size(extents, 1);
    M = zeros(N, N, 'logical');
        
    for i=1:N
        for j=i + 1:N
            
            j_in_i = is_covered_by(extents(j, 1:2), extents(j, 3:4), ...
                                   extents(i, 1:2), extents(i, 3:4));
                               
            i_in_j = is_covered_by(extents(i, 1:2), extents(i, 3:4), ...
                                   extents(j, 1:2), extents(j, 3:4));
            
            M(i, j) = j_in_i;
            M(j, i) = i_in_j;
        end
    end
    
    result = M;
end

function result = is_covered_by(c_min, c_max, p_min, p_max)
    % Is the rectangle defined by c_min and c_max covered by
    % the rectangle defined by p_min and p_max.

    result =    p_min(1) <= c_min(1) ...
             && p_min(2) <= c_min(2) ...
             && p_max(1) >= c_max(1) ...
             && p_max(2) >= c_max(2) ...
             ;
end

function result = fix_containment_matrix(C, points, safe_rings)
    
    result = C;
    [container, component] = ind2sub(size(C), find(C(:)));

    vertices = hdng.geometry.Vertices.define(points);
    
    for index=1:numel(component)
        K = container(index);
        k = component(index);
        
        is_contained = true;

        for p=safe_rings(k):safe_rings(k + 1) - 1

            is_contained = vertices.contains(points(p, 1), points(p, 2), safe_rings(K), safe_rings(K + 1) - 1);

            if ~is_contained
                break;
            end
        end

        if ~is_contained
            result(K, k) = 0;
        end
    end
end

function plot_shapes()

    %{
    figure;
    
    for i=1:N_rings
        
        first = safe_rings(i);
        last = safe_rings(i + 1) - 2;
        
        p = polyshape(vertices.coordinates(first:last, 1), ...
                      vertices.coordinates(first:last, 2), ...
                      'SolidBoundaryOrientation', 'ccw');
        
        plot(p);
    end
    %}
end
