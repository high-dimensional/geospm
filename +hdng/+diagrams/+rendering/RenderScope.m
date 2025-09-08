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

classdef RenderScope < handle
    %RenderScope Summary.
    %   Detailed description 
    
    properties
        name
        renderer
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = RenderScope(varargin)

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'name')
                options.name = '';
            end

            if ~isfield(options, 'renderer')
                options.renderer = [];
            end

            obj.name = options.name;
            obj.renderer = options.renderer;
        end

        function enter(obj, context) %#ok<INUSD>
        end
        
        function exit(obj, context) %#ok<INUSD>
        end
    end
end
