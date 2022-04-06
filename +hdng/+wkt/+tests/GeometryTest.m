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

classdef GeometryTest < matlab.unittest.TestCase
    properties
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
 
    methods(TestClassSetup)
    end
 
    methods(TestClassTeardown)
    end
 
    methods(Test)
        
        function test_point(obj)
            
            text = 'Point (10 30.0)';
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyEmpty(result.errors, 'Parse errors');
            
            text = 'Point empty';
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyEmpty(result.errors, 'Parse errors');
            
        end
        
        function test_linestring(obj)
            
            text = 'LineString zm (10 30.0 20 5, 10 60.0 20 3.3, 5 5 5 0)';
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyEmpty(result.errors, 'Parse errors');
            
            text = 'LineString zm empty';
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyEmpty(result.errors, 'Parse errors');
            
        end
        
        function test_polygon(obj)
            
            text = 'Polygon zm ((10 30.0 20 5, 10 60.0 20 3.3, 5 5 5 0))';
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyEmpty(result.errors, 'Parse errors');
            
            text = 'Polygon zm ((10 30.0 20 5, 10 60.0 20 3.3, 5 5 5 0), (10 30.0 20 5, 10 60.0 20 3.3, 5 5 5 0))';
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyEmpty(result.errors, 'Parse errors');
            
            text = 'Polygon ((10 30.0 20 5, 10 60.0 20 3.3, 5 5 5 0), (10 30.0 20 5, 10 60.0 20 3.3, 5 5 5 0))';
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyNotEmpty(result.errors, 'Expected parse errors');
            
            text = 'Polygon zm empty';
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyEmpty(result.errors, 'Parse errors');
            
        end
        
        function test_multipoint(obj)
            
            text = 'MultiPoint z (10 30.0 12, 5 10 9.2)';
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyEmpty(result.errors, 'Parse errors');
            
            text = 'MultiPoint z EMPTY';
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyEmpty(result.errors, 'Parse errors');
            
        end
        
        function test_multiline(obj)
            
            text = 'MultiLineString ZM((10 30.0 20 5, 10 60.0 20 3.3, 5 5 5 0), (10 30.0 20 5, 10 60.0 20 3.3, 5 5 5 0))';
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyEmpty(result.errors, 'Parse errors');
            
            text = 'multilinestring empTY';
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyEmpty(result.errors, 'Parse errors');
            
        end
        
        function test_multipolygon(obj)
            
            text = 'multipolygon m(((10 30.0 5, 10 60.0  3.3, 5 5  0)), ((10 30.0  5, 10 60.0  3.3, 5 5 0),(10 30.0 5, 10 60.0  3.3, 5 5  0)))';
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyEmpty(result.errors, 'Parse errors');
            
            text = 'multipolygon empTY';
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyEmpty(result.errors, 'Parse errors');
            
        end
        
        function test_geometry_collection(obj)
            
            text = strcat('GEOMETRYCOLLECTION (multipolygon m(((10 30.0 5, 10 60.0  3.3, 5 5  0)), ((10 30.0  5, 10 60.0  3.3, 5 5 0),(10 30.0 5, 10 60.0  3.3, 5 5  0))), ', ...
                    'MultiLineString ZM((10 30.0 20 5, 10 60.0 20 3.3, 5 5 5 0), (10 30.0 20 5, 10 60.0 20 3.3, 5 5 5 0)),', ...
                    'Polygon zm empty)');
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyEmpty(result.errors, 'Parse errors');
            
            text = 'GEOMETRYCOLLECTION empty';
            result = hdng.wkt.WKTGeometryCollection.from_chars(text);
            
            obj.verifyEmpty(result.errors, 'Parse errors');
            
        end
        
    end
    
    methods
        
        
    end
end
