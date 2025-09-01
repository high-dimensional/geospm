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

classdef PageScope < hdng.diagrams.rendering.RenderScope
    %PageScope Summary.
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = PageScope(varargin)

            obj@hdng.diagrams.rendering.RenderScope(varargin{:});

            %options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
        end

        function enter(obj, context)
            enter@hdng.diagrams.rendering.RenderScope(obj, context);
        end
        
        function exit(obj, context)
            exit@hdng.diagrams.rendering.RenderScope(obj, context);
        end
    end
end
