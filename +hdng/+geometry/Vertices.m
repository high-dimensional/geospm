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

classdef Vertices < hdng.geometry.Buffer
    %Vertices Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        N_vertices
        coordinates
        x
        y
        z
        has_z
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = Vertices()
            obj = obj@hdng.geometry.Buffer();
        end
        
        function result = get.N_vertices(obj)
            result = obj.access_N_vertices();
        end
        
        function result = get.coordinates(obj)
            result = obj.access_coordinates();
        end
        
        function result = get.x(obj)
            result = obj.access_x();
        end
        
        function result = get.y(obj)
            result = obj.access_y();
        end
        
        function result = get.z(obj)
            result = obj.access_z();
        end
        
        function result = get.has_z(obj)
            result = obj.access_has_z();
        end
        
        function result = nth_vertex_as_point(obj, index)
            
            if index < 0
                index = obj.N_vertices + index + 1;
            end
            
            coords = obj.coordinates(index, :);
            result = hdng.geometry.Point.define(coords(1), coords(2));
        end
        
        function result = premultiply_xy(obj, matrix23, first, last)
            
            if ~exist('first', 'var')
                first = 1;
            end
            
            if ~exist('last', 'var')
                last = obj.N_vertices;
            end
            
            if ~isnumeric(matrix23)
                error('premultiply_xy(): matrix must be numeric.');
            end
            
            if ~isequal(size(matrix23), [2, 3])
                error('premultiply_xy(): matrix must have 2 rows and 3 columns.');
            end
            
            is_valid_range = first >= 1 && first <= last;
            
            if ~is_valid_range
                result = hdng.geometry.Vertices.define([]);
                return;
            end
            
            M = eye(3);
            M(1:2,1:3) = matrix23;
            
            M = matrix23(1:2, 1:2);
            T = matrix23(1:2, 3);
            
            coords = obj.coordinates(:, 1:2);
            coords = coords * M' + T;
            
            result = hdng.geometry.Vertices.define(coords);
        end
        
        function [min_coords, max_coords, indices] = extent(obj, first, last)
            
            if ~exist('first', 'var')
                first = 1;
            end
            
            if ~exist('last', 'var')
                last = obj.N_vertices;
            end
            
            is_valid_range = first >= 1 && first <= last;
            
            X = obj.x;
            Y = obj.y;
            Z = obj.z;
            
            if is_valid_range
                min_coords = [X(first), Y(first)];
                max_coords = [X(first), Y(first)];
                indices = [1, 1; 1, 1];
            else
                min_coords = [];
                max_coords = [];
                indices = [0, 0; 0, 0];
            end
            
            for index=first + 1:last
                
                if X(index) < min_coords(1)
                    min_coords(1) = X(index);
                    indices(1, 1) = index;
                end
                
                if Y(index) < min_coords(2)
                    min_coords(2) = Y(index);
                    indices(2, 1) = index;
                end
                
                if X(index) > max_coords(1)
                    max_coords(1) = X(index);
                    indices(1, 2) = index;
                end
                
                if Y(index) > max_coords(2)
                    max_coords(2) = Y(index);
                    indices(2, 2) = index;
                end
            end

            if obj.has_z
                
                if is_valid_range

                    min_coords(3) = Z(first);
                    max_coords(3) = Z(first);
                    indices(3, 1) = 1;
                    indices(3, 2) = 1;
                else
                    indices(3, 1) = 0;
                    indices(3, 2) = 0;
                end

                for index=first + 1:last

                    if Z(index) < min_coords(3)
                        min_coords(3) = Z(index);
                        indices(3, 1) = index;
                    end

                    if Z(index) > max_coords(3)
                        max_coords(3) = Z(index);
                        indices(3, 2) = index;
                    end
                end
            end
        end
        
        function [indices] = convex_extremes_xy(obj, first, last)
            
            if ~exist('first', 'var')
                first = 1;
            end
            
            if ~exist('last', 'var')
                last = obj.N_vertices;
            end
            
            first = cast(first, 'int64');
            last = cast(last, 'int64');
            
            is_valid_range = first >= 1 && first <= last;
            
            X = obj.x;
            Y = obj.y;
            
            if is_valid_range
                c = cast(first, 'int64');
                min_coords = [X(first), Y(first)];
                max_coords = [X(first), Y(first)];
            else
                c = cast(0, 'int64');
                min_coords = [];
                max_coords = [];
            end

            min_indices = {{c, c}; {c, c}};
            max_indices = {{c, c}; {c, c}};
            
            coords = obj.coordinates;
            
            for index=first:last
                
                if X(index) < min_coords(1)
                    
                    min_coords(1) = X(index);
                    min_indices{1} = {index, index};
                    
                elseif X(index) == min_coords(1)
                    
                    r = min_indices{1};
                    
                    if Y(index) < coords(r{1}, 2)
                        r{1} = index;
                    end
                    
                    if Y(index) > coords(r{2}, 2)
                        r{2} = index;
                    end
                    
                    min_indices{1} = r;
                end
                
                if Y(index) < min_coords(2)
                    
                    min_coords(2) = Y(index);
                    min_indices{2} = {index, index};
                    
                elseif Y(index) == min_coords(2)
                    
                    r = min_indices{2};
                    
                    if X(index) < coords(r{1}, 1)
                        r{1} = index;
                    end
                    
                    if X(index) > coords(r{2}, 1)
                        r{2} = index;
                    end
                    
                    min_indices{2} = r;
                end
                
                if X(index) > max_coords(1)
                    
                    max_coords(1) = X(index);
                    max_indices{1} = {index, index};
                    
                elseif X(index) == max_coords(1)
                    
                    r = max_indices{1};
                    
                    if Y(index) < coords(r{1}, 2)
                        r{1} = index;
                    end
                    
                    if Y(index) > coords(r{2}, 2)
                        r{2} = index;
                    end
                    
                    max_indices{1} = r;
                end
                
                if Y(index) > max_coords(2)
                    
                    max_coords(2) = Y(index);
                    max_indices{2} = {index, index};
                    
                elseif Y(index) == max_coords(2)
                    
                    r = max_indices{2};
                    
                    if X(index) < coords(r{1}, 1)
                        r{1} = index;
                    end
                    
                    if X(index) > coords(r{2}, 1)
                        r{2} = index;
                    end
                    
                    max_indices{2} = r;
                end
            end
            
            
            all_indices = [min_indices{1}, min_indices{2}, max_indices{1}, max_indices{2}];
            all_indices = cell2mat(all_indices)';
            
            indices = [];
            
            for i=1:8
                if any(indices == all_indices(i))
                    continue;
                end
                
                indices = [indices; all_indices(i)]; %#ok<AGROW>
            end
        end
        
        function result = is_clockwise_xy(obj, first, last)
            
            if ~exist('first', 'var')
                first = 1;
            end
            
            if ~exist('last', 'var')
                last = obj.N;
            end
            
            X = obj.x;
            Y = obj.y;
            
            indices = obj.convex_extremes_xy(first, last);
            
            for i=1:numel(indices)
                
                index = indices(i);
                [prev, next] = obj.previous_and_next(index, first, last);
                
                x1 = X(prev);
                x2 = X(index);
                x3 = X(next);

                y1 = Y(prev);
                y2 = Y(index);
                y3 = Y(next);

                D = (x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1);
                
                if D > 0.0
                    result = false;
                    return;
                elseif D < 0.0
                    result = true;
                    return;
                end
            end
            
            warning('hdng.geometry.Vertices.is_counterclockwise_xy(): Polygon consists of colinear vertices, returning ''true'' by default.');
            result = true;
        end
        
        function [prev, next] = previous_and_next(obj, index, first, last)
            
            if ~exist('first', 'var')
                first = 1;
            end
            
            if ~exist('last', 'var')
                last = obj.N;
            end
            
            M = last - first + 1;
            
            prev = mod(index - first - 1, M) + first;
            next = mod(index - first + 1, M) + first;
        end
        
        function result = contains(obj, x, y, first, last)
            
            if ~exist('first', 'var')
                first = 1;
            end
            
            if ~exist('last', 'var')
                last = obj.N;
            end
            
            X = obj.x;
            Y = obj.y;
            
            result = zeros(1, 1, 'logical');
            j = last;

            for i=first:last
                
                edge_crosses = ((Y(i) > y) ~= (Y(j) > y));
                
                if edge_crosses && (x < (X(j) - X(i)) * (y - Y(i)) / (Y(j) - Y(i)) + X(i))
                    result = ~result;
                end
                
                j = i;
            end
        end
    end
    
    methods (Static)
        
        function result = define(array, stride)
            
            if ~exist('stride', 'var')
                stride = 1;
            end
            
            result = hdng.geometry.impl.VerticesImpl(array, stride);
        end
        
    end
    
    methods (Access = protected)
        
        function result = access_N_vertices(obj)
            result = obj.N_strides;
        end
        
        function result = access_coordinates(obj)
            
            if obj.stride == 1
                result = obj.array;
            else
                error('access_coordinates() retrieving coordinates for array strides other than 1 not yet implemented.');
            end
        end
        
        function result = access_x(~) %#ok<STOUT>
            error('access_x() must be implemented by a subclass.');
        end
        
        function result = access_y(~) %#ok<STOUT>
            error('access_y() must be implemented by a subclass.');
        end
        
        function result = access_z(~) %#ok<STOUT>
            error('access_z() must be implemented by a subclass.');
        end
        
        function result = access_has_z(obj)
            result = size(obj.array, 2) >= 3;
        end
        
    end
    
    
end
