% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2020,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef Curve < hdng.geometry.Primitive
    %Curve Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        start_point
        end_point
        is_simple
        is_closed
        is_ring
        is_line
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = Curve()
            obj = obj@hdng.geometry.Primitive();
        end
        
        function result = get.start_point(obj)
            result = obj.access_start_point();
        end
        
        function result = get.end_point(obj)
            result = obj.access_end_point();
        end
        
        function result = get.is_simple(obj)
            result = obj.access_is_simple();
        end
        
        function result = get.is_closed(obj)
            result = obj.access_is_closed();
        end
        
        function result = get.is_ring(obj)
            result = obj.access_is_ring();
        end
        
        function result = get.is_line(obj)
            result = obj.access_is_line();
        end
    end
    
    methods (Static)
    end
    
    methods (Access = protected)
        
        function result = access_start_point(~) %#ok<STOUT>
            error('access_start_point() must be implemented by a subclass.');
        end
        
        function result = access_end_point(~) %#ok<STOUT>
            error('access_end_point() must be implemented by a subclass.');
        end
        
        function result = access_is_simple(~) %#ok<STOUT>
            error('access_is_simple() must be implemented by a subclass.');
        end
        
        function result = access_is_closed(obj)
            result = isequal(obj.start_point, obj.end_point);
        end
        
        function result = access_is_ring(obj)
            result = obj.is_simple && obj.is_closed;
        end
        
        function result = access_is_line(~)
            result = obj.N_points == 2 && ~obj.is_closed;
        end
        
    end
end
