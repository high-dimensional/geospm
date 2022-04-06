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

classdef Buffer < handle
    %Buffer Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = immutable)
    end
    
    properties (Dependent, Transient)
        array
        stride
        size
        N_strides
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = Buffer()
        end
        
        function result = get.array(obj)
            result = obj.access_array();
        end
        
        function result = get.stride(obj)
            result = obj.access_stride();
        end
        
        
        function result = get.size(obj)
            result = obj.access_size();
        end
        
        function result = get.N_strides(obj)
            result = floor(obj.size / obj.stride);
        end
        
        function result = nth_stride(obj, index)
            index = (index - 1) * obj.stride + 1;
            result = obj.array(index:index + obj.stride - 1);
        end
        
        function result = slice(obj, start, limit)
            
            if ~exist('limit', 'var')
                limit = obj.size;
            end
            
            
            slice_start_index = (start - 1) * obj.stride + 1;
            slice_limit_index = (limit - 1) * obj.stride + 1;
            slice_array = obj.array(slice_start_index:slice_limit_index - 1, :);
            
            if isa(obj, 'hdng.geometry.Vertices')
                result = hdng.geometry.Vertices.define(slice_array, obj.stride);
            else
                result = hdng.geometry.Buffer.define(slice_array, obj.stride);
            end
        end
        
        
    end
    
    methods (Access = protected)
        
        function result = access_array(~) %#ok<STOUT>
            error('access_array() must be implemented by a subclass.');
        end
        
        function result = access_stride(~) %#ok<STOUT>
            error('access_stride() must be implemented by a subclass.');
        end
        
        function result = access_size(~) %#ok<STOUT>
            error('access_size() must be implemented by a subclass.');
        end
        
    end
    
    methods (Static)
        
        function result = define(array, stride)
            if ~exist('stride', 'var')
                stride = 1;
            end
            
            result = hdng.geometry.impl.BufferImpl(array, stride);
        end
    end
end
