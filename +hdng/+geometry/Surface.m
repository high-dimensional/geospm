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

classdef Surface < hdng.geometry.Primitive
    %Surface Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        area
        centroid
        boundary
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = Surface()
            obj = obj@hdng.geometry.Primitive();
        end
        
        function result = get.area(obj)
            result = obj.access_area();
        end
        
        function result = get.centroid(obj)
            result = obj.access_centroid();
        end
        
        function result = get.boundary(obj)
            result = obj.access_boundary();
        end
    end
    
    methods (Static)
    end
    
    methods (Access = protected)
        
        function result = access_area(~) %#ok<STOUT>
            error('access_area() must be implemented by a subclass.');
        end
        
        function result = access_centroid(~) %#ok<STOUT>
            error('access_centroid() must be implemented by a subclass.');
        end
        
        function result = access_boundary(~) %#ok<STOUT>
            error('access_boundary() must be implemented by a subclass.');
        end
    end
    
end
