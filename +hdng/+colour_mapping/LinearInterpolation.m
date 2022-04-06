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

classdef LinearInterpolation < hdng.colour_mapping.ColourInterpolation
    %LinearInterpolation Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = LinearInterpolation()
            obj = obj@hdng.colour_mapping.ColourInterpolation();
        end
        
        function result = with_colours(~, colours)
            result = hdng.colour_mapping.LinearInterpolation();
            result.colours = colours;
        end
        
        function [r, g, b, a] = apply_segment(obj, segment_index, scalar_field)
            
            reversed = 1.0 - scalar_field;
            
            colour1 = obj.colours{segment_index};
            colour2 = obj.colours{segment_index + 1};
            
            r = colour1(1) .* reversed + colour2(1) .* scalar_field;
            g = colour1(2) .* reversed + colour2(2) .* scalar_field;
            b = colour1(3) .* reversed + colour2(3) .* scalar_field;
            a = colour1(4) .* reversed + colour2(4) .* scalar_field;
        end
        
    end
end
