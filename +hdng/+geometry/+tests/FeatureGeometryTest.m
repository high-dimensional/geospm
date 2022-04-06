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

classdef FeatureGeometryTest < matlab.unittest.TestCase & hdng.geometry.Handler

    properties
        polygons_path
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
 
    methods(TestClassSetup)
        
        function prepare_shapes(obj)
            
            [directory, ~, ~] = fileparts(mfilename('fullpath'));
            parts = split(directory, filesep);
            directory = join(parts(1:end-1), filesep);
            directory = directory{1};
            obj.polygons_path = fullfile(directory, '+utilities', 'polygonshapes', 'polygonshapes.shp');
        end
    end
 
    methods(TestClassTeardown)
    end
 
    methods(Test)
        
        function test_feature_geometry_from_shapefile(obj)
            
            geometry = hdng.geometry.FeatureGeometry.load(obj.polygons_path);
            collection = geometry.collection;
            crs = geometry.crs;
            
            crs_type = crs.type;
            
            switch crs_type
                case hdng.SpatialCRS.GEOGRAPHIC_TYPE
                case hdng.SpatialCRS.GEOCENTRIC_TYPE
                case hdng.SpatialCRS.PROJECTED_TYPE
                    
                case hdng.SpatialCRS.UNKNOWN_TYPE
            end
            
            if crs.is_projected
            end
            
            collection.handle_with(obj);
        end
    end
    
    methods
        
        function result = handle_points(~, points) %#ok<INUSD>
            result = [];
        end

        function result = handle_polylines(~, polylines) %#ok<INUSD>
            result = [];
        end

        function result = handle_polygons(~, polygons)
            result = [];
            
            N_shapes = polygons.N_elements;
            
            for i=1:N_shapes
                polygon = polygons.nth_element(i); %#ok<NASGU>
            end
        end
        
    end
end
