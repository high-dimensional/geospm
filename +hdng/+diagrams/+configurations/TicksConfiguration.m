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

classdef TicksConfiguration < handle
    %TicksConfiguration Summary.  
    %   Detailed description 
    
    properties
        show
        style_class
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = TicksConfiguration(varargin)
             options = hdng.utilities.parse_struct_from_varargin(varargin{:});

             if ~isfield(options, 'show')
                 options.show = true;
             end

             if ~isfield(options, 'style_class')
                 options.style_class = true;
             end

            obj.show = options.show;
            obj.style_class = options.style_class;
        end
    end
end
