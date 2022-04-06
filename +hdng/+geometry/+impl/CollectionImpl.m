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

classdef CollectionImpl < hdng.geometry.Collection
    %CollectionImpl Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (GetAccess = private, SetAccess = private)
        element_type_
        N_elements_
        vertices_
        buffers_
        generator_
    end
    
    methods
        
        function obj = CollectionImpl(element_type, N_elements, vertices, buffers, generator)
            obj = obj@hdng.geometry.Collection();
            obj.element_type_ = element_type;
            obj.N_elements_ = N_elements;
            obj.vertices_ = vertices;
            obj.buffers_ = buffers;
            obj.generator_ = generator;
        end
        
        function result = substitute_vertices(obj, vertices)
            result = hdng.geometry.impl.CollectionImpl(obj.element_type_, ...
                obj.N_elements_, vertices, obj.buffers_, obj.generator_);
        end
        
    end
    
    methods (Access = protected)
        
        function result = access_element_type(obj)
            result = obj.element_type_;
        end
        
        function result = access_N_elements(obj)
            result = obj.N_elements_;
        end
        
        function result = access_vertices(obj)
            result = obj.vertices_;
        end
        
        function result = access_buffers(obj)
            result = obj.buffers_;
        end
        
        function result = access_generator(obj)
            result = obj.generator_;
        end
        
    end
    
end
