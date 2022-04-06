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

classdef SimulatedResult < hdng.experiments.ValueGenerator
    
    %SimulatedResult .
    %
    
    properties
        simulate_result
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = SimulatedResult()
            obj = obj@hdng.experiments.ValueGenerator();
            obj.simulate_result = @(rng, configuration, arguments) hdng.utilities.Dictionary();
        end
    end
    
    methods (Access=protected)
        
        function result = create_iterator(obj, arguments)
            rng = arguments.rng;
            configuration = arguments.configuration;
            
            result = obj.simulate_result(rng, configuration, arguments);
            result = hdng.experiments.ValueListIterator({result});
        end
    end
    
    methods (Static, Access=public)
        
        function generator = from(simulate_result)
            generator = hdng.experiments.SimulatedResult();
            generator.simulate_result = simulate_result;
        end
    end
    
end
