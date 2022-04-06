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

function [coords, rings, polygons] = trace_slice(bw_image)
    %Produces one or more polygons
    
    if ~islogical(bw_image)
        error('trace_slice() expects a logical array of pixels.');
    end
    
    %{


     4 8
     1 2

     o o    00
     o o

     x x    15
     x x

     o o    01 (-1,  0) ( 0, -1)
     x o

     x x    14 ( 0, -1) (-1,  0)
     o x

     x o    04 ( 0,  1) (-1,  0)
     o o
 
     o x    11 (-1,  0) ( 0,  1)
     x x

     o x    08 ( 1,  0) ( 0,  1)
     o o

     x o    07 ( 0,  1) ( 1,  0)
     x x

     o o    02 ( 0, -1) ( 1,  0)
     o x

     x x    13 ( 1,  0) ( 0, -1)
     x o


     o x    10 ( 0, -1) ( 0,  1)
     o x

     x o    05 ( 0,  1) ( 0, -1)
     x o

     x x    12 ( 1,  0) (-1,  0)
     o o

     o o    03 (-1,  0) ( 1,  0)
     x x

     x o    06 ( 0, -1) ( 1,  0)
     o x       ( 0,  1) (-1,  0)

     o x    09 (-1,  0) ( 0, -1)
     x o       ( 1,  0) ( 0,  1)
    
    %}
    
    %{
        Each grid position (i, j) corresponds to a linear position k.
        For each grid position, we look up its 4x4 neighbourhood entry.
        Each entry holds one or two segments.
        For each segment we produce the following:
        The linear position of the original grid position together
        with the linear position of its predecessor and its successor
        in the segment.
        
        neighbourhoods = {...
            {}, ...
            {[-1,  0; 0, -1]}, ...
            {[ 0, -1; 1,  0]}, ...
            {[-1,  0; 1,  0]}, ...
            {[ 0,  1;-1,  0]}, ...
            {[ 0,  1; 0, -1]}, ...
            {[ 0, -1; 1,  0], [ 0,  1;-1,  0]}, ...
            {[ 0,  1; 1,  0]}, ...
            {[ 1,  0; 0,  1]}, ...
            {[-1,  0; 0, -1], [ 1,  0; 0,  1]}, ...
            {[ 0, -1; 0,  1]}, ...
            {[-1,  0; 0,  1]}, ...
            {[ 1,  0;-1,  0]}, ...
            {[ 1,  0; 0, -1]}, ...
            {[ 0, -1;-1,  0]}, ...
            {} ... 
    
            {}, ...
            {[ 0, -1; -1,  0]}, ...
            {[ 1,  0;  0, -1]}, ...
            {[ 1,  0; -1,  0]}, ...
            {[-1,  0;  0,  1]}, ...
            {[ 0, -1;  0,  1]}, ...
            {[ 1,  0;  0, -1], [-1,  0; 0,  1]}, ...
            {[ 1,  0;  0,  1]}, ...
            {[ 0,  1;  1,  0]}, ...
            {[ 0, -1; -1,  0], [ 0,  1; 1,  0]}, ...
            {[ 0,  1;  0, -1]}, ...
            {[ 0,  1; -1,  0]}, ...
            {[-1,  0;  1,  0]}, ...
            {[ 0, -1;  1,  0]}, ...
            {[-1,  0;  0, -1]}, ...
            {} ... 
        };
    %}
    
    persistent neighbourhoods;
    
    if isempty(neighbourhoods)
        
        neighbourhoods = {...
            {}, ...
            {[-1,  0; 0, -1]}, ...
            {[ 0, -1; 1,  0]}, ...
            {[-1,  0; 1,  0]}, ...
            {[ 0,  1;-1,  0]}, ...
            {[ 0,  1; 0, -1]}, ...
            {[ 0, -1; 1,  0], [ 0,  1;-1,  0]}, ...
            {[ 0,  1; 1,  0]}, ...
            {[ 1,  0; 0,  1]}, ...
            {[-1,  0; 0, -1], [ 1,  0; 0,  1]}, ...
            {[ 0, -1; 0,  1]}, ...
            {[-1,  0; 0,  1]}, ...
            {[ 1,  0;-1,  0]}, ...
            {[ 1,  0; 0, -1]}, ...
            {[ 0, -1;-1,  0]}, ...
            {} ... 
        };
    end
    
    width = size(bw_image, 1);
    height = size(bw_image, 2);
    
    if width * height ~= numel(bw_image)
        error('trace_slice() expects a 2-dimensional array of pixels.');
    end
    
    %Embed the image into a temporal image with a 1-pixel wide margin
    tmp_bw_image = zeros(width + 2, height + 2, 'logical');
    tmp_bw_image(2:width + 1, 2:height + 1) = bw_image;
    
    %Create a field holding the neighbourhood type
    %The number of neighbourhoods along each dimension is one more than
    %the size of the dimension.
    n_types = zeros(width + 1, height + 1, 'uint8');
    
    for i=2:width + 2
        for j=2:height + 2
            
            n_types(i-1, j-1) =  1   + tmp_bw_image(i - 1, j - 1) ...
                                 + 8 * tmp_bw_image(i, j) ...
                                 + 4 * tmp_bw_image(i - 1, j) ...
                                 + 2 * tmp_bw_image(i, j - 1);
        end
    end
    
    dimensions = [width + 1, height + 1];
    N_unique_entries = dimensions(1) * dimensions(2);
    point_table = zeros(N_unique_entries, 6);
    N_unique_entries = 0;
    N_entries = 0;
    
    for i=1:width + 1
        for j=1:height + 1
            
            segments = neighbourhoods{n_types(i, j)};
            
            if numel(segments) ~= 0
                N_entries = N_entries + 1;
                N_unique_entries = N_unique_entries + 1;

                point_table = add_entry(i, j, dimensions, segments{1}, point_table, N_unique_entries, 0);
                point_table(N_unique_entries, 2) = 1;
            end
            
            if numel(segments) == 2
                N_entries = N_entries + 1;
                
                point_table = add_entry(i, j, dimensions, segments{2}, point_table, N_unique_entries, 2);
                point_table(N_unique_entries, 2) = 2;
            end
        end
    end
    
    point_table = point_table(1:N_unique_entries, :);
    
    point_table = sortrows(point_table);
    
    N_points = 0;
    points = zeros(N_entries * 2, 2, 'int64');
    
    N_locked_points = 0;
    
    N_rings = 0;
    rings = zeros(N_entries, 1, 'int64');
    rings(N_rings + 1) = 1;
    
    index = 1;
    start_index = index;
    variant = 0;
    
    while N_entries > 0
        
        key = point_table(index, 1);
        [points, N_points] = add_point_for_key(points, N_points, N_locked_points, key, dimensions);
        
        next_key = point_table(index, 4 + variant * 2);
        point_table(index, 2) = point_table(index, 2) - 1;
        
        if variant == 0
            point_table(index, 3:4) = point_table(index, 5:6);
        end
        
        point_table(index, 5:6) = 0;
        
        next_index = binary_search(point_table(:,1), next_key);
        
        index = next_index;
        N_entries = N_entries - 1;
        
        if next_index ~= start_index
            
            if next_index == 0
                error('trace_slices(): Implementation error.');
            end
            
            if point_table(next_index, 3) == key
                variant = 0;
            elseif point_table(next_index, 5) == key
                variant = 1;
            else
                error('trace_slices(): Implementation error.');
            end
            
        else
            
            variant = 0;
            
            key = point_table(index, 1);
            [points, N_points] = add_point_for_key(points, N_points, N_locked_points, key, dimensions);
        
            N_rings = N_rings + 1;
            rings(N_rings + 1) = N_points + 1;
            N_locked_points = N_points;
            
            did_find_start = false;
            
            for i=start_index:N_unique_entries
                if point_table(i, 2) > 0
                    index = i;
                    start_index = index;
                    did_find_start = true;
                    break;
                end
            end
            
            if ~did_find_start && N_entries > 0
                error('trace_slice(): Implementation error.');
            end
        end
    end
    
    points = points(1:N_points, :);
    rings = rings(1:N_rings);
    
    [coords, rings, polygons] = hdng.geometry.utilities.polygons_from_rings(points, rings);
end


function plot_polygon(points, rings)

    N_rings = size(rings, 1);
    safe_rings = [rings; size(points, 1) + 1];
    
    X = {};
    Y = {};
    
    figure;
    
    hold on;
    
    for i=1:N_rings
        
        first = safe_rings(i);
        last = safe_rings(i + 1) - 1;

        X = {points(first:last, 1)}; %#ok<AGROW>
        Y = {points(first:last, 2)}; %#ok<AGROW>
        
        
        p = polyshape(X, Y, 'SolidBoundaryOrientation', 'ccw');
        plot(p);
    end
    
    hold off;

    %p = polyshape(X, Y, 'SolidBoundaryOrientation', 'ccw');
    
    %plot(p);
end

function [points, N_points] = add_point_for_key(points, N_points, N_locked_points, key, dimensions)
    
    N_points = N_points + 1;
    [points(N_points, 1), points(N_points, 2)] = ind2sub(dimensions, key);
    
    %fprintf('[%d, %d]\n', points(N_points, 1), points(N_points, 2));
    
    if N_points - N_locked_points > 2
        
        p1 = points(N_points - 2, :);
        p2 = points(N_points - 1, :);
        p3 = points(N_points,     :);
        
        colinear_point = false;
        
        if p1(1) == p2(1) && p2(1) == p3(1)
            colinear_point = true;
        elseif p1(2) == p2(2) && p2(2) == p3(2)
            colinear_point = true;
        end

        if colinear_point
            points(N_points - 1, :) = points(N_points, :);
            N_points = N_points - 1;
        end
    end
end

function table = add_entry(h, v, dimensions, segment, table, index, column_offset)

    table(index, 1) = sub2ind(dimensions, h, v);

    p = [h, v] + segment(1, :);
    table(index, column_offset + 3) = sub2ind(dimensions, p(1), p(2));
    
    p = [h, v] + segment(2, :);
    table(index, column_offset + 4) = sub2ind(dimensions, p(1), p(2));
end

function [index_or_zero, insert_at] = binary_search(value_array, value)

    index_or_zero = 0;   
    insert_at = 0;
    
    N = cast(numel(value_array), 'int64');

    two = cast(2, 'int64');
    start = cast(1, 'int64');
    limit = cast(N + 1, 'int64');
    
    while start < limit

        pivot = start + idivide(limit - start, two, 'floor');

        if value <= value_array(pivot)
            limit = pivot;
        else
            start = pivot + 1;
        end
    end

    start = cast(start, 'double');
    
    if start <= N && value == value_array(start)
        index_or_zero = start;
    else
        insert_at = start;
    end
end
