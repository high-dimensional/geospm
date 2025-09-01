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

classdef Custom < hdng.diagrams.features.Geometry
    %Custom Summary.  
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Custom(varargin)
             obj@hdng.diagrams.features.Geometry(varargin{:});
        end

        function next_child = render(obj, n_visit, render_context, base, parents, siblings)
            next_child = render@hdng.diagrams.features.Geometry(obj, n_visit, ...
                render_context, base, parents, siblings);
            
            if n_visit ~= 1
                return;
            end
            
            render_options = obj.define_render_options();
            
            if ~isempty(obj.feature_declarator.delegate)
                obj.feature_declarator.delegate(obj, render_context, render_options, base, parents, siblings);
            end
        end
    end
end
