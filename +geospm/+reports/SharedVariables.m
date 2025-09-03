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

classdef SharedVariables < handle
    
    %SharedVariables
    %

    properties (GetAccess=public, SetAccess=public)
        
        dataset_cache       % dataset cache
        dataset_aliases     % dataset aliases

        volume_generators   % the volume generators
        
        host_name
        resources
        resource_manager

        easting_column
        northing_column
    end
    
    methods
        
        function obj = SharedVariables(dataset_cache, dataset_aliases, ...
                volume_generators, resources)
            

            if ~exist('dataset_cache', 'var')
                dataset_cache = [];
            end

            if ~exist('dataset_aliases', 'var')
                dataset_aliases = [];
            end

            if ~exist('volume_generators', 'var')
                volume_generators = [];
            end

            if ~exist('resources', 'var')
                resources = [];
            end

            
            if ~isobject(dataset_cache) && isempty(dataset_cache)
                dataset_cache = hdng.utilities.Dictionary();
            end

            if ~isobject(dataset_aliases) && isempty(dataset_aliases)
                dataset_aliases = hdng.utilities.Dictionary();
            end

            if ~isobject(volume_generators) && isempty(volume_generators)
                volume_generators = hdng.utilities.Dictionary();
            end

            if ~isobject(resources) && isempty(resources)
                resources = hdng.utilities.Dictionary();
            end


            obj.dataset_cache = dataset_cache;
            obj.dataset_aliases = dataset_aliases;

            obj.volume_generators = volume_generators;

            obj.host_name = '';
            obj.resources = resources;
            obj.resource_manager = [];

            obj.easting_column = 'easting';
            obj.northing_column = 'northing';
        end
        
        function update_volume_generators(obj, key, record)
        
            if ~obj.volume_generators.holds_key(key)
                
                specifier = struct();
                
                specifier.smoothing_levels = record('configuration.smoothing_levels').unpack();
                specifier.smoothing_levels = cell2mat(specifier.smoothing_levels);
                specifier.smoothing_levels_p_value = record('configuration.smoothing_levels_p_value').unpack();
                specifier.smoothing_method = record('configuration.smoothing_method').unpack();
                
                %specifier.smoothing_method.parameters.gaussian_method

                obj.volume_generators(key) = specifier;
            end
        end
    end
end
