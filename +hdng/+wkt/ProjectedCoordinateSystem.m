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

classdef ProjectedCoordinateSystem < hdng.wkt.WKTCoordinateSystem
    %PROJECTEDCOORDINATESYSTEM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        geographic_coordinate_system
        projection
        parameters
        linear_unit
        x_axis
        y_axis
    end
    
    methods
        
        function obj = ProjectedCoordinateSystem()
            
            obj@hdng.wkt.WKTCoordinateSystem();
            obj.geographic_coordinate_system = hdng.wkt.GeographicCoordinateSystem.empty;
            obj.projection = hdng.wkt.WKTProjection.empty;
            obj.parameters = cell(0,1);
            obj.linear_unit = hdng.wkt.WKTUnit.empty;
            obj.x_axis = hdng.wkt.WKTAxis('X', hdng.wkt.WKTBearing.EAST);
            obj.y_axis = hdng.wkt.WKTAxis('Y', hdng.wkt.WKTBearing.NORTH);
        end
        
        function set.projection(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTProjection')
                error('Expected WKTProjection value for ''projection'' attribute.');
            end
            
            obj.projection = value;
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
        
        function add_parameter(obj, parameter)
            
            obj.parameters{end + 1, 1} = parameter;
        end
    end
end
