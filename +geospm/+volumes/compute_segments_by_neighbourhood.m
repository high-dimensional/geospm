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

function result = compute_segments_by_neighbourhood()
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
        For each grid position, we look up its 4x4 neighbourhood entry.
        Each entry holds one or two segments.
        For each segment we produce the following:
        The linear position of the original grid position together
        with the linear position of its predecessor and its successor
        in the segment.
        
    %}
    
    persistent neighbourhoods;
    
    if isempty(neighbourhoods)
        
        %{
        neighbourhoods = {...
            {}, ...
            {[-1,  0; 0, -1]}, ...
            {[ 0, -1; 1,  0]}, ...
            {[-1,  0; 1,  0]}, ...
            {[ 0,  1;-1,  0]}, ...
            {[ 0,  1; 0, -1]}, ...
            {[ 0,  1;-1,  0], [ 0, -1; 1,  0]}, ...
            {[ 0,  1; 1,  0]}, ...
            {[ 1,  0; 0,  1]}, ...
            {[ 1,  0; 0,  1], [-1,  0; 0, -1]}, ...
            {[ 0, -1; 0,  1]}, ...
            {[-1,  0; 0,  1]}, ...
            {[ 1,  0;-1,  0]}, ...
            {[ 1,  0; 0, -1]}, ...
            {[ 0, -1;-1,  0]}, ...
            {} ... 
        };
        %}
        neighbourhoods = {...
            {}, ...
            {[ 0, -1;-1,  0]}, ...
            {[ 1,  0; 0, -1]}, ...
            {[ 1,  0;-1,  0]}, ...
            {[-1,  0; 0,  1]}, ...
            {[ 0, -1; 0,  1]}, ...
            {[-1,  0; 0,  1], [ 1,  0; 0, -1]}, ...
            {[ 1,  0; 0,  1]}, ...
            {[ 0,  1; 1,  0]}, ...
            {[ 0,  1; 1,  0], [0, -1; -1,  0]}, ...
            {[ 0,  1; 0, -1]}, ...
            {[ 0,  1;-1,  0]}, ...
            {[-1,  0; 1,  0]}, ...
            {[ 0, -1; 1,  0]}, ...
            {[-1,  0; 0, -1]}, ...
            {} ...
        };
    end

    result = neighbourhoods;
end
