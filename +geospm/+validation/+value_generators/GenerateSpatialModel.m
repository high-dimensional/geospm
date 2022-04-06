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

classdef GenerateSpatialModel < hdng.experiments.ValueGenerator
    %GenerateSpatialModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        description
    end
    
    methods
        
        function obj = GenerateSpatialModel(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'description')
                options.description = '';
            end
            
            obj = obj@hdng.experiments.ValueGenerator();
            obj.description = options.description;
        end
    end
    
    methods (Access=protected)
        
        function result = create_iterator(obj, arguments)
            
            generator = arguments.generator;
            experiment_seed = arguments.random_seed;
            transform = arguments.transform;
            
            arguments = rmfield(arguments, 'generator');
            arguments = rmfield(arguments, 'transform');
            arguments = rmfield(arguments, 'random_seed');
            arguments = rmfield(arguments, 'stage_random_seed');
            arguments = rmfield(arguments, 'study_random_seed');
            
            result= geospm.validation.value_generators.GenerateSpatialModelIterator(obj, generator, experiment_seed, transform, arguments);
        end
    end
    
    methods (Static, Access=private)
        
    end
    
end
