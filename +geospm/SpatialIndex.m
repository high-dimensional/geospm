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

classdef SpatialIndex < geospm.BaseSpatialIndex
    %SpatialIndex A spatial index stores coordinates grouped
    % into segments.
    %


    properties (Dependent, Transient)
        
        N % number of rows

        x % a column vector of length N (a N by 1 matrix) of observation x locations
        y % a column vector of length N (a N by 1 matrix) of observation y locations
        z % a column vector of length N (a N by 1 matrix) of observation z locations

        xyz

        segment_offsets % a column vector of length S specifying the index of the first coordinate for each segment
        segment_sizes % a column vector of length S listing the number of coordinates per segment
        segment_index % a column vector of length N specifying the segment index for each coordinate
        
        x_min % minimum x value
        x_max % maximum x value
        
        y_min % minimum y value
        y_max % maximum y value
        
        z_min % minimum z value
        z_max % maximum z value
        
        min_xy % [min_x, min_y]
        max_xy % [max_x, max_y]
        span_xy % max_xy - min_xy
        
        min_xyz % [min_x, min_y, min_z]
        max_xyz % [max_x, max_y, max_z]
        span_xyz % max_xyz - min_xyz
        
        centroid_x
        centroid_y
        centroid_z
        
        centroid_xyz
        
        square_min_xy
        square_max_xy
        square_xy % Centres a square around the rectangle spanned by min_xy and max_xy

        cube_min_xyz
        cube_max_xyz
        cube_xyz % Centres a cube around the volume spanned by min_xyz and max_xyz
        
    end
    
    properties (GetAccess = private, SetAccess = private)
        
        x_
        y_
        z_

        extra_data_

        segment_sizes_
        segment_labels_

        segment_index_
        segment_offsets_

        x_min_
        x_max_
        
        y_min_
        y_max_
        
        z_min_
        z_max_
        
        centroid_xyz_
    end
    
    methods
        
        function obj = SpatialIndex(x, y, z, segment_sizes, segment_labels, crs, extra_data)
            %Construct a SpatialIndex object from x, y and z vectors and an
            %optional CRS.
            % x ? x locations
            % y ? y locations
            % z ? z locations or empty
            % segment_sizes ?  
            % crs ? coordinate reference system or empty
            
            if ~exist('crs', 'var')
                crs = hdng.SpatialCRS.empty;
            end
            
            if ~exist('extra_data', 'var')
                extra_data = [];
            end
            
            if ~ismatrix(x) || size(x, 2) ~= 1
                error('''x'' is not a numeric value; specify ''x'' as a N x 1 matrix');
            end
            
            if ~ismatrix(y) || size(y, 2) ~= 1
                error('''y'' is not a numeric value; specify ''y'' as a N x 1 matrix');
            end
            
            if ~ismatrix(z)
                error('''z'' is not a numeric value; specify ''z'' as a N x 1 matrix or []');
            end
            
            if size(x, 1) ~= size(y, 1)
                error('The number of elements in ''x'' (=%d) and ''y'' (=%d) do not match; specify both ''x'' and ''y'' as a N x 1 matrix', size(x,1), size(y,1));
            end
            
            if isempty(z)
                z = zeros(size(x));
            end
            
            if size(z, 2) ~= 1
                error('''z'' is not a numeric value; specify ''z'' as a N x 1 matrix or []');
            end
            
            if size(x, 1) ~= size(z, 1)
                error('The number of elements in ''x'' (=%d) and ''z'' (=%d) do not match; specify ''x'', ''y'' and ''z'' each as a N x 1 matrix', size(x,1), size(z,1));
            end

            if isempty(segment_sizes)
                segment_sizes = ones(size(x, 1), 1);
            end

            if isempty(segment_labels)
                segment_labels = arrayfun(@(x) num2str(x), (1:numel(segment_sizes))', 'UniformOutput', false);
            end
            
            if ~isempty(extra_data) && ~ismatrix(extra_data)
                error('''extra_data'' is not a numeric matrix.');
            end
            
            if ~isempty(extra_data) && size(x, 1) ~= size(extra_data, 1)
                error('The number of rows in ''x'' (=%d) and ''extra'' (=%d) do not match; specify ''extra_data''as a N x k matrix', size(x,1), size(extra_data,1));
            end
            
            obj = obj@geospm.BaseSpatialIndex(crs);
            
            obj.x_ = x;
            obj.y_ = y;
            obj.z_ = z;

            obj.extra_data_ = extra_data;
            
            obj.segment_sizes_ = segment_sizes;
            obj.segment_labels_ = segment_labels;

            [obj.segment_index_, obj.segment_offsets_] = obj.segment_indices_from_segment_sizes(size(x, 1), segment_sizes);
        end

        function result = get.N(obj)
            result = obj.access_N();
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
        
        function result = get.xyz(obj)
            result = obj.access_xyz();
        end

        function result = get.segment_index(obj)
            result = obj.access_segment_index();
        end
        
        function result = get.segment_sizes(obj)
            result = obj.access_segment_sizes();
        end

        function result = get.segment_offsets(obj)
            result = obj.access_segment_offsets();
        end
        
        function result = get.x_min(obj)
            result = obj.access_x_min();
        end
        
        function result = get.x_max(obj)
            result = obj.access_x_max();
        end
        
        function result = get.y_min(obj)
            result = obj.access_y_min();
        end
        
        function result = get.y_max(obj)
            result = obj.access_y_max();
        end
        
        function result = get.z_min(obj)
            result = obj.access_z_min();
        end
        
        function result = get.z_max(obj)
            result = obj.access_z_max();
        end
        
        function result = get.min_xy(obj)
            result = obj.access_min_xy();
        end
        
        function result = get.max_xy(obj)
            result = obj.access_max_xy();
        end
        
        function result = get.span_xy(obj)
            result = obj.access_span_xy();
        end
        
        function result = get.min_xyz(obj)
            result = obj.access_min_xyz();
        end
        
        function result = get.max_xyz(obj)
            result = obj.access_max_xyz();
        end

        function result = get.span_xyz(obj)
            result = obj.access_span_xyz();
        end
        
        function result = get.centroid_x(obj)
            result = obj.access_centroid_x();
        end
        
        function result = get.centroid_y(obj)
            result = obj.access_centroid_y();
        end
        
        function result = get.centroid_z(obj)
            result = obj.access_centroid_z();
        end
        
        function result = get.centroid_xyz(obj)
            result = obj.access_centroid_xyz();
        end

        function result = get.square_min_xy(obj)
            result = obj.access_square_min_xy();
        end

        function result = get.square_max_xy(obj)
            result = obj.access_square_max_xy();
        end
        
        function result = get.square_xy(obj)
            result = obj.obj.access_square_xy();
        end

        function result = get.cube_min_xyz(obj)
            result = obj.access_cube_min_xyz();
        end

        function result = get.cube_max_xyz(obj)
            result = obj.access_cube_max_xyz();
        end
        
        function result = get.cube_xyz(obj)
            result = obj.access_cube_xyz();
        end

        function [x, y, z] = xyz_coordinates_for_segment(obj, segment_index)
            
            [first, last] = obj.range_for_segment(segment_index);

            x = obj.x(first:last);
            y = obj.y(first:last);
            z = obj.z(first:last);
        end
        
        function result = row_indices_from_segment_indices(obj, segment_indices)
            
            %{
            row_selection = zeros(obj.N, 1, 'logical');

            for index=1:numel(segment_indices)
                segment = segment_indices(index);

                first = obj.segment_offsets(segment);
                last = first + obj.segment_sizes(segment) - 1;

                row_selection(first:last) = 1;
            end

            result = find(row_selection);
            %}


            result = zeros(obj.N, 1);
            offset = 0;

            for index=1:numel(segment_indices)
                segment = segment_indices(index);
                
                k = obj.segment_sizes(segment);
                first = obj.segment_offsets(segment);
                last = first + k - 1;
                
                result(offset + 1:offset + k) = first:last;

                offset = offset + k;
            end
        end

        function result = segment_indices_from_row_indices(obj, row_indices)
            result = unique(obj.segment_index(row_indices));
        end
        
        function result = select_by_segment(obj, segment_selection, transform)
        
            if ~exist('segment_selection', 'var')
                segment_selection = [];
            end
            
            segment_selection = obj.normalise_segment_selection(segment_selection);
            
            if ~exist('transform', 'var')
                transform = @(specifier, modifier) specifier;
            end

            row_selection = obj.row_indices_from_segment_indices(segment_selection);
            result = obj.select(row_selection, [], transform);
        end
        
        function [spatial_index, segment_indices] = project(obj, grid, assigned_grid, as_integers)
            
            if ~exist('assigned_grid', 'var') || isempty(assigned_grid)
                assigned_grid = grid;
            end

            if ~exist('as_integers', 'var')
                as_integers = true;
            end
            
            % Select the subset of observations within the grid:
            
            [u, v, w] = grid.space_to_grid(obj.x, obj.y, obj.z, as_integers);
            
            row_indices = grid.clip_uvw(u, v, w);

            u = u(row_indices);
            v = v(row_indices);
            w = w(row_indices);
            
            x_projected = cast(u, 'double');
            y_projected = cast(v, 'double');
            z_projected = cast(w, 'double');

            segment_indices = obj.segment_indices_from_row_indices(row_indices);
            segment_sizes_new = obj.segment_indices_to_segment_sizes(obj.segment_index(row_indices));
            segment_labels = obj.segment_labels(segment_indices);

            spatial_index = geospm.SpatialIndex(x_projected, y_projected, z_projected, segment_sizes_new, segment_labels, obj.crs);
            
            spatial_index.attachments.assigned_grid = assigned_grid;
        end
        
        function result = convolve_segment(obj, segment_index, span_origin, span_limit, kernel)

            [x_segment, y_segment, z_segment] = obj.xyz_coordinates_for_segment(segment_index);
            
            selector = x_segment >= span_origin(1) & x_segment < span_limit(1) & y_segment >= span_origin(2) & y_segment < span_limit(2) & z_segment >= span_origin(3) & z_segment < span_limit(3);

            x_segment = x_segment(selector);
            y_segment = y_segment(selector);
            z_segment = z_segment(selector);

            N_locations = size(x_segment, 1);

            result = zeros(span_limit - span_origin);
            
            if N_locations > 1
                for index=1:N_locations
    
                    xi = x_segment(index);
                    yi = y_segment(index);
                    zi = z_segment(index);
                    
                    result(xi, yi, zi) = result(xi, yi, zi) + 1;
                end
    
                result = convn(result, kernel, 'same');
            else

                window_resolution = span_limit - span_origin;
                xyz_segment = [x_segment, y_segment, z_segment] - span_origin + 1;
 
                %If sample_location is (1, 1), then range_start is window_resolution
                %If sample_location is window_resolution, then range_start is 1
                
                range_start = window_resolution - xyz_segment + 1;
                range_end = range_start + window_resolution - 1;
                
                result = kernel(range_start(1):range_end(1), ...
                                range_start(2):range_end(2), ...
                                range_start(3):range_end(3));
            end
        end
       
        function result = as_json_struct(obj, varargin)
            %Creates a JSON representation of this SpatialIndex object.
            % The following fields can be provided in the options
            % argument:
            % None so far.
            
            [~] = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            specifier = struct();
            
            specifier.ctor = 'geospm.SpatialIndex';

            specifier.crs = '';

            if ~isempty(obj.crs)
                specifier.crs = obj.crs.identifier;
            end

            specifier.N = obj.N;
            specifier.S = obj.S;

            specifier.x = obj.x;
            specifier.y = obj.y;
            specifier.z = obj.z;
            
            specifier.segment_index = obj.segment_index;
            specifier.segment_sizes = obj.segment_sizes;
            specifier.segment_offsets = obj.segment_offsets;
            
            result = specifier;
        end
    end
    
    methods (Access=protected)

        function result = access_N(obj)
            result = size(obj.x_, 1);
        end

        function result = access_C(obj) %#ok<MANU>
            result = 0;
        end

        function result = access_x(obj)
            result = obj.x_;
        end
        
        function result = access_y(obj)
            result = obj.y_;
        end

        function result = access_z(obj)
            result = obj.z_;
        end
        
        function result = access_segment_sizes(obj)
            result = obj.segment_sizes_;
        end
        
        function result = access_segment_labels(obj)
            result = obj.segment_labels_;
        end
        
        function result = access_S(obj)
            result = size(obj.segment_sizes, 1);
        end
        
        function result = access_segment_index(obj)
            result = obj.segment_index_;
        end
        
        function result = access_segment_offsets(obj)
            result = obj.segment_offsets_(1:end - 1);
        end
        
        function result = access_x_min(obj)
            if isempty(obj.x_min_)
                obj.x_min_ = min(obj.x);
            end
            
            result = obj.x_min_;
        end
        
        function result = access_x_max(obj)
            if isempty(obj.x_max_)
                obj.x_max_ = max(obj.x);
            end
            
            result = obj.x_max_;
        end
        
        function result = access_y_min(obj)
            if isempty(obj.y_min_)
                obj.y_min_ = min(obj.y);
            end
            
            result = obj.y_min_;
        end
        
        function result = access_y_max(obj)
            if isempty(obj.y_max_)
                obj.y_max_ = max(obj.y);
            end
            
            result = obj.y_max_;
        end
        
        function result = access_z_min(obj)
            if isempty(obj.z_min_)
                obj.z_min_ = min(obj.z);
            end
            
            result = obj.z_min_;
        end
        
        function result = access_z_max(obj)
            if isempty(obj.z_max_)
                obj.z_max_ = max(obj.z);
            end
            
            result = obj.z_max_;
        end
        
        function result = access_min_xy(obj)
            result = [obj.x_min, obj.y_min];
        end
        
        function result = access_max_xy(obj)
            result = [obj.x_max, obj.y_max];
        end
        
        function result = access_span_xy(obj)
            result = obj.max_xy - obj.min_xy;
        end
        
        function result = access_min_xyz(obj)
            result = [obj.x_min, obj.y_min, obj.z_min];
        end
        
        function result = access_max_xyz(obj)
            result = [obj.x_max, obj.y_max, obj.z_max];
        end

        function result = access_span_xyz(obj)
            result = obj.max_xyz - obj.min_xyz;
        end
        
        function result = access_centroid_x(obj)
            result = obj.centroid_xyz(1);
        end
        
        function result = access_centroid_y(obj)
            result = obj.centroid_xyz(2);
        end
        
        function result = access_centroid_z(obj)
            result = obj.centroid_xyz(3);
        end
        
        function result = access_centroid_xyz(obj)
            if isempty(obj.centroid_xyz_)
                obj.centroid_xyz_ = [mean(obj.x), mean(obj.y), mean(obj.z)];
            end
            
            result = obj.centroid_xyz_;
        end

        function result = access_square_min_xy(obj)
            span = obj.max_xy - obj.min_xy;
            d = max(span);
            offsets = (span - d) / 2;
            result = obj.min_xy + offsets;
        end

        function result = access_square_max_xy(obj)
            span = obj.max_xy - obj.min_xy;
            d = max(span);
            offsets = (span - d) / 2;
            result = obj.max_xy - offsets;
        end
        
        function result = access_square_xy(obj)
            span = obj.max_xy - obj.min_xy;
            d = max(span);
            offsets = (span - d) / 2;
            square_min = obj.min_xy + offsets;
            square_max = obj.max_xy - offsets;
            result = [square_min; square_max];
        end

        function result = access_cube_min_xyz(obj)
            span = obj.max_xyz - obj.min_xyz;
            d = max(span);
            offsets = (span - d) / 2;
            result = obj.min_xyz + offsets;
        end

        function result = access_cube_max_xyz(obj)
            span = obj.max_xyz - obj.min_xyz;
            d = max(span);
            offsets = (span - d) / 2;
            result = obj.max_xyz - offsets;
        end
        

        function result = access_cube_xyz(obj)
            span = obj.max_xyz - obj.min_xyz;
            d = max(span);
            offsets = (span - d) / 2;
            cube_min = obj.min_xyz + offsets;
            cube_max = obj.max_xyz - offsets;
            result = [cube_min; cube_max];
        end
        
        function result = access_xyz(obj)
            result = [obj.x, obj.y, obj.z];
        end
        
        function assign_property(obj, name, values)
            obj.(name) = values;
        end

        function [first, last] = range_for_segment(obj, segment_index)
            first = obj.segment_offsets_(segment_index);
            last = obj.segment_offsets_(segment_index + 1) - 1;
        end
        
        function [specifier, modifier] = define_clone_specifier(obj)
            
            [specifier, modifier] = define_clone_specifier@geospm.BaseSpatialIndex(obj);
            
            % Replace specifier.data so that data has a valid number of
            % rows

            specifier.data = zeros(obj.N, 0);

            specifier.per_row.x = obj.x;
            specifier.per_row.y = obj.y;
            specifier.per_row.z = obj.z;
            specifier.per_row.segment_index = obj.segment_index;

            specifier.segment_sizes = obj.segment_sizes;
            specifier.segment_labels = obj.segment_labels;
            specifier.segment_offsets = obj.segment_offsets_;
        end

        function result = create_clone_from_specifier(~, specifier)
            
            specifier_segment_sizes = ...
                geospm.SpatialIndex.segment_indices_to_segment_sizes(...
                    specifier.per_row.segment_index);

            result = geospm.SpatialIndex(specifier.per_row.x, ...
                                         specifier.per_row.y, ...
                                         specifier.per_row.z, ...
                                         specifier_segment_sizes, ...
                                         specifier.segment_labels, ...
                                         specifier.crs);
        end

    end

    methods (Static)

        function result = from_json_struct_impl(specifier, ~)
            
            if ~isfield(specifier, 'x') || ~isnumeric(specifier.x)
                error('Missing ''x'' field in json struct or ''x'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'y') || ~isnumeric(specifier.y)
                error('Missing ''y'' field in json struct or ''y'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'z') || ~isnumeric(specifier.z)
                error('Missing ''z'' field in json struct or ''z'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'segment_sizes') || ~isnumeric(specifier.segment_sizes)
                error('Missing ''segment_sizes'' field in json struct or ''segment_sizes'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'segment_labels')
                specifier.segment_labels = [];
            end

            if ~isfield(specifier, 'segment_labels') || ~isnumeric(specifier.segment_labels)
                error('Missing ''segment_labels'' field in json struct or ''segment_labels'' field is not a cell array.');
            end
            
            if isfield(specifier, 'crs') && ~ischar(specifier.crs)
                error('''crs'' field is not char.');
            end
            
            crs = '';
            
            if isfield(specifier, 'crs') && ~isempty(specifier.crs)
                crs = specifier.crs;
            end
            
            result = geospm.SpatialIndex(specifier.x, specifier.y, specifier.z, specifier.segment_sizes, specifier.segment_labels, crs);

        end
    end
end
