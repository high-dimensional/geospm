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

classdef CreateSamplingStrategy < hdng.experiments.ValueGenerator
    %CreateSamplingStrategy Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        strategy_type
        description
        sampling_options
    end
    
    properties (Transient, Dependent)
    end
    
    methods
        
        function obj = CreateSamplingStrategy(strategy_type, varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'description')
                options.description = strategy_type;
            end
            
            obj = obj@hdng.experiments.ValueGenerator();
            
            obj.strategy_type = strategy_type;
            obj.description = options.description;
            obj.sampling_options = rmfield(options, 'description');
        end
        
    end
    
    methods (Access=protected)
        
        function result = create_iterator(obj, arguments)
            
            
            names = fieldnames(obj.sampling_options);
            
            for index=1:numel(names)
                name = names{index};
                arguments.(name) = obj.sampling_options.(name);
            end
            
            result= geospm.validation.value_generators.CreateSamplingStrategyIterator(obj, arguments);
        end
    end
    
    methods (Static, Access=private)
        
    end
    
end
