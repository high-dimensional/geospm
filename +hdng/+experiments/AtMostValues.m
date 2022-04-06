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

classdef AtMostValues < hdng.experiments.ValueGenerator
    
    %AtMostValues Provides an iterator over a list of values.
    %
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
        N
        value_generator
    end
    
    methods
        
        function obj = AtMostValues()
            obj = obj@hdng.experiments.ValueGenerator();
            obj.N = 1;
            obj.value_generator = hdng.experiments.ValueGenerator.empty;
        end
        
    end
    
    methods (Access=protected)
        
        function arguments = prepare_arguments(~, arguments)
        end
        
        function result = create_iterator(obj, arguments)
            
            g = obj.value_generator(arguments);
            result = hdng.experiments.AtMostValuesIterator(obj.N, g);
        end
    end
    
    methods (Static, Access=public)
        
        function generator = from(N, value_generator)
            
            generator = hdng.experiments.AtMostValues();
            generator.N = N;
            generator.value_generator = value_generator;
        end
    end
    
end
