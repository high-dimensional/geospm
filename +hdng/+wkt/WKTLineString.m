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

classdef WKTLineString < hdng.wkt.Primitive
    %WKTLineString Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Dependent, Transient)
        
        x
        y
        z
        m
        
        has_z
        has_m
    end
    
    properties (GetAccess=private, SetAccess=private)
        coordinates_
        m_
    end
    
    methods
        
        function obj = WKTLineString(coordinates, m)
            
            obj = obj@hdng.wkt.Primitive();
            
            if ~isnumeric(coordinates)
                error('Expected numeric value for coordinates.');
            end
            
            if ~isnumeric(m)
                error('Expected numeric value for m values.');
            end
            
            obj.coordinates_ = coordinates;
            obj.m_ = m;
        end
        
        function result = get.x(obj)
            result = obj.coordinates_(:, 1);
        end
        
        function result = get.y(obj)
            result = obj.coordinates_(:, 2);
        end
        
        function result = get.z(obj)
            if obj.has_z
                result = obj.coordinates_(:, 3);
            else
                result = zeros(obj.N_points, 1);
            end
        end
        
        function result = get.m(obj)
            if obj.has_m
                result = obj.m_;
            else
                result = zeros(obj.N_points, 1);
            end
        end
        
        function result = get.has_z(obj)
            result = size(obj.coordinates_, 2) == 3;
        end
        
        function result = get.has_m(obj)
            result = ~isempty(obj.m_);
        end
    end
    
    methods (Access = protected)
        
        function result = access_N_points(obj)
            result = size(obj.coordinates_, 1);
        end
    end
    
    methods (Static)
        function result = select_handler_method(handler)
            result = @(primitive) handler.handle_polylines(primitive);
        end
    end
end
