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

classdef ColourLegend < handle
    %ColourLegend Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
        
        colour_map
    end
    
    methods
        
        function obj = ColourLegend(colour_map)
            obj.colour_map  = colour_map;
        end
        
        function result = render_and_save_as(obj, resolution, filename) %#ok<STOUT,INUSD>
            error('ColourLegend.render_and_save_as() must be implemented by a subclass.');
        end
        
        function result = as_json_struct(obj, resolution) %#ok<STOUT,INUSD>
            error('ColourLegend.as_json_struct() must be implemented by a subclass.');
        end
        
        function result = as_html(obj, size) %#ok<STOUT,INUSD>
            error('ColourLegend.as_json_struct() must be implemented by a subclass.');
        end
    end
end
