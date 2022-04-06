% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2019,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef VariableTest < matlab.unittest.TestCase
 
    properties
        N
        variables
        names
    end
 
    methods(TestMethodSetup)
        
        function create_variables(obj)
            
            obj.N = 1000;
            obj.variables = cell(obj.N, 1);
            obj.names = hdng.utilities.randidentifier(3, 8, obj.N);
            
            for i=1:obj.N
                name = obj.names{i};
                variable = hdng.pipeline.Variable(name, i);
                obj.variables{i} = variable;
            end
        end
    end
 
    methods(TestMethodTeardown)
    end
 
    methods
        
    end
    
    methods(Test)
        
        
    end
end
