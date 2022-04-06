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

classdef GeographicCoordinateSystem < hdng.wkt.WKTCoordinateSystem
    %GEOGRAPHICCOORDINATESYSTEM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

        datum
        prime_meridian
        angular_unit
        linear_unit
        lon_axis
        lat_axis
    end
    
    methods
        
        function obj = GeographicCoordinateSystem()
            obj@hdng.wkt.WKTCoordinateSystem();
            obj.datum = hdng.wkt.WKTDatum.empty;
            obj.prime_meridian = hdng.wkt.WKTPrimeMeridian.empty;
            obj.angular_unit = hdng.wkt.WKTUnit.empty;
            obj.linear_unit = hdng.wkt.WKTUnit.empty;
            obj.lon_axis = hdng.wkt.WKTAxis('Lon', hdng.wkt.WKTBearing.EAST);
            obj.lat_axis = hdng.wkt.WKTAxis('Lat', hdng.wkt.WKTBearing.NORTH);
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
        
        function set.angular_unit(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTUnit')
                error('Expected WKTUnit value for ''angular_unit'' attribute.');
            end
            
            obj.angular_unit = value;
        end
        
        function set.linear_unit(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTUnit')
                error('Expected WKTUnit value for ''linear_unit'' attribute.');
            end
            
            obj.linear_unit = value;
        end
        
        
        function set.lon_axis(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTAxis')
                error('Expected WKTAxis value for ''lon_axis'' attribute.');
            end
            
            obj.lon_axis = value;
        end
        
        function set.lat_axis(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTAxis')
                error('Expected WKTAxis value for ''lat_axis'' attribute.');
            end
            
            obj.lat_axis = value;
        end
    end
end
