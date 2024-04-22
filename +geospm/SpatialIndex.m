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

classdef SpatialIndex < geospm.TabularData
    %SpatialIndex A spatial index stores coordinates grouped
    % into segments.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
        
        x % a column vector of length N (a N by 1 matrix) of observation x locations
        y % a column vector of length N (a N by 1 matrix) of observation y locations
        z % a column vector of length N (a N by 1 matrix) of observation z locations
        
        segment_sizes % a column vector of length S listing the number of coordinates per segment

        crs % an optional SpatialCRS or empty
    end
    
    properties (Dependent, Transient)
        
        S % number of segments
        
        segment_index % a column vector of length N specifying the segment index for each coordinate
        segment_offsets % a column vector of length S specifying the index of the first coordinate for each segment

        has_crs % is a crs defined?
        
        x_min % minimum x value
        x_max % maximum x value
        
        y_min % minimum y value
        y_max % maximum y value
        
        z_min % minimum z value
        z_max % maximum z value
        
        min_xy % [min_x, min_y]
        max_xy % [max_x, max_y, ]
        
        min_xyz % [min_x, min_y, min_z]
        max_xyz % [max_x, max_y, max_z]
        
        centroid_x
        centroid_y
        centroid_z
        
        centroid_xyz
        
        xyz
    end
    
    properties (GetAccess = private, SetAccess = private)
        
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
        
        function obj = SpatialIndex(x, y, z, segment_sizes, crs)
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
            
            if ~isempty(crs) && ~isa(crs, 'hdng.SpatialCRS') && ~ischar(crs)
                error('''crs'' should be a hdng.SpatialCRS instance, empty ([]) or a string identifier.');
            end

            obj = obj@geospm.TabularData(size(x, 1), 0);
            
            obj.x = x;
            obj.y = y;
            obj.z = z;
            
            obj.segment_sizes = segment_sizes;
            [obj.segment_index_, obj.segment_offsets_] = obj.segment_indices_from_segment_sizes(size(x, 1), segment_sizes);

            if isempty(crs)
                crs = hdng.SpatialCRS.empty;
            elseif ischar(crs)
                crs = hdng.SpatialCRS.from_identifier(crs);
            end
            
            obj.crs = crs;
        end
        
        function result = get.S(obj)
            result = size(obj.segment_sizes, 1);
        end
        
        function result = get.segment_index(obj)
            result = obj.segment_index_;
        end
        
        function result = get.segment_offsets(obj)
            result = obj.segment_offsets_(1:end - 1);
        end

        function result = get.has_crs(obj)
            result = ~isempty(obj.crs);
        end
        
        function result = get.x_min(obj)
            if isempty(obj.x_min_)
                obj.x_min_ = min(obj.x);
            end
            
            result = obj.x_min_;
        end
        
        function result = get.x_max(obj)
            if isempty(obj.x_max_)
                obj.x_max_ = max(obj.x);
            end
            
            result = obj.x_max_;
        end
        
        function result = get.y_min(obj)
            if isempty(obj.y_min_)
                obj.y_min_ = min(obj.y);
            end
            
            result = obj.y_min_;
        end
        
        function result = get.y_max(obj)
            if isempty(obj.y_max_)
                obj.y_max_ = max(obj.y);
            end
            
            result = obj.y_max_;
        end
        
        function result = get.z_min(obj)
            if isempty(obj.z_min_)
                obj.z_min_ = min(obj.z);
            end
            
            result = obj.z_min_;
        end
        
        function result = get.z_max(obj)
            if isempty(obj.z_max_)
                obj.z_max_ = max(obj.z);
            end
            
            result = obj.z_max_;
        end
        
        function result = get.min_xy(obj)
            result = [obj.x_min, obj.y_min];
        end
        
        function result = get.max_xy(obj)
            result = [obj.x_max, obj.y_max];
        end
        
        function result = get.min_xyz(obj)
            result = [obj.x_min, obj.y_min, obj.z_min];
        end
        
        function result = get.max_xyz(obj)
            result = [obj.x_max, obj.y_max, obj.z_max];
        end
        
        function result = get.centroid_x(obj)
            result = obj.centroid_xyz(1);
        end
        
        function result = get.centroid_y(obj)
            result = obj.centroid_xyz(2);
        end
        
        function result = get.centroid_z(obj)
            result = obj.centroid_xyz(3);
        end
        
        function result = get.centroid_xyz(obj)
            if isempty(obj.centroid_xyz_)
                obj.centroid_xyz_ = [mean(obj.x), mean(obj.y), mean(obj.z)];
            end
            
            result = obj.centroid_xyz_;
        end
        
        function result = get.xyz(obj)
            result = [obj.x, obj.y, obj.z];
        end
        
        function show_samples(obj)
            
            figure;
            
            ax = gca;
            axis(ax, 'equal', 'auto');
            
            s = scatter(obj.x, obj.y);
            
            s.Marker = 'o';
            s.MarkerEdgeColor = 'none';
            s.MarkerFaceColor = '#0072BD';
            
        end
        
        function [origin, frame_size] = span_frame(~, point1, point2)
            
            min_point = [min(point1(1), point2(1)), min(point1(2), point2(2))];
            max_point = [max(point1(1), point2(1)), max(point1(2), point2(2))];
            
            origin = min_point;
            frame_size = max_point - min_point;
        end
        
        function [first, last] = range_for_segment(obj, segment_index)
            first = obj.segment_offsets_(segment_index);
            last = obj.segment_offsets_(segment_index + 1) - 1;
        end
        
        function [x, y, z] = xyz_coordinates_for_segment(obj, segment_index)
            
            [first, last] = obj.range_for_segment(segment_index);

            x = obj.x(first:last);
            y = obj.y(first:last);
            z = obj.z(first:last);
        end
        
        function result = select_by_segment(obj, segment_selection, transform)
        
            if ~exist('segment_selection', 'var')
                segment_selection = [];
            end
            
            if isempty(segment_selection)
                segment_selection = 1:obj.S;
            end

            if ~isnumeric(segment_selection)
                
                if islogical(segment_selection)
                    if numel(segment_selection) ~= obj.S
                        error('select_by_segment(): The length of a logical segment selection vector must be equal to the number of segments.');
                    end
                else
                    error('select_by_segment(): segment selection vector must be a numeric or logical array.');
                end
            else
                segment_selection = segment_selection(:);

                try
                    tmp = (1:obj.S)';
                    tmp = tmp(segment_selection); %#ok<NASGU>
                    clear('tmp');
                catch
                    error('select_by_segment(): One or more segment selection indices are out of bounds.');
                end
            end
            
            if ~exist('transform', 'var')
                transform = @(specifier, modifier) specifier;
            end

            row_selection = obj.row_indices_from_segment_indices(segment_selection);
            result = obj.select(row_selection, [], transform);
        end

        function result = render_in_figure(obj, origin, frame_size, variant, varargin)
            
            result = struct();
            result.corrective_scale_factor = 1.0;

            if ~exist('origin', 'var')
                origin = [obj.x_min, obj.y_min];
            end
            
            if ~exist('frame_size', 'var')
                frame_size = [obj.x_max, obj.y_max] - origin;
            end
            
            if ~exist('variant', 'var')
                variant = 'categories';
            end
            
            method_name = ['render_' variant '_in_figure'];

            if ~ismethod(obj, method_name)
                return;
            end
            
            result = obj.(method_name)(origin, frame_size, varargin{:});
        end


        function result = render_frequencies_in_figure(obj, origin, frame_size, varargin)

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if isempty(origin)
                origin = obj.min_xy;
            end

            if isempty(frame_size)
                frame_size = obj.max_xy - obj.min_xy;
            end

            if ~isfield(options, 'grid_size')
                cell_size = max(frame_size) / 100;
                options.grid_size = ceil(frame_size ./ cell_size);
            end
            
            if ~isfield(options, 'marker_alignment')
                options.marker_alignment = [0.5 0.5];
            end
            
            if ~isfield(options, 'marker_scale')
                options.marker_scale = 1;
            end
            
            grid = geospm.Grid();
            grid.span_frame(origin, origin + frame_size, options.grid_size);
            
            [grid_spatial_index, ~] = grid.transform_spatial_index(obj);
            
            linear_index = sub2ind(grid.resolution(1:2), grid_spatial_index.u, grid_spatial_index.v);

            [cell_index, occurrences] = hdng.utilities.compute_unique_values(linear_index);
            frequencies = cellfun(@(x) numel(x), occurrences);
            marker_sizes = frequencies ./ max(frequencies);

            %N = 10;
            %q = quantile(frequencies, N - 1);
            %marker_sizes = N - sum(frequencies <= q', 1);
            
            %cell_size = options.marker_scale * options.max_pixel_size / max(options.grid_size);

            %marker_size_by_symbol = containers.Map('KeyType', 'char', 'ValueType', 'double');
            %marker_size_by_symbol('x') = 4;
            %marker_size_by_symbol('o') = 2;
            %marker_size_by_symbol('.') = 16;
            %marker_size_by_symbol('s') = 4;
            %marker_size_by_symbol('+') = 0.5;

            marker_symbol = 'o';
            
            %marker_sizes = marker_sizes .* cell_size * cell_size;

            [u, v] = ind2sub(grid.resolution(1:2), cell_index);
            
            result = geospm.diagrams.scatter(...
                u, v, ...
                [1, 1] - options.marker_alignment, ...
                options.grid_size, ...
                'marker_sizes', marker_sizes, ...
                'marker_symbol', marker_symbol, varargin{:}, ...
                'line_width', 0.1 * options.marker_scale );
        end

        function write_as_eps(obj, file_path, point1, point2, variant, varargin)
            
            if ~exist('point1', 'var') || isempty(point1)
                point1 = obj.min_xy;
            end
            
            if ~exist('point2', 'var') || isempty(point2)
                point2 = obj.max_xy;
            end

            if ~exist('variant', 'var')
                variant = [];
            end
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'max_pixel_size')
                options.max_pixel_size = 150;
            end
            
            [origin, frame_size] = obj.span_frame(point1, point2);
            
            resolution_factor = options.max_pixel_size / max(frame_size);
            options.max_pixel_size = max(frame_size);
            
            figure('Renderer', 'painters');
            %ax = gca;
            
            arguments = hdng.utilities.struct_to_name_value_sequence(options);

            result = obj.render_in_figure(origin, frame_size, variant, arguments{:});
            resolution_factor = resolution_factor / result.corrective_scale_factor;

            %saveas(ax, file_path, 'epsc');
            
            print(file_path, '-depsc', ['-r' num2str(72 * resolution_factor)], '-noui');
            
            close;
        end


        function write_as_png(obj, file_path, point1, point2, variant, varargin)
            
            if ~exist('point1', 'var') || isempty(point1)
                point1 = obj.min_xy;
            end
            
            if ~exist('point2', 'var') || isempty(point2)
                point2 = obj.max_xy;
            end

            if ~exist('variant', 'var')
                variant = [];
            end
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'max_pixel_size')
                options.max_pixel_size = 150;
            end

            [origin, frame_size] = obj.span_frame(point1, point2);
            
            resolution_factor = options.max_pixel_size / max(frame_size);
            options.max_pixel_size = max(frame_size);

            figure('Renderer', 'painters');
            %ax = gca;
            %f = gcf;
            
            arguments = hdng.utilities.struct_to_name_value_sequence(options);

            result = obj.render_in_figure(origin, frame_size, variant, arguments{:});
            resolution_factor = resolution_factor / result.corrective_scale_factor;
            
            %saveas(ax, file_path, 'png');
            %exportgraphics(ax, file_path, 'Resolution', 100, 'BackgroundColor', 'none');
            
            print(file_path, '-dpng', ['-r' num2str(72 * resolution_factor)], '-noui');
            
            close;
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
        
        function write_as_json(obj, filepath, varargin)
            %Writes a JSON representation of this SpatialIndex object to a file.
            % The range of possible name-value arguments is documented for
            % the as_json_struct() method.
            
            json = obj.as_json_struct(varargin{:});
            
            [dir, name, ext] = fileparts(filepath);
            
            if ~strcmpi(ext, '.json')
                filepath = fullfile(dir, [name, '.json']);
            end
            
            json = jsonencode(json);
            hdng.utilities.save_text(json, filepath);
        end

        function write_as_matlab(obj, filepath, varargin)
            %Writes a Matlab struct of this SpatialIndex object to a file.
            % The range of possible name-value arguments is documented for
            % the as_json_struct() method.
            
            json = obj.as_json_struct(varargin{:});
            
            [dir, name, ext] = fileparts(filepath);
            
            if ~strcmpi(ext, '.mat')
                filepath = fullfile(dir, [name, '.mat']);
            end
            
            save(filepath, '-struct', 'json');
        end
        
        function result = row_indices_from_segment_indices(obj, segment_indices)
            
            row_selection = zeros(obj.N, 1, 'logical');

            for index=1:numel(segment_indices)
                segment = segment_indices(index);

                first = obj.segment_offsets(segment);
                last = first + obj.segment_sizes(segment) - 1;

                row_selection(first:last) = 1;
            end

            result = find(row_selection);
        end

        function result = segment_indices_from_row_indices(obj, row_indices)
            result = unique(obj.segment_index(row_indices));
        end
    end
    
    methods (Access=protected)
        
        function assign_property(obj, name, values)
            obj.(name) = values;
        end

        function [specifier, modifier] = define_clone_specifier(obj)
            
            [specifier, modifier] = define_clone_specifier@geospm.TabularData(obj);
            
            specifier.per_row.x = obj.x;
            specifier.per_row.y = obj.y;
            specifier.per_row.z = obj.z;
            specifier.per_row.segment_index = obj.segment_index;

            specifier.segment_sizes = obj.segment_sizes;
            specifier.segment_offsets = obj.segment_offsets_;

            specifier.crs = obj.crs;

        end

        function result = create_clone_from_specifier(~, specifier)
            
            specifier_segment_sizes = ...
                geospm.SpatialIndex.segment_indices_to_segment_sizes(...
                    specifier.per_row.segment_index);

            result = geospm.SpatialIndex(specifier.per_row.x, ...
                                         specifier.per_row.y, ...
                                         specifier.per_row.z, ...
                                         specifier_segment_sizes, ...
                                         specifier.crs);
        end

    end

    methods (Static)

        function result = from_json_struct(specifier)
            
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
            
            if isfield(specifier, 'crs') && ~ischar(specifier.crs)
                error('''crs'' field is not char.');
            end
            
            crs = '';

            if isfield(specifier, 'crs') && ~isempty(specifier.crs)
                crs = specifier.crs;
            end
            
            result = geospm.SpatialIndex(specifier.x, specifier.y, specifier.z, specifier.segment_sizes, crs);

        end

        function result = load_from_matlab(filepath)
            
            specifier = load(filepath);
            ctor = str2func([specifier.ctor '.from_json_struct']);
            result = ctor(specifier);
        end
        
        function segment_sizes = segment_indices_to_segment_sizes(segment_indices)
            
            if any(segment_indices <= 0)
                error('segment_index_to_segment_sizes(): Only positive segment indices allowed.');
            end
            
            %{
            unique_segments = unique(segment_indices);
            max_segment = max(unique_segments);

            segments = zeros(max_segment, 1);

            for index=1:numel(segment_indices)
                current_segment = segment_indices(index);
                segments(current_segment) = segments(current_segment) + 1;
            end

            segment_sizes = segments(unique_segments);
            %}
            
            segment_indices = sort(segment_indices);
            tmp = [segment_indices - [0; segment_indices(1:end - 1)]; 1];
            offsets = find(tmp(2:end));
            segment_sizes = offsets - [0; offsets(1:end - 1)];
        end

        function [segment_index, segment_offsets] = segment_indices_from_segment_sizes(N_coords, segment_sizes)
            
            segment_sum = sum(segment_sizes);

            if N_coords ~= segment_sum
                error('The sum of segments (=%d) does not match the number of coordinates (=%d).', segment_sum, N_coords);
            end

            segment_index = zeros(N_coords, 1);

            current_segment_index = 1;
            segment_counts = segment_sizes;

            for index=1:N_coords
                if segment_counts(current_segment_index) <= 0
                    error('Zero segments are not supported [%d].', current_segment_index);
                end

                segment_counts(current_segment_index) = segment_counts(current_segment_index) - 1;

                segment_index(index) = current_segment_index;

                if segment_counts(current_segment_index) <= 0
                    current_segment_index = current_segment_index + 1;
                end
            end

            segment_offsets = [1; cumsum(segment_sizes) + 1];
        end
    end
end
