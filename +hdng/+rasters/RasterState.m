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

classdef RasterState < handle
    %RasterState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        transform
        mask
        
        fill_1
        fill_2
        
        line_width
        line_stroke
        
        mask_fill_1
        mask_fill_2
        
        blank_mask
        mask_level
        
        channels
    end
    
    properties (Transient, Dependent)
        dimensions
    end
    
    methods
        
        function obj = RasterState(mask, channels)
            
            obj.mask = mask;
            obj.mask_level = 0;
            
            obj.channels = channels;
            
            obj.transform = eye(3);
            obj.fill_1 = hdng.rasters.ConstantEffect();
            obj.fill_2 = hdng.rasters.NoEffect();
            
            obj.mask_fill_1 = hdng.rasters.ConstantEffect();
            obj.mask_fill_2 = hdng.rasters.NoEffect();
            
            obj.line_width = 1.0;
            obj.line_stroke = hdng.rasters.ConstantEffect();
        end
        
        function result = get.dimensions(obj)
            result = size(obj.mask);
        end
        
        function result = copy(obj)
            
            result = hdng.rasters.RasterState(obj.mask, obj.channels);
            
            result.mask_level = 0;
            result.channels = obj.channels;
            result.transform = obj.transform;
            result.fill_1 = obj.fill_1;
            result.fill_2 = obj.fill_2;
            result.mask_fill_1 = obj.mask_fill_1;
            result.mask_fill_2 = obj.mask_fill_2;
            result.line_width = obj.line_width;
            result.line_stroke = obj.line_stroke;
        end
    end
end
