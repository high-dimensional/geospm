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

classdef Grid < handle
    
    %Grid Defines an affine mapping between a rectangular grid of cells and a spatial coordinate system.
    % 
    
    properties (GetAccess=public, SetAccess=private)
    end
    
    properties (Dependent, Transient)
        
        resolution % 3-vector ? Number of unit cells in this grid along its u, v and w directions.
        
        origin % 3-vector ? Origin (x, y, z) of this grid in the spatial coordinate system.
        span % 3-vector ? Span (dx, dy, dz) of this grid in the spatial coordinate system.
        cell_size % 3-vector ? Size of a grid cell (u, v, w) in the scale of the spatial coordinate system.
        rotation_z % scalar ? The counter-clockwise, positive angle of rotation (in radians) of the grid about the z-axis of the spatial coordinate system.
        
        flip_u % logical ? The grid is flipped along its u direction compared to the spatial coordinate system.
        flip_v % logical ? The grid is flipped along its v direction compared to the spatial coordinate system.
        
        cell_marker_alignment % 3-vector ? position of markers within a grid cell, ranges from 0 to 1
        cell_marker_scale % 3-vector ? size of markers in units of grid cells

        space_to_grid_transform
        grid_to_space_transform
        
        space_to_grid_translation
        space_to_grid_rotation
        space_to_grid_flip_and_scale
        space_to_grid_offset
        
        grid_to_space_translation
        grid_to_space_rotation
        grid_to_space_scale_and_flip
        grid_to_space_offset
    end
    
    
    properties (GetAccess=private, SetAccess=private)
        
        resolution_
        
        origin_
        cell_size_
        rotation_z_
        
        flip_u_
        flip_v_

        cell_marker_alignment_
        cell_marker_scale_
        
        space_to_grid_transform_
        grid_to_space_transform_
    end
    
    methods
        
        function result = get.resolution(obj)
            result = obj.resolution_;
        end
        
        function set.resolution(obj, value)
            
            if ~isnumeric(value) || (numel(value) ~= 3 && numel(value) ~= 2)
                error('Grid2.resolution must be specified as a 2-vector or 3-vector.');
            end
            
            if numel(value) == 2
                value = [value(:)' 1];
            end
            
            if ~isequal(obj.resolution_,  value(:)')
                obj.clear_transform_cache();
                obj.resolution_ = value(:)';
            end
        end
        
        function result = get.origin(obj)
            result = obj.origin_;
        end
        
        function set.origin(obj, value)
            
            if ~isnumeric(value) || (numel(value) ~= 3 && numel(value) ~= 2)
                error('Grid2.origin must be specified as a 2-vector or 3-vector.');
            end
            
            if numel(value) == 2
                value = [value(:)' 1];
            end
            
            if ~isequal(obj.origin_,  value(:)')
                obj.clear_transform_cache();
                obj.origin_ = value(:)';
            end
        end
        
        function result = get.span(obj)
            result = obj.cell_size_ .* obj.resolution_;
        end

        function result = get.cell_size(obj)
            result = obj.cell_size_;
        end
        
        function set.cell_size(obj, value)
            
            if ~isnumeric(value) || (numel(value) ~= 3 && numel(value) ~= 2)
                error('Grid2.cell_size must be specified as a 2-vector or 3-vector.');
            end
            
            if numel(value) == 2
                value = [value(:)' 1];
            end
            
            if ~isequal(obj.cell_size_,  value(:)')
                obj.clear_transform_cache();
                obj.cell_size_ = value(:)';
            end
        end
        
        function result = get.rotation_z(obj)
            result = obj.rotation_z_;
        end
        
        function set.rotation_z(obj, value)
            
            if ~isnumeric(value) || numel(value) ~= 1
                error('Grid2.rotation_z must be specified as a scalar value.');
            end
            
            if ~isequal(obj.rotation_z_,  value)
                obj.clear_transform_cache();
                obj.rotation_z_ = value;
            end
        end
        
        function result = get.flip_u(obj)
            result = obj.flip_u_;
        end
        
        function set.flip_u(obj, value)
            
            if ~isa(value, 'logical') || numel(value) ~= 1
                error('Grid2.flip_u must be specified as a logical value.');
            end
            
            if ~isequal(obj.flip_u_,  value)
                obj.clear_transform_cache();
                obj.flip_u_ = value;
            end
        end
        
        function result = get.flip_v(obj)
            result = obj.flip_v_;
        end
        
        function set.flip_v(obj, value)
            
            if ~isa(value, 'logical') || numel(value) ~= 1
                error('Grid2.flip_v must be specified as a logical value.');
            end
            
            if ~isequal(obj.flip_v_,  value)
                obj.clear_transform_cache();
                obj.flip_v_ = value;
            end
        end

        function result = get.cell_marker_alignment(obj)
            result = obj.cell_marker_alignment_;
        end
        
        function set.cell_marker_alignment(obj, value)
            
            if ~isnumeric(value) || (numel(value) ~= 3 && numel(value) ~= 2)
                error('Grid2.cell_marker_alignment must be specified as a 2-vector or 3-vector.');
            end
            
            if numel(value) == 2
                value = [value(:)' 0.5];
            end
            
            if ~isequal(obj.cell_marker_alignment_,  value(:)')
                obj.cell_marker_alignment_ = value(:)';
            end
        end

        function result = get.cell_marker_scale(obj)
            result = obj.cell_marker_scale_;
        end
        
        function set.cell_marker_scale(obj, value)
            
            if ~isnumeric(value) || (numel(value) ~= 3 && numel(value) ~= 2)
                error('Grid2.cell_marker_scale must be specified as a 2-vector or 3-vector.');
            end
            
            if numel(value) == 2
                value = [value(:)' 1];
            end
            
            if ~isequal(obj.cell_marker_scale_,  value(:)')
                obj.cell_marker_scale_ = value(:)';
            end
        end
        
        function result = get.space_to_grid_transform(obj)
            
            if isempty(obj.space_to_grid_transform_)
                obj.space_to_grid_transform_ = obj.compute_space_to_grid_transform();
            end
            
            result = obj.space_to_grid_transform_;
        end
        
        function result = get.grid_to_space_transform(obj)
            
            if isempty(obj.grid_to_space_transform_)
                obj.grid_to_space_transform_ = obj.compute_grid_to_space_transform();
            end
            
            result = obj.grid_to_space_transform_;
        end
        
        function result = get.space_to_grid_translation(obj)
            result = obj.compute_space_to_grid_translation();
        end
        
        function result = get.space_to_grid_rotation(obj)
            result = obj.compute_space_to_grid_rotation();
        end
        
        function result = get.space_to_grid_flip_and_scale(obj)
            result = obj.compute_space_to_grid_flip_and_scale();
        end
        
        function result = get.space_to_grid_offset(obj)
            result = obj.compute_space_to_grid_offset();
        end
        
        function result = get.grid_to_space_translation(obj)
            result = obj.compute_grid_to_space_translation();
        end
        
        function result = get.grid_to_space_rotation(obj)
            result = obj.compute_grid_to_space_rotation();
        end
        
        function result = get.grid_to_space_scale_and_flip(obj)
            result = obj.compute_grid_to_space_scale_and_flip();
        end
        
        function result = get.grid_to_space_offset(obj)
            result = obj.compute_grid_to_space_offset();
        end
        
        function obj = Grid()
            
            obj.space_to_grid_transform_ = [];
            obj.grid_to_space_transform_ = [];
            
            obj.resolution_ = [240 240 1];
            obj.origin_ = [0 0 0];
            obj.cell_size_ = [1 1 1];
            obj.rotation_z_ = 0.0;

            obj.flip_u_ = false;
            obj.flip_v_ = false;

            obj.cell_marker_alignment_ = [0.5, 0.5, 0.5];
            obj.cell_marker_scale_ = [1, 1, 1];
        end
        
        function result = compute_raster_reference_for_w(obj, w, centre_pixels, flip_y)
            
            if ~exist('centre_pixels', 'var') || isempty(centre_pixels)
                centre_pixels = true;
            end
            
            if ~exist('flip_y', 'var')
                flip_y = false;
            end
            
            T = obj.grid_to_space_transform;
            
            result = [T(1, 1), T(1, 2), w * T(1, 3) + T(1, 4) + obj.cell_size_(1);
                      T(2, 1), T(2, 2), w * T(2, 3) + T(2, 4) + obj.cell_size_(2)];
            
            if ~centre_pixels
                result(1, 3) = result(1, 3) + obj.cell_size_(1) * 0.5;
                result(2, 3) = result(2, 3) + obj.cell_size_(2) * 0.5;
            end
            
            if flip_y
                result(2, 2) = -result(2, 2);
                result(2, 3) = result(2, 3) + (obj.resolution(2) - 1) * obj.cell_size(2);
            end
            
        end
        
        function define(obj, varargin)
            %Defines the computational grid to be used.
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'resolution')
                options.resolution = [240 240 1];
            end
            
            if ~isfield(options, 'origin')
                options.origin = [0 0 0];
            end
            
            if ~isfield(options, 'cell_size')
                options.cell_size = [1 1 1];
            end
            
            if ~isfield(options, 'rotation_z')
                options.rotation_z = 0.0;
            end
            
            if ~isfield(options, 'flip_u')
                options.flip_u = false;
            end
            
            if ~isfield(options, 'flip_v')
                options.flip_v = false;
            end
            
            if ~isfield(options, 'cell_marker_alignment')
                options.cell_marker_alignment = [0.5 0.5 0.5];
            end
            
            if ~isfield(options, 'cell_marker_scale')
                options.cell_marker_scale = [1, 1, 1];
            end
            
            if isempty(options.resolution)
                options.resolution = obj.resolution;
            end
            
            if isempty(options.origin)
                options.origin = obj.origin;
            end
            
            if isempty(options.cell_size)
                options.cell_size = obj.cell_size;
            end
            
            if isempty(options.rotation_z)
                options.rotation_z = obj.rotation_z;
            end
            
            if isempty(options.flip_u)
                options.flip_u = obj.flip_u;
            end
            
            if isempty(options.flip_v)
                options.flip_v = obj.flip_v;
            end
            
            assigned_resolution = cast(cast(options.resolution, 'int64'), 'double');
            
            if ~isequal(assigned_resolution, options.resolution)
                error('Grid.define(): Resolution must be an integer vector.');
            end
            
            options.resolution = assigned_resolution;
            
            obj.clear_transform_cache();
            obj.resolution = options.resolution;
            obj.origin = options.origin;
            obj.cell_size = options.cell_size;
            obj.rotation_z = options.rotation_z;
            obj.flip_u = options.flip_u;
            obj.flip_v = options.flip_v;
            obj.cell_marker_alignment = options.cell_marker_alignment;
            obj.cell_marker_scale = options.cell_marker_scale;
        end
        
        function [u, v, w] = space_to_grid(obj, x, y, z, as_integers)
            
            if numel(x) ~= numel(y) || numel(x) ~= numel(z)
                error('Grid.space_to_grid(): x, y and z vectors must have identical length.');
            end
            
            if ~exist('as_integers', 'var')
                as_integers = true;
            end
            
            result = obj.space_to_grid_transform * [x(:)'; y(:)'; z(:)'; ones(1, numel(x))];
            result = result(1:3, :) ./ result(4, :);
            
            if as_integers
                result = cast(floor(result), 'int64');
            end
            
            u = result(1, :)';
            v = result(2, :)';
            w = result(3, :)';
        end
        
        function [x, y, z] = grid_to_space(obj, u, v, w)
           
            if numel(u) ~= numel(v) || numel(u) ~= numel(w)
                error('Grid.grid_to_space(): u, v and w vectors must have identical length.');
            end
            
            result = obj.grid_to_space_transform * [cast([u(:)'; v(:)'; w(:)'], 'double'); ones(1, numel(u), 'double')];
            result = result(1:3, :) ./ result(4, :);
            
            x = result(1, :)';
            y = result(2, :)';
            z = result(3, :)';
        end
        
        function span_frame(obj, point1, point2, resolution)
            
            % Define the grid to span a rectangle defined by point1 and
            % point2, and a maximum resolution of max_units.
            
            if (numel(point1) == 2) && (numel(point2) == 2)
                point1 = [point1 0];
                point2 = [point2 0];
            elseif (numel(point1) == 3) && (numel(point2) == 2)
                point2 = [point2 point1(3)];
            elseif (numel(point1) == 2) && (numel(point2) == 3)
                point1 = [point1 point2(3)];
            end
            
            if numel(resolution) == 2
                resolution = [resolution 1];
            end
            
            min_point = [min(point1(1), point2(1)), min(point1(2), point2(2)), min(point1(3), point2(3))];
            max_point = [max(point1(1), point2(1)), max(point1(2), point2(2)), max(point1(3), point2(3))];
            
            frame_origin = min_point;
            frame_size = max_point - min_point;
            
            frame_cell_size = frame_size ./ resolution;
            frame_resolution = ceil(frame_size ./ frame_cell_size);
            
            matches = frame_cell_size <= eps;
            
            if any(matches)
                constant = [1, 1, 1];
                frame_cell_size(matches) = constant(matches);
                frame_resolution(matches) = constant(matches);
            end
            
            obj.define('resolution', frame_resolution, ...
                       'origin', frame_origin, ...
                       'cell_size', frame_cell_size);
        end

        function [row_indices, uvw] = select_xyz(obj, xyz)
            
            N = size(xyz, 1);

            [u, v, w] = obj.space_to_grid(xyz(:, 1), xyz(:, 2), xyz(:, 3));
            
            indicators = ...
                u >= 1 & u <= obj.resolution(1) & ...
                v >= 1 & v <= obj.resolution(2) & ...
                w >= 1 & w <= obj.resolution(3);
            
            row_numbers = cast((1:N)', 'int64');
            row_indices = row_numbers(indicators);
            
            uvw = [u(row_indices), v(row_indices), w(row_indices)];
        end
        
        function [grid_spatial_index, row_indices, segment_indices] = transform_spatial_index(obj, spatial_index, assigned_grid)
            
            if ~exist('assigned_grid', 'var')
                assigned_grid = obj;
            end
            
            % Select the subset of observations within the grid:
            
            [row_indices, uvw] = obj.select_xyz(spatial_index.xyz);
            
            x = spatial_index.x(row_indices);
            y = spatial_index.y(row_indices);
            z = spatial_index.z(row_indices);

            segment_indices = spatial_index.segment_indices_from_row_indices(row_indices);
            segment_sizes = spatial_index.segment_indices_to_segment_sizes(spatial_index.segment_index(row_indices));

            grid_spatial_index = geospm.GridSpatialIndex(uvw(:, 1), uvw(:, 2), uvw(:, 3), x, y, z, segment_sizes, obj.resolution, assigned_grid.clone(), spatial_index.crs);
            
            grid_spatial_index.assign_row_attachments(spatial_index, row_indices);
            grid_spatial_index.assign_column_attachments(spatial_index);
        end

        function result = as_json_struct(obj, varargin)
            %Creates a JSON representation of this Grid object.
            % The following fields can be provided in the options
            % argument:
            % None so far.
            
            [~] = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            specifier = struct();
            
            specifier.ctor = 'geospm.Grid';
            
            specifier.resolution = obj.resolution;
            specifier.origin = obj.origin;
            specifier.cell_size = obj.cell_size;
            specifier.rotation_z = obj.rotation_z;
            specifier.flip_u = obj.flip_u;
            specifier.flip_v = obj.flip_v;
            specifier.cell_marker_alignment = obj.cell_marker_alignment;
            specifier.cell_marker_scale = obj.cell_marker_scale;
            
            result = specifier;
        end
    end
    
    methods (Static)

        function result = from_json_struct(specifier)
            
            if ~isfield(specifier, 'resolution') || ~isnumeric(specifier.resolution)
                error('Missing ''resolution'' field in json struct or ''resolution'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'origin') || ~isnumeric(specifier.origin)
                error('Missing ''origin'' field in json struct or ''origin'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'cell_size') || ~isnumeric(specifier.cell_size)
                error('Missing ''cell_size'' field in json struct or ''cell_size'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'rotation_z') || ~isnumeric(specifier.rotation_z)
                error('Missing ''rotation_z'' field in json struct or ''rotation_z'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'flip_u') || ~islogical(specifier.flip_u)
                error('Missing ''flip_u'' field in json struct or ''flip_u'' field is not logical.');
            end
            
            if ~isfield(specifier, 'flip_v') || ~islogical(specifier.flip_v)
                error('Missing ''flip_v'' field in json struct or ''flip_v'' field is not logical.');
            end
            
            if ~isfield(specifier, 'cell_marker_alignment') || ~isnumeric(specifier.cell_marker_alignment)
                error('Missing ''cell_marker_alignment'' field in json struct or ''cell_marker_alignment'' field is not numeric.');
            end
            
            if ~isfield(specifier, 'cell_marker_scale') || ~isnumeric(specifier.cell_marker_scale)
                error('Missing ''cell_marker_scale'' field in json struct or ''cell_marker_scale'' field is not numeric.');
            end
            

            result = geospm.Grid();
            
            result.define('resolution', specifier.resolution, ...
                          'origin', specifier.origin, ...
                          'cell_size', specifier.cell_size, ...
                          'rotation_z', specifier.rotation_z, ...
                          'flip_u', specifier.flip_u, ...
                          'flip_v', specifier.flip_v, ...
                          'cell_marker_alignment', specifier.cell_marker_alignment, ...
                          'cell_marker_scale', specifier.cell_marker_scale);
        end

        function result = load_from_matlab(filepath)
            
            specifier = load(filepath);
            ctor = str2func([specifier.ctor '.from_json_struct']);
            result = ctor(specifier);
        end
    end

    methods (Access=private)
        
        function result = clone(obj)
            
            result = geospm.Grid();
            
            result.define('resolution', obj.resolution, ...
                          'origin', obj.origin, ...
                          'cell_size', obj.cell_size, ...
                          'rotation_z', obj.rotation_z, ...
                          'flip_u', obj.flip_u, ...
                          'flip_v', obj.flip_v, ...
                          'cell_marker_alignment', obj.cell_marker_alignment, ...
                          'cell_marker_scale', obj.cell_marker_scale);
            
        end
        
        
        function clear_transform_cache(obj)
            obj.space_to_grid_transform_ = [];
            obj.grid_to_space_transform_ = [];
        end
        
        function [result, is_identity] = compute_space_to_grid_translation(obj)
            
            result = eye(4);
            
            is_identity = hdng.utilities.isalmostequal(obj.origin(1), 0.0) ...
                          && hdng.utilities.isalmostequal(obj.origin(2), 0.0) ...
                          && hdng.utilities.isalmostequal(obj.origin(3), 0.0);
            
            if is_identity
                return
            end
                          
            result(1:3, 4) = -[obj.origin(1); obj.origin(2); obj.origin(3)];
        end
        
        
        function [result, is_identity] = compute_grid_to_space_translation(obj)
            
            result = eye(4);
            
            is_identity = hdng.utilities.isalmostequal(obj.origin(1), 0.0) ...
                          && hdng.utilities.isalmostequal(obj.origin(2), 0.0) ...
                          && hdng.utilities.isalmostequal(obj.origin(3), 0.0);
            
            if is_identity
                return
            end
                   
            result(1:3, 4) = [obj.origin(1); obj.origin(2); obj.origin(3)];
        end
        
        
        function [result, is_identity] = compute_space_to_grid_rotation(obj)
            
            result = eye(4);
            
            is_identity = hdng.utilities.isalmostequal(mod(obj.rotation_z, 360.0), 0.0);
            
            if is_identity
                return
            end
            
            sine = sin(-obj.rotation_z);
            cosine = cos(-obj.rotation_z);
            
            result(1:2, 1) = [cosine; sine];
            result(1:2, 2) = [-sine; cosine];
        end
        
        
        function [result, is_identity] = compute_grid_to_space_rotation(obj)
            
            result = eye(4);
            
            is_identity = hdng.utilities.isalmostequal(mod(obj.rotation_z, 360.0), 0.0);
            
            if is_identity
                return
            end
            
            sine = sin(obj.rotation_z);
            cosine = cos(obj.rotation_z);
            
            result(1:2, 1) = [cosine; sine];
            result(1:2, 2) = [-sine; cosine];
        end
        
        
        %{
        function [result, is_identity] = compute_space_to_grid_shear(obj)
            result = eye(3);
            
            is_identity = hdng.utilities.isalmostequal(obj.shear(1), 0.0) ...
                          && hdng.utilities.isalmostequal(obj.shear(2), 0.0);
            
            if is_identity
                return
            end
            
            result(1, 2) = obj.shear(1);
            result(2, 1) = obj.shear(2);
        end
        
        function [result, is_identity] = compute_grid_to_space_shear(obj)
            
            result = eye(3);
            
            is_identity = hdng.utilities.isalmostequal(obj.shear(1), 0.0) ...
                          && hdng.utilities.isalmostequal(obj.shear(2), 0.0);
            
            if is_identity
                return
            end
            
            d = 1.0 / (1.0 - obj.shear(1) * obj.shear(2));
            
            result(1, 1) = d;
            result(2, 2) = d;
            
            result(1, 2) = -obj.shear(1) * d;
            result(2, 1) = -obj.shear(2) * d;
        end
        %}
        
        
        function [result, is_identity] = compute_space_to_grid_flip_and_scale(obj)
            
            result = eye(4);
            
            is_identity = ~obj.flip_u && ~obj.flip_v ...
                          && hdng.utilities.isalmostequal(obj.cell_size(1), 1.0) ...
                          && hdng.utilities.isalmostequal(obj.cell_size(2), 1.0) ...
                          && hdng.utilities.isalmostequal(obj.cell_size(3), 1.0);
            
            if is_identity
                return
            end
                      
            result(1, 1) = (obj.flip_u * -1.0 + ~obj.flip_u * 1.0) / obj.cell_size(1);
            result(2, 2) = (obj.flip_v * -1.0 + ~obj.flip_v * 1.0) / obj.cell_size(2);
            result(3, 3) = 1.0 / obj.cell_size(3);
            
            result(1, 4) = obj.flip_u * obj.resolution(1);
            result(2, 4) = obj.flip_v * obj.resolution(2);
            result(3, 4) = 0.0;
        end
        
        function [result, is_identity] = compute_grid_to_space_scale_and_flip(obj)
            
            result = eye(4);
            
            is_identity = ~obj.flip_u && ~obj.flip_v ...
                          && hdng.utilities.isalmostequal(obj.cell_size(1), 1.0) ...
                          && hdng.utilities.isalmostequal(obj.cell_size(2), 1.0) ...
                          && hdng.utilities.isalmostequal(obj.cell_size(3), 1.0);
            
            if is_identity
                return
            end
            
            result(1, 1) = (obj.flip_u * -1.0 + ~obj.flip_u * 1.0) * obj.cell_size(1);
            result(2, 2) = (obj.flip_v * -1.0 + ~obj.flip_v * 1.0) * obj.cell_size(2);
            result(3, 3) = obj.cell_size(3);
            
            result(1, 4) = obj.flip_u * obj.resolution(1) * obj.cell_size(1);
            result(2, 4) = obj.flip_v * obj.resolution(2) * obj.cell_size(2);
            result(3, 4) = 0.0;
        end
        
        
        function [result, is_identity] = compute_space_to_grid_offset(~)
            
            result = eye(4);
            
            is_identity = false;
            result(1:3, 4) = [1; 1; 1];
        end
        
        
        function [result, is_identity] = compute_grid_to_space_offset(~)
            
            result = eye(4);
            
            is_identity = false;
            result(1:3, 4) = -[1; 1; 1];
        end
        
        
        
        function [result, result_is_identity] = compute_space_to_grid_transform(obj)
            [result, result_is_identity] = obj.compute_transform(true);
        end
        
        function [result, result_is_identity] = compute_grid_to_space_transform(obj)
            [result, result_is_identity] = obj.compute_transform(false);
        end
        
        function [result, result_is_identity] = compute_transform(obj, space_to_grid)
            
            result_is_identity = true;
            result = eye(4);
            
            if space_to_grid
                
                % result = FlipAndScale * Shear * R * T;
            
                [T, is_identity] = obj.compute_space_to_grid_translation();

                if ~is_identity
                    if result_is_identity
                        result = T;
                    else
                        result = T * result; %#ok<UNRCH>
                    end
                    
                    result_is_identity = false;
                end

                [R, is_identity] = obj.compute_space_to_grid_rotation();


                if ~is_identity
                    if result_is_identity
                        result = R;
                    else
                        result = R * result;
                    end
                    
                    result_is_identity = false;
                end

                %{
                [Shear, is_identity] = obj.compute_space_to_grid_shear();

                if ~is_identity
                    if result_is_identity
                        result = Shear;
                    else
                        result = Shear * result;
                    end

                    result_is_identity = false;
                end
                %}
                
                [FlipAndScale, is_identity] = obj.compute_space_to_grid_flip_and_scale();

                if ~is_identity
                    if result_is_identity
                        result = FlipAndScale;
                    else
                        result = FlipAndScale * result;
                    end

                    result_is_identity = false;
                end
                
                [Offset, is_identity] = obj.compute_space_to_grid_offset();

                if ~is_identity
                    if result_is_identity
                        result = Offset;
                    else
                        result = Offset * result;
                    end

                    result_is_identity = false;
                end
            else
                
                % result = T * R * Shear * ScaleAndFlip;
                
                [T, is_identity] = obj.compute_grid_to_space_translation();

                if ~is_identity
                    
                    if result_is_identity
                        result = T;
                    else
                        result = result * T; %#ok<UNRCH>
                    end
                    
                    result_is_identity = false;
                end

                [R, is_identity] = obj.compute_grid_to_space_rotation();


                if ~is_identity
                    if result_is_identity
                        result = R;
                    else
                        result = result * R;
                    end

                    result_is_identity = false;
                end

                %{
                [Shear, is_identity] = obj.compute_grid_to_space_shear();

                if ~is_identity
                    if result_is_identity
                        result = Shear;
                    else
                        result = result * Shear;
                    end

                    result_is_identity = false;
                end
                %}
                
                [ScaleAndFlip, is_identity] = obj.compute_grid_to_space_scale_and_flip();

                if ~is_identity
                    if result_is_identity
                        result = ScaleAndFlip;
                    else
                        result = result * ScaleAndFlip;
                    end

                    result_is_identity = false;
                end
                
                [Offset, is_identity] = obj.compute_grid_to_space_offset();

                if ~is_identity
                    if result_is_identity
                        result = Offset;
                    else
                        result = result * Offset;
                    end

                    result_is_identity = false;
                end
            end
        end
    end
end
