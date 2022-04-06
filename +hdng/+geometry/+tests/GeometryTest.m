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

classdef GeometryTest < matlab.unittest.TestCase & hdng.geometry.Handler

    properties
        directory
        polygonshapes
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
 
    methods(TestClassSetup)
        
        function create_shapes(obj)
            
            [obj.directory, ~, ~] = fileparts(mfilename('fullpath'));
            parts = split(obj.directory, filesep);
            obj.directory = join(parts(1:end-1), filesep);
            obj.directory = obj.directory{1};
        end
    end
 
    methods(TestClassTeardown)
    end
 
    methods(Test)
        
        function test_collection_from_wkt(obj)
            
            file_path = fullfile(obj.directory, '+utilities', 'wkt', 'points.wkt');
            collection = hdng.geometry.Collection.from_wkt(file_path);
            collection.handle_with(obj);  
        end
    end
    
    methods
        
        function result = handle_points(~, points)
            result = [];
            
            N_points = points.N_elements;
            
            for i=1:N_points
                point = points.nth_element(i); %#ok<NASGU>
            end
        end

        function result = handle_polylines(~, polylines) %#ok<INUSD>
            result = [];
        end

        function result = handle_polygons(~, polygons) %#ok<INUSD>
            result = [];
        end
        
    end
end
