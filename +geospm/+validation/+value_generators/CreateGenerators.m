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

classdef CreateGenerators < hdng.experiments.ValueGenerator
    %CreateGenerators Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        configurations
        debug_path
    end
    
    methods
        
        function obj = CreateGenerators(configurations, varargin)
            
            options = struct();
            
            for i=1:2:numel(varargin)
                name = varargin{i};
                value = varargin{i + 1};
                options.(name) = value;
            end
            
            for i=1:numel(configurations)
                
                configuration = configurations{i};
                
                if ~isfield(configuration, 'generator_type')
                    error('CreateGenerators.ctor(): Expected generator type in generator specification.');
                end
                
                if ~isfield(configuration, 'initialiser')
                    configuration.initialiser = ...
                        @(options) struct('create_domain', @(~) geospm.models.Domain(), ...
                                          'configure_generator', @(~) 0);
                end
                
                if ~isfield(configuration, 'options')
                    configuration.options = struct();
                end
                
                if ~isfield(configuration, 'spatial_resolution')
                    configuration.spatial_resolution = [100 100];
                end
                
                if ~isfield(configuration, 'description')
                    configuration.description = configuration.generator_type;
                end
                
                configurations{i} = configuration;
            end
            
            obj = obj@hdng.experiments.ValueGenerator();
            obj.configurations = configurations;
            
            obj.debug_path = [];
        end
    end
    
    methods (Access=protected)
        
        function result = create_iterator(obj, arguments) %#ok<INUSD>
            result = geospm.validation.value_generators.CreateGeneratorsIterator(obj);
        end
    end
    
    methods (Static, Access=private)
    end
end
