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

classdef GeocentricCoordinateSystem < hdng.wkt.WKTCoordinateSystem
    %GEOCENTRICCOORDINATESYSTEM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        datum
        prime_meridian
        linear_unit
        x_axis
        y_axis
        z_axis
    end
    
    methods
        
        function obj = GeocentricCoordinateSystem()
            
            obj@hdng.wkt.WKTCoordinateSystem();
            obj.datum = hdng.wkt.WKTDatum.emtpy;
            obj.prime_meridian = hdng.wkt.WKTPrimeMeridian.empty;
            obj.linear_unit = hdng.wkt.WKTUnit.empty;
            obj.x_axis = hdng.wkt.WKTAxis('X', hdng.wkt.WKTBearing.OTHER);
            obj.y_axis = hdng.wkt.WKTAxis('Y', hdng.wkt.WKTBearing.EAST);
            obj.z_axis = hdng.wkt.WKTAxis('Z', hdng.wkt.WKTBearing.NORTH);
        end
         
        function set.datum(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTDatum')
                error('Expected WKTDatum value for ''datum'' attribute.');
            end
            
            obj.datum = value;
        end
        
        function set.prime_meridian(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTPrimeMeridian')
                error('Expected WKTPrimeMeridian value for ''prime_meridian'' attribute.');
            end
            
            obj.prime_meridian = value;
        end
        
        function set.linear_unit(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTUnit')
                error('Expected WKTUnit value for ''linear_unit'' attribute.');
            end
            
            obj.linear_unit = value;
        end
        
        function set.x_axis(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTAxis')
                error('Expected WKTAxis value for ''x_axis'' attribute.');
            end
            
            obj.x_axis = value;
        end
        
        function set.y_axis(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTAxis')
                error('Expected WKTAxis value for ''y_axis'' attribute.');
            end
            
            obj.y_axis = value;
        end
        
        function set.z_axis(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTAxis')
                error('Expected WKTAxis value for ''z_axis'' attribute.');
            end
            
            obj.z_axis = value;
        end
    end
    
end
