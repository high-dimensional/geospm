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

classdef Configuration < handle
    %Configuration Summary.  
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Configuration(varargin)
             %options = hdng.utilities.parse_struct_from_varargin(varargin{:});
        end

        function result = format_inline_css(obj, attribute)
            style = obj.(attribute);

            if isempty(style)
                result = '';
                return;
            end

            style_dict = style.format_css_dictionary('px');
            result = hdng.diagrams.utilities.format_css_attributes(style_dict);
        end
    end
end
