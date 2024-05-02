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

classdef Subsampling < geospm.models.SamplingStrategy
    %Subsampling Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        
        IDENTITY_MODE = 'identity'
        JITTER_MODE = 'jitter'
        AVERAGE_MODE = 'average'
        REMOVE_MODE = 'remove'
        
    end
    
    properties
        grid
        grid_options
        
        backtransform_coordinates
        coincident_observations_mode
    end
    
    methods
        
        function obj = Subsampling(grid, varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'grid_options')
                options.grid_options = struct();
                options.grid_options.spatial_resolution_max = 200;
            end
            
            obj = obj@geospm.models.SamplingStrategy();
            
            obj.grid_options = options.grid_options;
            obj.grid = grid;
            obj.backtransform_coordinates = false;
            
            obj.coincident_observations_mode = geospm.models.sampling.Subsampling.JITTER_MODE;
        end
        
        function [result, spatial_index] = observe(obj, model, N_samples, seed)
            
            rng = RandStream.create('mt19937ar', 'Seed', seed);
            
            spatial_data = model.attachments.spatial_data;
            spatial_index = model.attachments.spatial_index;
            
            attachments = spatial_data.attachments;
            
            %{
            [u, v, w] = obj.grid.space_to_grid(spatial_index.x, spatial_index.y, spatial_index.z);
            
            row_indices = obj.grid.clip_uvw(u, v, w);

            u = u(row_indices);
            v = v(row_indices);
            w = w(row_indices);
            %}

            [grid_spatial_index, row_indices, ~] = spatial_index.project(obj.grid);
            u = grid_spatial_index.x_protected;
            v = grid_spatial_index.y_protected;
            w = grid_spatial_index.z_protected;
            
            spatial_data = spatial_data.select(row_indices, []);
            spatial_index = spatial_index.select_by_segment(row_indices);

            if ischar(N_samples)
                if strcmp(N_samples, 'data')
                    N_samples = spatial_data.N;
                else
                    error('Unknown directive for N_samples: %s.', N_samples);
                end
            end

            jitter_x = mod(rng.rand([N_samples 1]), 1);
            jitter_y = mod(rng.rand([N_samples 1]), 1);
            
            %u = u - 1;
            %v = v - 1;
            w = w - 1;
            
            sample_indices = randperm(rng, spatial_data.N, N_samples);
            
            u = u(sample_indices, 1);
            v = v(sample_indices, 1);
            w = w(sample_indices, 1);
            
            switch obj.coincident_observations_mode

                case geospm.models.sampling.Subsampling.IDENTITY_MODE
                    result = spatial_data.select(sample_indices, []);
                    spatial_index = spatial_index.select_by_segment(sample_indices, @(specifier, modifier) obj.update_coordinates(specifier, modifier, u, v, w));
                
                case geospm.models.sampling.Subsampling.JITTER_MODE
                    result = spatial_data.select(sample_indices, []);
                    spatial_index = spatial_index.select_by_segment(sample_indices, @(specifier, modifier) obj.add_jitter(specifier, modifier, jitter_x, jitter_y, u, v, w));
                
                %{
                case geospm.models.sampling.Subsampling.AVERAGE_MODE
                    result = spatial_data.select(sample_indices, [], @(arguments) obj.average_coincident_observations(arguments, u, v, w));
                
                case geospm.models.sampling.Subsampling.REMOVE_MODE
                    result = spatial_data.select(sample_indices, [], @(arguments) obj.pick_one_coincident_observation(arguments, u, v, w));
                %}

                otherwise
                    error('geospm.models.sampling.Subsampling.observe(): Unknown observation mode: %s', obj.coincident_observations_mode);
            end

            result.attachments = attachments;
            result.attachments.spatial_resolution = model.spatial_resolution;
        end
        
        function result = char(obj)
            result = class(obj);
        end
    end
    
    methods (Access=private)
        
        function specifier = update_coordinates(obj, specifier, modifier, u, v, w) %#ok<INUSD>
            
            if ~obj.backtransform_coordinates
                specifier.per_row.x = cast(u, 'double');
                specifier.per_row.y = cast(v, 'double');
                specifier.per_row.z = cast(w, 'double');
            end
        end

        function specifier = add_jitter(obj, specifier, modifier, jitter_x, jitter_y, u, v, w) %#ok<INUSD>
            
            u = cast(u, 'double') + jitter_x;
            v = cast(v, 'double') + jitter_y;
            
            if obj.backtransform_coordinates
                [specifier.per_row.x, specifier.per_row.y, specifier.per_row.z] = obj.grid.grid_to_space(u, v, w);
            else
                specifier.per_row.x = cast(u, 'double');
                specifier.per_row.y = cast(v, 'double');
                specifier.per_row.z = cast(w, 'double');
            end
        end
        
        function result = average_coincident_observations(obj, args, u, v, w)

            w_is_constant = all(w(1) == w(2:end));
            
            if w_is_constant
                coords = [u, v];
                constant_w = w;
            else
                coords = [u, v, w];
                constant_w = [];
            end
            
            result = struct();
            result.observations = [];
            result.x = [];
            result.y = [];
            result.z = [];
            result.row_map = [];
            
            result = geospm.utilities.bin_coordinates(...
                @(state, coordinates, indices) ...
                    geospm.models.sampling.Subsampling.update_mean(...
                        state, coordinates, indices, args.observations, constant_w), ...
                coords, result);
            
            if obj.backtransform_coordinates
                result.x = args.x(result.row_map);
                result.y = args.y(result.row_map);
                result.z = args.z(result.row_map);
            else
                result.x = cast(u(result.row_map), 'double');
                result.y = cast(v(result.row_map), 'double');
                result.z = cast(w(result.row_map), 'double');
            end
        end
        
        function result = pick_one_coincident_observation(obj, args, u, v, w)
            
            w_is_constant = all(w(1) == w(2:end));
            
            if w_is_constant
                coords = [u, v];
                constant_w = w;
            else
                coords = [u, v, w];
                constant_w = [];
            end
            
            result = struct();
            result.observations = [];
            result.x = [];
            result.y = [];
            result.z = [];
            result.row_map = [];
            
            result = geospm.utilities.bin_coordinates(...
                @(state, coordinates, indices) ...
                    geospm.models.sampling.Subsampling.select_first(...
                        state, coordinates, indices, args.observations, constant_w), ...
                coords, result);
            
            if obj.backtransform_coordinates
                result.x = args.x(result.row_map);
                result.y = args.y(result.row_map);
                result.z = args.z(result.row_map);
            else
                result.x = cast(u(result.row_map), 'double');
                result.y = cast(v(result.row_map), 'double');
                result.z = cast(w(result.row_map), 'double');
            end
        end
    end
    
    
    methods (Static, Access=private)


        function state = update_mean(state, coordinates, indices, observations, constant_z)
            
            %fprintf('update: (%.0f, %.0f, %.0f) with %d observations.\n', coordinates(1), coordinates(2), coordinates(3), numel(indices));
            
            state.x = [state.x; coordinates(1)];
            state.y = [state.y; coordinates(2)];
            
            if numel(coordinates) == 3
                state.z = [state.z; coordinates(3)];
            else
                state.z = [state.z; constant_z];
            end
            
            local_observations = observations(indices, :);
            observations = mean(local_observations, 1);
            
            state.observations = [state.observations; observations];
            state.row_map = [state.row_map, indices(1)];
        end


        function state = select_first(state, coordinates, indices, observations, constant_z)
            
            %fprintf('update: (%.0f, %.0f, %.0f) with %d observations.\n', coordinates(1), coordinates(2), coordinates(3), numel(indices));
            
            state.x = [state.x; coordinates(1)];
            state.y = [state.y; coordinates(2)];
            
            if numel(coordinates) == 3
                state.z = [state.z; coordinates(3)];
            else
                state.z = [state.z; constant_z];
            end
            
            local_observations = observations(indices, :);
            observations = local_observations(1, :);
            
            state.observations = [state.observations; observations];
        end
    end
    
end
