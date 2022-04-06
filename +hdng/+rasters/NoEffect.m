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

classdef NoEffect < hdng.rasters.RasterEffect
    %NoEffect Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        value
    end
    
    properties (Transient, Dependent)
    end
    
    methods
        
        function obj = NoEffect()
            obj = obj@hdng.rasters.RasterEffect();
        end
        
        function result = do_apply(~)
            result = false;
        end
        
        function canvas = apply(obj, canvas, channels, selector) %#ok<INUSD,INUSL>
        end
    end
end
