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

classdef StandardSampling < geospm.models.SamplingStrategy
    %StandardSampling Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        add_position_jitter % Add random noise to the sample locations
        add_observation_noise % Add random noise to the observations
        observation_noise
    end
    
    methods
        
        function obj = StandardSampling(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'add_position_jitter')
                options.add_position_jitter = false;
            end
            
            if ~isfield(options, 'add_observation_noise')
                options.add_observation_noise = false;
            end
            
            if ~isfield(options, 'observation_noise')
                options.observation_noise = 0.005;
            end
            
            obj = obj@geospm.models.SamplingStrategy();
            obj.add_position_jitter = options.add_position_jitter;
            obj.add_observation_noise = options.add_observation_noise;
            obj.observation_noise = options.observation_noise;
        end
        
        function [X, Y] = sample_density(obj, density, N_samples, rng)
            
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
            
            %Generate jitter samples every time...
            
            jitter_x = mod(rng.rand([N_samples 1]), 1.0);
            jitter_y = mod(rng.rand([N_samples 1]), 1.0);
            
            %...but only apply them if requested
            
            if obj.add_position_jitter
                Y = Y + jitter_x;
                X = X + jitter_y;
            end
        end
        
        function result = observe(obj, model, N_samples, seed)
            
            rng = RandStream.create('mt19937ar', 'Seed', seed);
            
            domain = model.domain;
            
            [x, y] = obj.sample_density(model.density, N_samples, rng);
            
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
            
            result = geospm.SpatialData(x, y, zeros(N_samples, 1), observations);
            result.set_variable_names(model.domain.variable_names');
            result.set_categories(categories);
            result.attachments.spatial_resolution = model.spatial_resolution;
        end
        
        function result = char(obj)
            result = class(obj);
        end
    end

    
    methods (Static, Access=private)
    end
    
end
