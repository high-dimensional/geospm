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

classdef Switch < hdng.diagrams.features.Geometry
    %Switch Summary.  
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Switch(varargin)
             obj@hdng.diagrams.features.Geometry(varargin{:});
        end

        function result = is_last_visit(obj, n_visit)
            n_children = obj.feature_declarator.n_choices > 0;
            result = n_visit == n_children + 1;
        end

        function next_child = render(obj, n_visit, render_context, base, parents, siblings)
            
            render@hdng.diagrams.features.Geometry(obj, n_visit, ...
                render_context, base, parents, siblings);
            
            if n_visit == 1
                
                next_child = obj.children{obj.values_by_identifier.choice};
            else
                next_child = [];
            end
        end
    end
end
