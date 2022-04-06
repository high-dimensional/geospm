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

classdef CreateGeneratorsIterator < hdng.experiments.ValueIterator
    %CreateGeneratorsIterator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        value_generator
        index
    end
    
    methods
        
        function obj = CreateGeneratorsIterator(value_generator)
            obj = obj@hdng.experiments.ValueIterator();
            obj.value_generator = value_generator;
            obj.index = 1;
        end
        
        function [is_valid, value] = next(obj)
            
            is_valid = obj.index <= numel(obj.value_generator.configurations);
            value = [];
            
            if is_valid
                
                configuration = obj.value_generator.configurations{obj.index};
                
                initialiser_ctor = str2func(configuration.initialiser);
                initialiser = initialiser_ctor(configuration.options);
                
                domain = initialiser.create_domain();
                
                generator = geospm.models.Generator.create(configuration.generator_type, domain);
                initialiser.configure_generator(generator);
                
                generator.debug_path = obj.value_generator.debug_path;
                
                value = struct();
                value.generator = generator;
                value.spatial_resolution = initialiser.spatial_resolution;
                
                value = hdng.experiments.Value.from(value, configuration.description, missing, 'builtin.missing');
                
                obj.index = obj.index + 1;
            end
        end
        
    end
    
    methods (Static, Access=private)
    end
    
end
