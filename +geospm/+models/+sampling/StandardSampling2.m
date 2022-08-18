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

classdef StandardSampling2 < geospm.models.SamplingStrategy
    %StandardSampling2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        
        IDENTITY_MODE = 'identity'
        JITTER_MODE = 'jitter'
        AVERAGE_MODE = 'average'
        REMOVE_MODE = 'remove'
        
    end
    
    properties
        
        add_observation_noise % Add random noise to the observations
        observation_noise
        
        coincident_observations_mode
    end
    
    methods
        
        function obj = StandardSampling2(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'coincident_observations_mode')
                options.coincident_observations_mode = geospm.models.sampling.StandardSampling2.JITTER_MODE;
            end
            
            if ~isfield(options, 'add_observation_noise')
                options.add_observation_noise = false;
            end
            
            if ~isfield(options, 'observation_noise')
                options.observation_noise = 0.005;
            end
            
            obj = obj@geospm.models.SamplingStrategy();
            
            obj.add_observation_noise = options.add_observation_noise;
            obj.observation_noise = options.observation_noise;
            
            obj.coincident_observations_mode = options.coincident_observations_mode;
        end
        
        function [X, Y] = sample_density(~, density, N_samples, rng)
            
            if density.dimensions ~= 1
                error('StandardSampling.sample_density(): Expected scalar-valued quantity.');
            end
            
            values = density.flatten();
            
            %Create a 1-dimensional distribution over all location
            %cells/indices
            
            distribution = geospm.models.Distribution(numel(values));
            distribution.compute_from_marginals({values(:)});
            
            %Generate the desired number of samples
            
            samples = rng.rand([N_samples 1]);
            samples = distribution.samples_from_uniform(samples);
            samples = cast(samples, 'int32');
            
            %Compute XY coordinates from samples
            
            Y = idivide(samples, density.model.spatial_resolution(1), 'ceil');
            X = samples - (Y - 1) .* (density.model.spatial_resolution(1));
            
            Y = cast(Y, 'double');
            X = cast(X, 'double');
        end
        
        function result = observe(obj, model, N_samples, seed)
            
            rng = RandStream.create('mt19937ar', 'Seed', seed);
            
            domain = model.domain;
            %distribution = geospm.models.Distribution(model.joint_distribution.dimensions);
            
            [x, y] = obj.sample_density(model.density, N_samples, rng);
            
            %Generate jitter samples every time...
            
            jitter_x = mod(rng.rand([N_samples 1]), 1.0);
            jitter_y = mod(rng.rand([N_samples 1]), 1.0);
            
            N_samples = numel(x);
            
            observations = zeros(N_samples, domain.N_variables);
            categories = zeros(N_samples, 1, 'int64');
            
            % Generate N uniform samples in the interval (0, 1)
            samples = rng.rand([N_samples, 1]);
            
            for i=1:N_samples
                
                sample_x = x(i);
                sample_y = y(i);
                
                [~, distribution] = model.joint_distribution.value_at(sample_x, sample_y);
                
                observation = distribution.sample_from_uniform(samples(i));
                
                noise = rng.rand([1 distribution.N_dimensions]) * obj.observation_noise;
                
                if ~obj.add_observation_noise
                    noise = 0;
                end
                
                observations(i, :) = observation - 1 + noise;
                
                observation = num2cell(observation);
                
                category = distribution.sub2ind(observation{:});
                categories(i) = category;
            end
            
            sample_indices = randperm(rng, N_samples, N_samples);
            
            spatial_data = geospm.SpatialData(x, y, zeros(N_samples, 1), observations);
            spatial_data.set_variable_names(model.domain.variable_names');
            spatial_data.set_categories(categories);
            
            if strcmp(obj.coincident_observations_mode, geospm.models.sampling.StandardSampling2.IDENTITY_MODE)
                result = spatial_data.select([], []);
            elseif strcmp(obj.coincident_observations_mode, geospm.models.sampling.StandardSampling2.JITTER_MODE)
                result = spatial_data.select([], [], @(arguments) obj.add_jitter(arguments, jitter_x, jitter_y));
            elseif strcmp(obj.coincident_observations_mode, geospm.models.sampling.StandardSampling2.AVERAGE_MODE)
                result = spatial_data.select([], [], @(arguments) obj.average_coincident_observations(arguments));
                sample_indices = sample_indices(sample_indices <= result.N);
                result = result.select(sample_indices, []);
            elseif strcmp(obj.coincident_observations_mode, geospm.models.sampling.StandardSampling2.REMOVE_MODE)
                result = spatial_data.select([], [], @(arguments) obj.pick_one_coincident_observation(arguments));
                sample_indices = sample_indices(sample_indices <= result.N);
                result = result.select(sample_indices, []);
            else
                error('geospm.models.sampling.StandardSampling2.observe(): Unknown observation mode: %s', obj.coincident_observations_mode);
            end
            
            result.attachments.spatial_resolution = model.spatial_resolution;
        end
        
        function result = char(obj)
            result = class(obj);
        end
    end

    methods (Access=private)
        
        
        function args = add_jitter(~, args, jitter_x, jitter_y)
            args.x = args.x + jitter_x;
            args.y = args.y + jitter_y;
        end
        
        function args = update_coordinates(~, args, x, y, z)
            args.x = x;
            args.y = y;
            args.z = z;
        end
        
        function result = average_coincident_observations(~, args)
            
            z_is_constant = all(args.z(1) == args.z(2:end));
            
            if z_is_constant
                X = [args.x, args.y];
                constant_z = args.z(1);
            else
                X = [args.x, args.y, args.z];
                constant_z = [];
            end
            
            result = struct();
            result.observations = [];
            result.x = [];
            result.y = [];
            result.z = [];
            result.row_map = [];
            
            result = geospm.utilities.bin_coordinates(...
                @(state, coordinates, indices) ...
                    geospm.models.sampling.StandardSampling2.update_mean(...
                        state, coordinates, indices, args.observations, constant_z), ...
                X, result);
        end
        
        function result = pick_one_coincident_observation(~, args)
            
            z_is_constant = all(args.z(1) == args.z(2:end));
            
            if z_is_constant
                X = [args.x, args.y];
                constant_z = args.z(1);
            else
                X = [args.x, args.y, args.z];
                constant_z = [];
            end
            
            result = struct();
            result.observations = [];
            result.x = [];
            result.y = [];
            result.z = [];
            result.row_map = [];
            
            result = geospm.utilities.bin_coordinates(...
                @(state, coordinates, indices) ...
                    geospm.models.sampling.StandardSampling2.select_first(...
                        state, coordinates, indices, args.observations, constant_z), ...
                X, result);
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
