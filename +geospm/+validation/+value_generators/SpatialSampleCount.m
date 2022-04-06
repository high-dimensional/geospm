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

classdef SpatialSampleCount < hdng.experiments.ValueGenerator
    %SpatialSampleCount Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        description
    end
    
    methods
        
        function obj = SpatialSampleCount(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'description')
                options.description = '';
            end
            
            obj = obj@hdng.experiments.ValueGenerator();
            obj.description = options.description;
        end
        
    end
    
    methods (Access=protected)
        
        
        function result = create_iterator(~, arguments)
            
            generator_context = arguments.generator;
            transform = arguments.transform;
            sample_density = arguments.sample_density;
            
            spatial_resolution = generator_context.spatial_resolution * transform(:,1:2);
            n_cells = prod(spatial_resolution);
            
            n_samples = ceil(sample_density * n_cells / 25.0);
            
            n_samples = hdng.experiments.Value.from(n_samples);
            result = hdng.experiments.ValueListIterator({n_samples});
        end
        
    end
    
    methods (Static, Access=private)
        
    end
    
end
