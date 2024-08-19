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

classdef VolumetricIndex < geospm.BaseSpatialIndex
    %VolumetricIndex Stores points in each segment implicitly in a volume.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
        segment_paths
    end

    properties

        grid_ % The space of the grid is the coordinate space of the 
              % locations represented by this index. Its resolution
              % always matches the native resolution of the underlying 
              % volumes. 
    end

    properties (GetAccess = private, SetAccess = private)
        
        segment_labels_
        segment_metadata_
    end
    
    properties (Dependent, Transient, GetAccess=private, SetAccess=private)
        effective_resolution
    end
    
    methods

        function result = get.effective_resolution(obj)

            volume_range = [[1, 1, 1]; obj.grid_.resolution + 1];

            [sx, sy, sz] = obj.grid_.grid_to_space(volume_range(:, 1), volume_range(:, 2), volume_range(:, 3));

            space_range = sort([sx, sy, sz]);
            
            result = space_range(2, :) - space_range(1, :);
        end

        
        function obj = VolumetricIndex(segment_paths, segment_labels, crs, grid)
            
            %Construct a VolumetricIndex object from a collection of
            %volumes.
            %
            
            if ~exist('grid', 'var')
                grid = geospm.Grid();
            end

            if ~exist('crs', 'var')
                crs = hdng.SpatialCRS.empty;
            end
            
            if ~iscell(segment_paths) || size(segment_paths, 2) ~= 1
                error('''segment_paths'' is not a cell array value; specify ''segment_paths'' as a S x 1 cell array.');
            end

            if isempty(segment_labels)
                segment_labels = arrayfun(@(x) num2str(x), (1:numel(segment_paths))', 'UniformOutput', false);
            end
                        
            if ~all(cellfun(@(x) ischar(x), segment_paths))
                error('''segment_paths'' is not a cell array of chars; specify ''segment_paths'' as a S x 1 cell array of char values.');
            end

            obj@geospm.BaseSpatialIndex(crs);
            
            obj.segment_paths = segment_paths;
            obj.segment_labels_ = segment_labels;

            obj.grid_ = grid;
            obj.segment_metadata_ = cell(numel(segment_paths), 1);
        end
        

        function result = select(obj, row_selection, column_selection, transform) %#ok<STOUT,INUSD>
            error('select() is not supported by VolumetricIndex.');
        end

        function [x, y, z] = xyz_coordinates_for_segment(obj, segment_index)

            path = obj.segment_paths{segment_index};

            [locations, count, ~, ~] = geospm.utilities.recover_points_from_nifti(path);
            locations = geospm.VolumetricIndex.multiply_locations(locations, count);

            [x, y, z] = obj.grid_.grid_to_space(locations(:, 1), locations(:, 2), locations(:, 3));
        end
        
        function result = select_by_segment(obj, segment_selection, transform) %#ok<INUSD>
            
            if ~exist('segment_selection', 'var')
                segment_selection = [];
            end
            
            segment_selection = obj.normalise_segment_selection(segment_selection);

            if ~exist('transform', 'var')

                paths = obj.segment_paths(segment_selection);
                labels = obj.segment_labels(segment_selection);
                
                result = geospm.VolumetricIndex(paths, ...
                                                labels, ...
                                                obj.crs, ...
                                                obj.grid_ ...
                                                );

                return
            end

            error('Transform selections are not supported for VolumetricIndex.');
        end

        function [spatial_index, segment_indices] = project(obj, grid, assigned_grid, as_integers) %#ok<INUSD>
                    
            if grid.has_rotation
                error('Projection grid has a rotational component, which is currently not supported.');
            end
        
            if ~exist('assigned_grid', 'var') || isempty(assigned_grid)
                assigned_grid = grid;
            end
            
            projected_grid = geospm.Grid.concat(obj.grid_, grid, true);
            
            grid_range = [[1, 1, 1]; grid.resolution + 1];

            [px, py, pz] = projected_grid.space_to_grid(...
                                grid_range(:, 1), ...
                                grid_range(:, 2), ...
                                grid_range(:, 3));
            
            grid_range = sort([px, py, pz]);

            segment_indices = zeros(obj.S, 1);
            S_projected = 0;
            
            for index=1:obj.S
                metadata = obj.get_segment_metadata(index);

                intersect_min = hdng.utilities.intersect_boxes(...
                    grid_range(1, :), grid_range(2, :), ...
                    metadata.min_xyz, metadata.max_xyz + 1);
                
                % if the minimum of the intersection is empty there is no
                % intersection

                if isempty(intersect_min)
                    continue;
                end

                S_projected = S_projected + 1;
                segment_indices(S_projected) = index;
            end

            segment_indices = segment_indices(1:S_projected);
            
            % Drop the CRS when creating the projected index

            spatial_index = geospm.VolumetricIndex(...
                                obj.segment_paths(segment_indices), ...
                                obj.segment_labels(segment_indices), ...
                                [], projected_grid);
            
            spatial_index.attachments.assigned_grid = assigned_grid;
        end
        
        function result = convolve_segment(obj, segment_index, span_origin, span_limit, kernel, kernel_key)

            if ~exist('kernel_key', 'var')
                kernel_key = '';
            end
            
            path = obj.segment_paths{segment_index};

            voxel_start = floor(span_origin);
            voxel_end = floor(span_limit - 1);
            cache_key = '';
            cache_directory = '';
            was_cached = false;

            if ~isempty(kernel_key)
                cache_key = obj.convolution_cache_key(path, obj.effective_resolution, voxel_start, voxel_end, kernel_key);
                cache_directory = fullfile(fileparts(path), 'cache');

                [was_cached, result] = obj.retrieve_value_from_cache(cache_key, cache_directory);
                
                if was_cached
                    return
                end
            end
            
            [locations, count, ~, ~] = geospm.utilities.recover_points_from_nifti(path);
            
            [x, y, z] = obj.grid_.grid_to_space(locations(:, 1), locations(:, 2), locations(:, 3));
            locations = cast(floor([x, y, z]), 'int64');
            
            data = zeros(obj.effective_resolution);
            indices = sub2ind(size(data), locations(:, 1), locations(:, 2), locations(:, 3));
            data(indices) = count;

            selected = data(voxel_start(1):voxel_end(1), voxel_start(2):voxel_end(2), voxel_start(3):voxel_end(3));
            result = convn(selected, kernel, 'same');
            
            if ~was_cached && ~isempty(cache_key)
                obj.commit_value_to_cache(cache_key, result, cache_directory);
            end
        end

        function result = as_json_struct(obj, varargin)
            %Creates a JSON representation of this SpatialIndex as a struct.
            % Possible name-value arguments are:
            % segment_base_path - Save segment paths relative to this path

            result = struct();
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'segment_base_path')
                options.segment_base_path = [];
            end

            result.ctor = 'geospm.VolumetricIndex';
            
            paths = obj.segment_paths;

            if ~isempty(options.segment_base_path)
                for index=1:numel(paths)
                    path = paths{index};
                    
                    if ~startsWith(path, options.segment_base_path)
                        continue
                    end

                    path = path(numel(options.segment_base_path) + 1 + numel(filesep):end);
                    path = fullfile('${SEGMENT_BASE_PATH}', path);
                    paths{index} = path;
                end
            end

            result.segment_paths = paths;
            result.segment_labels = obj.segment_labels;
            result.grid = obj.grid_.as_json_struct();
        end
        
        function write_as_matlab(obj, filepath, varargin)
            %Writes a Matlab struct of this VolumetricIndex object to a file.
            % The range of possible name-value arguments is documented for
            % the as_json_struct() method.
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'segment_base_path')
                options.segment_base_path = fileparts(filepath);
            end
            
            arguments = hdng.utilities.struct_to_name_value_sequence(options);
            
            write_as_matlab@geospm.BaseSpatialIndex(obj, filepath, arguments{:});
        end
    end
    
    methods (Access=protected)

        function result = convolution_cache_key(~, path, effective_resolution, voxel_start, voxel_end, kernel_key)
            
            effective_resolution = sprintf('%d,%d,%d', effective_resolution(1), effective_resolution(2), effective_resolution(3));
            
            voxel_start = sprintf('%d,%d,%d', voxel_start(1), voxel_start(2), voxel_start(3));
            voxel_end = sprintf('%d,%d,%d', voxel_end(1), voxel_end(2), voxel_end(3));

            [directory, name, ext] = fileparts(path);
            [~, directory_name, directory_ext] = fileparts(directory);

            result = [directory_name directory_ext ':' name ext ';' kernel_key ';' effective_resolution ';' voxel_start ';' voxel_end];
        end

        function result = hash_key_for_cache(~, key)
            result = hdng.utilities.hash_strings({key}, 'uint64');
            result = num2str(result, '%x');
        end

        function [was_cached, result] = retrieve_value_from_cache(obj, key, directory)
           was_cached = false;
           result = [];

           hashed_key = obj.hash_key_for_cache(key);

           hash_directory = fullfile(directory, hashed_key);

           if ~exist(hash_directory, 'dir')
               return;
           end
           

           keys_path = fullfile(hash_directory, 'keys');
           
           try
                key_list = hdng.utilities.load_text(keys_path);
           catch 
               return;
           end

           key_list = split(key_list, '\n');
           key_list = cellfun(@(x) strip(x), key_list, 'UniformOutput', false);
           empty = cellfun(@(x) isempty(x), key_list);
           key_list = key_list(~empty);

           entry_index = find(strcmp(key, key_list));
           
           if isempty(entry_index)
               return;
           end
           
            entry_directory = fullfile(hash_directory, sprintf('%d', entry_index));
            contents_file = fullfile(entry_directory, 'contents');

            try
                contents = load(contents_file);
            catch
                return;
            end

            result = contents.value;
            was_cached = true;
        end
        
        function commit_value_to_cache(obj, key, value, directory)


            hashed_key = obj.hash_key_for_cache(key);

            hash_directory = fullfile(directory, hashed_key);

            if ~exist(hash_directory, 'dir')
                mkdir(hash_directory);
            end
           

            keys_path = fullfile(hash_directory, 'keys');

            try
                key_list = hdng.utilities.load_text(keys_path);
            catch
                key_list = '';
            end
            
            key_list = split(key_list, '\n');
            key_list = cellfun(@(x) strip(x), key_list, 'UniformOutput', false);
            empty = cellfun(@(x) isempty(x), key_list);
            key_list = key_list(~empty);

            entry_index = find(strcmp(key, key_list));
           
            if isempty(entry_index)
                key_list = [key_list; {key}];
                entry_index = numel(key_list);

                key_list = join(key_list, '\n');
                key_list = key_list{1};
                hdng.utilities.save_text(key_list, keys_path);
            end
            
            entry_directory = fullfile(hash_directory, sprintf('%d', entry_index));

            if ~exist(entry_directory, 'dir')
                mkdir(entry_directory);
            end

            contents_file = fullfile(entry_directory, 'contents');
            
            save(contents_file, 'value');
        end
        
        function result = render_in_figure(obj, origin, frame_size, variant, varargin) %#ok<INUSD>
            
            warning('render_in_figure() is not supported for VolumetricIndex.');
            
            result = struct();
            result.corrective_scale_factor = 1.0;
        end

        function result = get_segment_path(obj, segment_number)
            
            result = obj.segment_paths{segment_number};
        end

        function result = get_segment_metadata(obj, segment_number)

            if ~isempty(obj.segment_metadata_{segment_number})
                result = obj.segment_metadata_{segment_number};
                return;
            end

            path = obj.get_segment_path(segment_number);
            
            [directory, name, ~] = fileparts(path);
            [~, name, ~] = fileparts(name);

            metadata_file = fullfile(directory, [name '.json']);
            metadata_json = hdng.utilities.load_json(metadata_file, 'as_struct', true);

            metadata = geospm.VolumetricMetadata.from_json_struct(metadata_json);

            if isempty(metadata.min_xyz)
                metadata.min_xyz = [1, 1, 1];
            end

            if isempty(metadata.max_xyz)
                metadata.max_xyz = obj.grid_.resolution;
            end

            obj.segment_metadata_{segment_number} = metadata;

            result = metadata;
        end
        
        function result = access_S(obj)
            result = size(obj.segment_paths, 1);
        end

        function result = access_segment_sizes(obj) %#ok<STOUT,MANU>
            error('access_segment_sizes() must be implemented by a subclass.');
        end
        
        function result = access_segment_labels(obj)
            result = obj.segment_labels_;
        end
        
        function assign_property(obj, name, values)
            obj.(name) = values;
        end

        function [specifier, modifier] = define_clone_specifier(obj)
            
            [specifier, modifier] = define_clone_specifier@geospm.BaseSpatialIndex(obj);
            
            % Provide a data element with maximum number of rows allowable
            % in Matlab
            specifier.data = zeros(2^48 - 1, 0);

            specifier.segment_paths = obj.segment_paths;
            specifier.segment_labels = obj.segment_labels;
            specifier.grid = obj.grid_;
        end
    
        function result = create_clone_from_specifier(~, specifier)
            
            result = geospm.VolumetricIndex(specifier.segment_paths, ...
                                            specifier.segment_labels, ...
                                            specifier.grid, ...
                                            specifier.crs);
        end

    end

    methods (Static, Access=private)

        function result = multiply_locations(locations, count)
            
            result = zeros(sum(count), 3);
            output_index = 1;
        
            for index=1:size(locations, 1)
                location = locations(index, :);
                C = count(index);
        
                result(output_index:output_index + C - 1, :) = repmat(location, C, 1);
                output_index = output_index + C;
            end
        end
    end
    
    methods (Static)

        function result = from_json_struct_impl(specifier, options)
            
            if ~isfield(specifier, 'segment_paths') || ~iscell(specifier.segment_paths)
                error('Missing ''segment_paths'' field in json struct or ''segment_paths'' field is not a cell array.');
            end
           
            if ~isfield(specifier, 'segment_labels') || ~iscell(specifier.segment_labels)
                error('Missing ''segment_labels'' field in json struct or ''segment_labels'' field is not a cell array.');
            end
            
            if isfield(specifier, 'crs') && ~ischar(specifier.crs)
                error('''crs'' field is not char.');
            end
            
            if isfield(specifier, 'grid') && ~isstruct(specifier.grid)
                error('''grid'' field is not a struct.');
            end
            
            crs = '';

            if isfield(specifier, 'crs') && ~isempty(specifier.crs)
                crs = specifier.crs;
            end

            grid = [];

            if isfield(specifier, 'grid') && ~isempty(specifier.grid)
                grid = geospm.Grid.from_json_struct(specifier.grid);
            end

            if isfield(options, 'segment_base_path') && ~isempty(options.segment_base_path)
                for index=1:numel(specifier.segment_paths)
                    path = specifier.segment_paths{index};
                    path = replace(path, '${SEGMENT_BASE_PATH}', options.segment_base_path);
                    specifier.segment_paths{index} = path;
                end
            end
            
            result = geospm.VolumetricIndex(specifier.segment_paths, specifier.segment_labels, crs, grid);
        end

        function result = load_from_nifti_files_in_directory(directory, order_fn, crs, grid)
            
            if ~exist('grid', 'var')
                grid = geospm.Grid();
            end

            if ~exist('crs', 'var')
                crs = hdng.SpatialCRS.empty;
            end

            file_paths = hdng.utilities.list_files(directory);

            segment_paths = cell(numel(file_paths), 1);
            segment_names = cell(numel(file_paths), 1);
            segment_files = cell(numel(file_paths), 1);

            segment_count = 0;
        
            for index=1:numel(file_paths)
        
                file_path = file_paths{index};
                [~, name, ext] = fileparts(file_path);

                name = [name, ext]; %#ok<AGROW>
                parts = split(name, '.');
                base_name = parts{1};
                ext = join(parts(2:end), '.');
                ext = ext{1};
        
                if ~any(strcmp(ext, {'nii', 'nii.gz'}))
                    %warning('Skipping file ''%s''...', name);
                    continue
                end

                segment_count = segment_count + 1;
                
                segment_paths{segment_count} = file_path;
                segment_names{segment_count} = base_name;
                segment_files{segment_count} = name;
                
            end

            order_args = struct();
            order_args.segment_paths = segment_paths(1:segment_count);
            order_args.segment_names = segment_names(1:segment_count);
            order_args.segment_files = segment_files(1:segment_count);

            order = order_fn(order_args);

            result = geospm.VolumetricIndex(order_args.segment_paths(order), order_args.segment_names(order), crs, grid);
        end
    end
end
