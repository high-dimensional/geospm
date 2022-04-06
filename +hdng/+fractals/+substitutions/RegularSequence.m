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

%#ok<*CPROPLC>

classdef RegularSequence < hdng.fractals.substitutions.TransformSequence
    %RegularSequence Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        scale_power
        orientation
        flipped
        reversed
    end
    
    methods
        
        function obj = RegularSequence(length)
            
            obj = obj@hdng.fractals.substitutions.TransformSequence();
            
            if ~exist('length', 'var')
                length = 0;
            end
            
            obj.allocate(length);
        end
        
        function obj = allocate(obj, length)
            
            obj.length = length;
            
            obj.scale_power = zeros(obj.length, 1, 'uint8');
            obj.orientation = zeros(obj.length, 1, 'uint8');
            obj.flipped     = zeros(obj.length, 1, 'logical');
            obj.reversed    = zeros(obj.length, 1, 'logical');
        end
        
        function copy = truncate(obj, length)
        
            copy = hdng.fractals.substitutions.RegularSequence();
            
            copy.length = length;
            
            copy.scale_power = obj.scale_power(1:copy.length);
            copy.orientation = obj.orientation(1:copy.length);
            copy.flipped     = obj.flipped(1:copy.length);
            copy.reversed    = obj.reversed(1:copy.length);
        end
        
        function result = get_transform(obj, index)
            
            result = struct(...
                      'generator',   1, ...
                      'scale_power', obj.scale_power(index), ...
                      'orientation', obj.orientation(index), ...
                      'flipped',     obj.flipped(index), ...
                      'reversed',    obj.reversed(index));
        end
        
        function obj = set_transform(obj, index, transform)
            
            obj.scale_power(index) = transform.scale_power;
            obj.orientation(index) = transform.orientation;
            obj.flipped(index)     = transform.flipped;
            obj.reversed(index)    = transform.reversed;
        end
    end
end
