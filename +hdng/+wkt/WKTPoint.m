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

classdef WKTPoint < hdng.wkt.Primitive
    %WKTPoint Summary of this class goes here
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
    end
    
    methods
        
        function obj = WKTPoint(x, y, z, m)
            
            obj = obj@hdng.wkt.Primitive();
            
            if ~isnumeric(x) || isnan(x)
                error('Expected numeric value for x.');
            end
            
            if ~isnumeric(y) || isnan(y)
                error('Expected numeric value for y.');
            end
            
            if ~isnumeric(z) && ~isnan(z) && ~isempty(z)
                error('Expected numeric, NaN or [] for z.');
            end
            
            if ~isnumeric(m) && ~isnan(m) && ~isempty(m)
                error('Expected numeric, NaN or [] for m.');
            end
            
            if isempty(z)
                z = NaN;
            end
            
            if isempty(m)
                m = NaN;
            end
            
            obj.coordinates_ = [x, y, z, m];
        end
        
        function result = get.x(obj)
            result = obj.coordinates_(1);
        end
        
        function result = get.y(obj)
            result = obj.coordinates_(2);
        end
        
        function result = get.z(obj)
            result = obj.coordinates_(3);
        end
        
        function result = get.m(obj)
            result = obj.coordinates_(4);
        end
        
        function result = get.has_z(obj)
            result = ~isnan(obj.coordinates_(3));
        end
        
        function result = get.has_m(obj)
            result = ~isnan(obj.coordinates_(4));
        end
    end
    
    methods (Access = protected)
        
        function result = access_N_points(~)
            result = 1;
        end
    end
    
    methods (Static)
        function result = select_handler_method(handler)
            result = @(primitive) handler.handle_points(primitive);
        end
    end
end
