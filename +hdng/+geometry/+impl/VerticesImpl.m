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

classdef VerticesImpl < hdng.geometry.Vertices
    %VerticesImpl Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
        array_
        stride_
    end
    
    methods
        
        function obj = VerticesImpl(array, stride)
            obj = obj@hdng.geometry.Vertices();
            obj.array_ = array;
            obj.stride_ = stride;
        end
    end
    
    methods (Access = protected)
        
        function result = access_array(obj)
            result = obj.array_;
        end
        
        function result = access_stride(obj)
            result = obj.stride_;
        end
        
        function result = access_size(obj)
            result = size(obj.array_, 1);
        end
        
        function result = access_x(obj)
            result = obj.coordinates(:, 1);
        end
        
        function result = access_y(obj)
            result = obj.coordinates(:, 2);
        end
        
        function result = access_z(obj)
            if obj.has_z
                result = obj.coordinates(:, 3);
            else
                result = zeros(obj.N_vertices, 1);
            end
        end
        
    end
    
end
