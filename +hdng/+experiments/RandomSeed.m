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

classdef RandomSeed < hdng.experiments.ValueGenerator
    
    %RandomSeed Provides an iterator over a list of values.
    %
    
    properties
        seed_requirement
        seed_type
        
        inputs
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = RandomSeed(inputs)
            obj = obj@hdng.experiments.ValueGenerator();
            obj.seed_requirement = 'stage_random_seed';
            obj.seed_type = 'uint32';
            obj.inputs = inputs;
        end
    end
    
    methods (Access=protected)
        
        function arguments = prepare_arguments(~, arguments)
        end
        
        function result = create_iterator(obj, arguments)
            
            seed = arguments.(obj.seed_requirement);
            
            names = obj.inputs;
            strings = cell(numel(names), 1);
            
            for index=1:numel(names)
                name = names{index};
                
                value = arguments.(name);
                strings{index} = value.digest;
            end
            
            random_state = hdng.experiments.RandomHash(seed.content);
            
            value = random_state.for_strings(strings, obj.seed_type);
            value = hdng.experiments.Value.from(value);
            
            result = hdng.experiments.ValueListIterator({value});
        end
    end
    
    methods (Static, Access=public)
    end
    
end
