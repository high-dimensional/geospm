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

classdef BaseSpatialIndex < geospm.TabularData
    %BaseSpatialIndex A spatial index stores coordinates grouped
    % into segments.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    
        crs % an optional SpatialCRS or empty
    end

    properties

        attachments % struct of optional attachments
    end
    
    properties (Dependent, Transient, GetAccess=public)

        has_crs % is a crs defined?

        S % number of segments

        segment_sizes % a column vector of length S listing the number of coordinates per segment

        x_protected
        y_protected
        z_protected
    end
    
    
    methods
        
        function obj = BaseSpatialIndex(crs)
            %Construct a BaseSpatialIndex object with an optional CRS.
            % N ? number of points or locations
            % crs ? coordinate reference system or empty
            
            if ~exist('crs', 'var')
                crs = hdng.SpatialCRS.empty;
            end
            
            if ~isempty(crs) && ~isa(crs, 'hdng.SpatialCRS') && ~ischar(crs)
                error('''crs'' should be a hdng.SpatialCRS instance, empty ([]) or a string identifier.');
            end
            
            obj = obj@geospm.TabularData();
            
            if isempty(crs)
                crs = hdng.SpatialCRS.empty;
            elseif ischar(crs)
                crs = hdng.SpatialCRS.from_identifier(crs);
            end
            
            obj.crs = crs;
            obj.attachments = struct();
        end

        function result = get.has_crs(obj)
            result = ~isempty(obj.crs);
        end
        
        function result = get.segment_sizes(obj)
            result = obj.access_segment_sizes();
        end

        function result = get.S(obj)
            result = obj.access_S();
        end
        
        function result = get.x_protected(obj)
            result = obj.access_x();
        end
        
        function result = get.y_protected(obj)
            result = obj.access_y();
        end
        
        function result = get.z_protected(obj)
            result = obj.access_z();
        end
        
        function [x, y, z] = xyz_coordinates_for_segment(obj, segment_index) %#ok<STOUT,INUSD>
            error('xyz_coordinates_for_segment() must be implemented by a subclass.');
        end

        %{
        function result = row_indices_from_segment_indices(obj, segment_indices) %#ok<STOUT,INUSD>
            error('row_indices_from_segment_indices() must be implemented by a subclass.');
        end

        function result = segment_indices_from_row_indices(obj, row_indices) %#ok<STOUT,INUSD>
            error('segment_indices_from_row_indices() must be implemented by a subclass.');
        end
        %}
        
        function result = select_by_segment(obj, segment_selection, transform) %#ok<STOUT,INUSD>
            error('select_by_segment() must be implemented by a subclass.');
        end

        function [spatial_index, segment_indices] = project(obj, grid, assigned_grid) %#ok<STOUT,INUSD>
            error('project() must be implemented by a subclass.');
        end
        
        function result = convolve_segment(obj, segment_index, span_origin, span_limit, kernel) %#ok<STOUT,INUSD>
            error('convolve_segment() must be implemented by a subclass.');
        end
        
        function write_as_eps(obj, file_path, point1, point2, variant, varargin)
            
            if ~exist('point1', 'var')
                point1 = [];
            end
            
            if ~exist('point2', 'var')
                point2 = [];
            end

            if ~exist('variant', 'var')
                variant = [];
            end

            obj.render_frame_in_figure_and_write_to_file(point1, point2, variant, file_path, 'epsc', varargin{:});
        end


        function write_as_png(obj, file_path, point1, point2, variant, varargin)
            
            if ~exist('point1', 'var')
                point1 = [];
            end
            
            if ~exist('point2', 'var')
                point2 = [];
            end

            if ~exist('variant', 'var')
                variant = [];
            end

            obj.render_frame_in_figure_and_write_to_file(point1, point2, variant, file_path, 'png', varargin{:});
        end
        
        function result = as_json_struct(obj, varargin) %#ok<STOUT,INUSD>
            error('as_json_struct() must be implemented by a subclass.');
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
    end
    
    methods (Access=protected)


        function result = access_x(obj) %#ok<STOUT,MANU>
            error('access_x() must be implemented by a subclass.');
        end
        
        function result = access_y(obj) %#ok<STOUT,MANU>
            error('access_y() must be implemented by a subclass.');
        end

        function result = access_z(obj) %#ok<STOUT,MANU>
            error('access_z() must be implemented by a subclass.');
        end
        
        function result = access_segment_sizes(obj) %#ok<STOUT,MANU>
            error('access_segment_sizes() must be implemented by a subclass.');
        end

        function result = access_S(obj) %#ok<STOUT,MANU>
            error('() must be implemented by a subclass.');
        end
        
        %{
        function result = access_segment_index(obj) %#ok<STOUT,MANU>
            error('access_segment_index() must be implemented by a subclass.');
        end
        
        function result = access_segment_offsets(obj) %#ok<STOUT,MANU>
            error('access_segment_offsets() must be implemented by a subclass.');
        end
        
        function result = access_x_min(obj) %#ok<STOUT,MANU>
            error('access_x_min() must be implemented by a subclass.');
        end
        
        function result = access_x_max(obj) %#ok<STOUT,MANU>
            error('access_x_max() must be implemented by a subclass.');
        end
        
        function result = access_y_min(obj) %#ok<STOUT,MANU>
            error('access_y_min() must be implemented by a subclass.');
        end
        
        function result = access_y_max(obj) %#ok<STOUT,MANU>
            error('access_y_max() must be implemented by a subclass.');
        end
        
        function result = access_z_min(obj) %#ok<STOUT,MANU>
            error('access_z_min() must be implemented by a subclass.');
        end
        
        function result = access_z_max(obj) %#ok<STOUT,MANU>
            error('access_z_max() must be implemented by a subclass.');
        end
        
        function result = access_min_xy(obj) %#ok<STOUT,MANU>
            error('access_min_xy() must be implemented by a subclass.');
        end
        
        function result = access_max_xy(obj) %#ok<STOUT,MANU>
            error('access_max_xy() must be implemented by a subclass.');
        end
        
        function result = access_span_xy(obj) %#ok<STOUT,MANU>
            error('access_span_xy() must be implemented by a subclass.');
        end
        
        function result = access_min_xyz(obj) %#ok<STOUT,MANU>
            error('access_min_xyz() must be implemented by a subclass.');
        end
        
        function result = access_max_xyz(obj) %#ok<STOUT,MANU>
            error('access_max_xyz() must be implemented by a subclass.');
        end

        function result = access_span_xyz(obj) %#ok<STOUT,MANU>
            error('access_span_xyz() must be implemented by a subclass.');
        end
        
        function result = access_centroid_x(obj) %#ok<STOUT,MANU>
            error('access_centroid_x() must be implemented by a subclass.');
        end
        
        function result = access_centroid_y(obj) %#ok<STOUT,MANU>
            error('access_centroid_y() must be implemented by a subclass.');
        end
        
        function result = access_centroid_z(obj) %#ok<STOUT,MANU>
            error('access_centroid_z() must be implemented by a subclass.');
        end
        
        function result = access_centroid_xyz(obj) %#ok<STOUT,MANU>
            error('access_centroid_xyz() must be implemented by a subclass.');
        end

        function result = access_square_min_xy(obj) %#ok<STOUT,MANU>
            error('access_square_min_xy() must be implemented by a subclass.');
        end

        function result = access_square_max_xy(obj) %#ok<STOUT,MANU>
            error('access_square_max_xy() must be implemented by a subclass.');
        end
        
        function result = access_square_xy(obj) %#ok<STOUT,MANU>
            error('access_square_xy() must be implemented by a subclass.');
        end

        function result = access_cube_min_xyz(obj) %#ok<STOUT,MANU>
            error('access_cube_min_xyz() must be implemented by a subclass.');
        end

        function result = access_cube_max_xyz(obj) %#ok<STOUT,MANU>
            error('access_cube_max_xyz() must be implemented by a subclass.');
        end
        

        function result = access_cube_xyz(obj) %#ok<STOUT,MANU>
            error('access_cube_xyz() must be implemented by a subclass.');
        end
        
        function result = access_xyz(obj) %#ok<STOUT,MANU>
            error('access_xyz() must be implemented by a subclass.');
        end
        %}
        
        function assign_property(obj, name, values)
            obj.(name) = values;
        end

        function [specifier, modifier] = define_clone_specifier(obj)
            
            [specifier, modifier] = define_clone_specifier@geospm.TabularData(obj);
            
            specifier.crs = obj.crs;
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
                variant = 'frequencies';
            end
            
            method_name = ['render_' variant '_in_figure'];

            if ~ismethod(obj, method_name)
                return;
            end
            
            result = obj.(method_name)(origin, frame_size, varargin{:});
        end

        function [origin, frame_size] = sanitise_origin_and_frame_size(obj, origin, frame_size)
            
            tmp_square_xy = [];

            function compute_square_xy()
                if ~isempty(tmp_square_xy)
                    tmp_square_xy = obj.square_xy;
                end
            end
            
            if isempty(origin)
                compute_square_xy();
                origin = tmp_square_xy(1, :);
            end

            if isempty(frame_size)
                compute_square_xy();
                frame_size = tmp_square_xy(2, :) - tmp_square_xy(1, :);
            end
        end

        function result = render_frequencies_in_figure(obj, origin, frame_size, varargin)

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            [origin, frame_size] = obj.sanitise_origin_and_frame_size(origin, frame_size);

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

        function resolution_factor = render_frame_in_figure_and_write_to_file(obj, point1, point2, variant, file_path, file_format, varargin)
            
            if isempty(point1)
                point1 = obj.min_xy;
            end
            
            if isempty(point2)
                point2 = obj.max_xy;
            end
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'max_pixel_size')
                options.max_pixel_size = 150;
            end
            
            [origin, frame_size] = obj.span_frame(point1, point2);
            
            resolution_factor = options.max_pixel_size / max(frame_size);
            options.max_pixel_size = max(frame_size);
            
            arguments = hdng.utilities.struct_to_name_value_sequence(options);
            
            figure('Renderer', 'painters');
            
            result = obj.render_in_figure(origin, frame_size, variant, arguments{:});
            resolution_factor = resolution_factor / result.corrective_scale_factor;
            
            print(file_path, ['-d' file_format], ['-r' num2str(72 * resolution_factor)], '-noui');
            
            close;
        end
    end

    methods (Static)

        function [origin, frame_size] = span_frame(point1, point2)
            
            min_point = [min(point1(1), point2(1)), min(point1(2), point2(2))];
            max_point = [max(point1(1), point2(1)), max(point1(2), point2(2))];
            
            origin = min_point;
            frame_size = max_point - min_point;
        end

        function result = from_json_struct_impl(specifier) %#ok<STOUT,INUSD>
            error('from_json_struct_impl() must be implemented by a subclass.');
        end

        function result = from_json_struct(specifier)
                
            ctor = str2func([specifier.ctor '.from_json_struct_impl']);
            result = ctor(specifier);
        end
        
        function result = load_from_matlab(filepath)
            
            specifier = load(filepath);
            result = geospm.BaseSpatialIndex.from_json_struct(specifier);
        end
        
        function segment_sizes = segment_indices_to_segment_sizes(segment_indices)
            
            if any(segment_indices <= 0)
                error('segment_index_to_segment_sizes(): Only positive segment indices allowed.');
            end
            
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
