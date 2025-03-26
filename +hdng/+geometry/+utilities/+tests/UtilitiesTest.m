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

classdef UtilitiesTest < matlab.unittest.TestCase

    properties
        polygonshapes
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
 
    methods(TestMethodSetup)
        
        function create_shapes(obj)
            
            [directory, ~, ~] = fileparts(mfilename('fullpath'));
            
            %{
            parts = split(directory, filesep);
            directory = join(parts(1:end-1), filesep);
            directory = directory{1};
            %}
            
            file_path = fullfile(directory, 'polygonshapes', 'polygonshapes.shp');
            obj.polygonshapes = shaperead(file_path);
        end
    end
 
    methods(TestMethodTeardown)
    end
 
    methods(Test)
        
        function test_disassemble_shapevector(obj)
            
            [shapes, parts, coordinates] = ...
                hdng.geometry.utilities.disassemble_shapevector(...
                obj.polygonshapes); %#ok<ASGLU>
            
        end
    end
    
    methods
        
        
    end
end
