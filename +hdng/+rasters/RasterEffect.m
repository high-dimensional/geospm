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

classdef RasterEffect < handle
    %RasterEffect Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    properties (Transient, Dependent)
    end
    
    methods
        
        function obj = RasterEffect()
        end
        
        function result = do_apply(~)
            result = true;
        end
        
        function canvas = apply(obj, canvas, channels, selector) %#ok<INUSD>
            error('RasterEffect.apply() must be implemented by a subclass.');
        end
    end
end
