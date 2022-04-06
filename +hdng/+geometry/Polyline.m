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

classdef Polyline < hdng.geometry.Curve
    %Polyline Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = Polyline()
            obj = obj@hdng.geometry.Curve();
        end
        
        function result = contains(obj, primitive) %#ok<INUSD>
            result = false;
        end
        
        function result = as_point_collection(~) %#ok<STOUT>
            error('as_point_collection() must be implemented by a subclass.');
        end
    end
    
    methods (Static)
        
        function result = select_handler_method(handler)
            result = @(primitive) handler.handle_polylines(primitive);
        end
        
        function result = define(vertices, is_simple)
            
            if ~exist('is_simple', 'var')
                is_simple = false;
            end
            
            result = hdng.geometry.impl.PolylineImpl(vertices, is_simple);
        end
        
        function result = define_collection(vertices, offsets, is_simple, offsets_base)

            if ~exist('is_simple', 'var')
                is_simple = [];
            end
            
            if ~exist('offsets_base', 'var')
                offsets_base = 0;
            end
            
            function polyline = generate_polyline(index, vertices, offsets, is_simple, offsets_base)
                
                N_vertices = vertices.N_vertices;
                N_offsets = offsets.N_strides;

                if index < N_offsets
                    limit = offsets.nth_stride(index + 1) - offsets_base;
                else
                    limit = N_vertices + 1;
                end

                if isempty(is_simple)
                    s = false;
                elseif ~isa(is_simple, 'hdng.geometry.Buffer')
                    s = is_simple ~= 0;
                else
                    s = is_simple.nth_stride(is_simple, index);
                end
                
                start = offsets.nth_stride(index) - offsets_base;
                polyline = hdng.geometry.Polyline.define(Vertices.slice(vertices, start, limit), s);
            end

            result = hdng.geometry.Collection.define('hdng.geometry.Polyline', offsets.N_strides, vertices, {offsets, is_simple, offsets_base}, @generate_polyline);
        end
    end
    
    
    methods (Access = protected)
    end
    
end
