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

classdef ConstantEffect < hdng.rasters.RasterEffect
    %ConstantEffect Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        value
    end
    
    properties (Transient, Dependent)
    end
    
    methods
        
        function obj = ConstantEffect(value)
            obj = obj@hdng.rasters.RasterEffect();
            
            if ~exist('value', 'var')
                value = ones(1, 3);
            end
            
            obj.value = value;
        end
        
        function canvas = apply(obj, canvas, channels, selector)
        
            for c=1:channels
                channel = canvas(:,:,c);
                channel(selector) = obj.value(c);
                canvas(:,:,c) = channel;
            end
        end
    end
end
