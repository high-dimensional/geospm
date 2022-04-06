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

classdef GenerateSpatialModelIterator < hdng.experiments.ValueIterator
    %GenerateSpatialModelIterator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        value_generator
        controls
        is_valid
        generator
        seed
        transform
        spatial_resolution
    end
    
    methods
        
        function obj = GenerateSpatialModelIterator(value_generator, generator_context, seed, transform, controls)
            
            obj = obj@hdng.experiments.ValueIterator();
            obj.value_generator = value_generator;
            obj.controls = controls;
            obj.is_valid = true;
            obj.generator = generator_context.generator;
            
            random_state = hdng.experiments.RandomHash(seed);
            obj.seed = random_state.for_strings({'spatial_model'});
            
            obj.transform = transform;
            obj.spatial_resolution = generator_context.spatial_resolution * transform(:,1:2);
        end
        
        function [is_valid, value] = next(obj)
            
            is_valid = obj.is_valid;
            value = [];
            
            if is_valid
                
                settings = obj.generator.get_settings();
                
                control_settings = fieldnames(obj.controls);
                
                for i=1:numel(control_settings)
                    setting = obj.controls.(control_settings{i});
                    settings.(setting.identifier) = setting.value;
                end
                
                [model, metadata] = obj.generator.render(obj.seed, obj.transform, obj.spatial_resolution, settings);
                
                value = struct();
                value.model = model;
                value.metadata = metadata;
                
                value = hdng.experiments.Value.from(value, obj.value_generator.description, missing, 'builtin.missing');
                
                obj.is_valid = false;
            end
        end
        
    end
    
    methods (Static, Access=private)
    end
    
end
