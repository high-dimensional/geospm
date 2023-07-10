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

     x o    06 ( 0,  1) (-1,  0)
     o x       ( 0, -1) ( 1,  0)

     o x    09 ( 1,  0) ( 0,  1)
     x o       (-1,  0) ( 0, -1)
    
    %}
    
    %{
        Each grid position (i, j) corresponds to a linear position k.
        For each grid position, we look up its 2x2 cell neighbourhood entry.
        
        Each entry holds one or two segments.
        For each segment we produce the following:
        The linear position of the original grid position together
        with the linear position of its predecessor and its successor
        in the segment.
        
    %}
    
    height = size(bw_image, 1);
    width = size(bw_image, 2);
    
    if width * height ~= numel(bw_image)
        error('trace_slice() expects a 2-dimensional array of pixels.');
    end
    
    %Embed the image into a temporal image with a 1-pixel wide margin
    tmp_bw_image = zeros(height + 2, width + 2, 'logical');
    tmp_bw_image(2:height + 1, 2:width + 1) = bw_image;
    
    %Create a field holding the neighbourhood type
    %The number of neighbourhoods along each dimension is one more than
    %the size of the dimension.
    n_types = zeros(height + 1, width + 1, 'uint8');
    
    for y=2:height + 2
        for x=2:width + 2
            
            %n_types(y-1, x-1) =  1   + tmp_bw_image(y - 1, x - 1) ...
            %                     + 8 * tmp_bw_image(y, x) ...
            %                     + 4 * tmp_bw_image(y - 1, x) ...
            %                     + 2 * tmp_bw_image(y, x - 1);

            n_types(y-1, x-1) = geospm.volumes.compute_neighbourhood_index_at(tmp_bw_image, x, y);
        end
    end
    
    dimensions = [height + 1, width + 1];
    
    [segment_table, N_segments] = create_segment_table(dimensions, n_types);
    
    N_points = 0;
    points = zeros(N_segments * 2, 2, 'int64');
    
    N_locked_points = 0;
    
    N_rings = 0;
    rings = zeros(N_segments, 1, 'int64');
    rings(N_rings + 1) = 1;
    
    row_index = 1;
    start_row_index = row_index;
    
    position = [];

    % (1) We loop until each segment has been traversed exactly once
    % (2) Every time we reach the start_row_index, we have found a ring
    
    while N_segments > 0

        if row_index == start_row_index
            previous_position = [];
        else
            previous_position = position;
        end

        position = segment_table(row_index, 1);

        [points, N_points] = add_point_for_position(position, dimensions, points, N_points, N_locked_points);
        
        [segment_table, row_index] = traverse_segment_at_row(segment_table, row_index, previous_position);
        
        N_segments = N_segments - 1;
        
        if row_index == start_row_index

            % We have closed the current ring:
            % Add the last point and lock in all the points in the ring.
            
            position = segment_table(row_index, 1);
            [points, N_points] = add_point_for_position(position, dimensions, points, N_points, N_locked_points);
        
            N_rings = N_rings + 1;
            rings(N_rings + 1) = N_points + 1;
            N_locked_points = N_points;
            
            row_index = find(segment_table(:, 2) > 0, 1);
            start_row_index = row_index;
            
            if N_segments > 0 && isempty(row_index)
                error('trace_slice(): Implementation error.');
            end
        end
    end
    
    points = points(1:N_points, :);
    rings = rings(1:N_rings);
    
    [coords, rings, polygons] = hdng.geometry.utilities.polygons_from_rings(points, rings);
end

function [segment_table, next_row_index] = traverse_segment_at_row(segment_table, row_index, previous_position)
    
    if segment_table(row_index, 2) == 0
        error('traverse_segment_at_row(): Implementation error, no segments at current position in segment table.');
    end
    
    segment_index = 0;

    if ~isempty(previous_position)
        segment_index = find(segment_table(row_index, [3, 5]) == previous_position, 1) - 1;
    end

    % at the current position, retrieves the second point of the segment indicated by variant
    next_position = segment_table(row_index, 4 + segment_index * 2);

    % decrement segment count at the current position
    segment_table(row_index, 2) = segment_table(row_index, 2) - 1;
    
    if segment_index == 0
        % moves a potentially available second segment to the slot of
        % the first
        segment_table(row_index, 3:4) = segment_table(row_index, 5:6);
    end

    % the segment count is now either 0 or 1
    d = segment_table(row_index, 2);
    
    % zero-out deleted segment
    segment_table(row_index, (3:4) + d + d) = 0;

    next_row_index = binary_search(segment_table(:,1), next_position);

    if next_row_index == 0
        error('traverse_segment_at_row(): Implementation error, could not find next position in segment table.');
    end
end


function [segment_table, N_segments] = create_segment_table(dimensions, n_types)
    
    % Creates a table holding one or two segments per row, were each row
    % corresponds to one of the positions in the grid

    segments_by_neighbourhood = geospm.volumes.compute_segments_by_neighbourhood();

    N_positions = dimensions(1) * dimensions(2);

    % segment_table:
    %
    % One row per position in the grid
    %
    % column 1: linear index into grid
    % column 2: number of segments (1 or 2)
    % column 3: linear index segment 1, point 1
    % column 4: linear index segment 1, point 2
    % column 5: linear index segment 2, point 1
    % column 6: linear index segment 2, point 2

    segment_table = zeros(N_positions, 9);
    
    N_positions = 0;
    N_segments = 0;
    
    for x=1:dimensions(2)
        for y=1:dimensions(1)
            
            segments = segments_by_neighbourhood{n_types(y, x)};
            
            if numel(segments) ~= 0
                N_positions = N_positions + 1;
                N_segments = N_segments + 1;

                segment_table = add_position_segment(x, y, dimensions, segments{1}, segment_table, N_positions, 0);
                segment_table(N_positions, 2) = 1;
                segment_table(N_positions, 9) = n_types(y, x);
            end
            
            if numel(segments) == 2
                N_segments = N_segments + 1;
                
                segment_table = add_position_segment(x, y, dimensions, segments{2}, segment_table, N_positions, 2);
                segment_table(N_positions, 2) = 2;
            end
        end
    end

    segment_table = segment_table(1:N_positions, :);
    segment_table = sortrows(segment_table);

    % segment_table: Entries sorted by ascending position index, segment
    % count...
end


function table = add_position_segment(x, y, dimensions, segment, table, index, column_offset)

    table(index, 1) = sub2ind(dimensions, y, x);
    table(index, 7) = x;
    table(index, 8) = y;

    p = [x, y] + segment(1, :);
    table(index, column_offset + 3) = sub2ind(dimensions, p(2), p(1));
    
    p = [x, y] + segment(2, :);
    table(index, column_offset + 4) = sub2ind(dimensions, p(2), p(1));
end

function [points, N_points] = add_point_for_position(position, dimensions, points, N_points, N_locked_points)
    
    N_points = N_points + 1;

    [points(N_points, 1), points(N_points, 2)] = ind2sub(dimensions, position);
    
    %fprintf('[%d, %d]\n', points(N_points, 1), points(N_points, 2));
    
    ring_length = N_points - N_locked_points;

    if ring_length > 2
        
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

function plot_polygon(points, rings)

    N_rings = size(rings, 1);
    safe_rings = [rings; size(points, 1) + 1];
    
    figure;
    
    hold on;
    
    for i=1:N_rings
        
        first = safe_rings(i);
        last = safe_rings(i + 1) - 1;

        X = {points(first:last, 1)};
        Y = {points(first:last, 2)};
        
        
        p = polyshape(X, Y, 'SolidBoundaryOrientation', 'ccw');
        plot(p);
    end
    
    hold off;
end
