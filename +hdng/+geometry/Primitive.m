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

classdef Primitive < hdng.geometry.Collection
    %Primitive Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        N_points
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = Primitive()
            obj = obj@hdng.geometry.Collection();
        end
        
        function result = get.N_points(obj)
            result = obj.access_N_points();
        end
        
        function result = nth_point(obj, index)
            result = obj.vertices.nth_vertex_as_point(index);
        end
        
        function result = nth_element(obj, index)
            
            if index ~= 1
                error('nth_element(): index argument is out of bounds.');
            end
            
            result = obj;
        end
        
        function handle_with(obj, handler)
            m = obj.select_handler_method(handler);
            m(obj);
        end
        
        function result = contains(obj, primitive) %#ok<STOUT,INUSD>
            error('contains() must be implemented by a subclass.');
        end
    end
    
    methods (Static)
        
        function result = select_handler_method(handler) %#ok<STOUT,INUSD>
            error('select_handler_method() must be implemented by a subclass.');
        end
        
    end
    
    methods (Access = protected)
        
        function result = access_N_elements(~)
            result = 1;
        end
        
        function result = access_buffers(~)
            result = {};
        end
        
        function result = access_generator(~)
            result = @(index, vertices, buffer) [];
        end
        
        function result = access_N_points(obj)
            result = obj.vertices.N_vertices;
        end
        
    end
    
end
