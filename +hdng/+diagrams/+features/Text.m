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

classdef Text < hdng.diagrams.features.Geometry
    %Text Summary.  
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Text(varargin)
             obj@hdng.diagrams.features.Geometry(varargin{:});
        end


        function next_child = render(obj, n_visit, render_context, base, parents, siblings)
            next_child = render@hdng.diagrams.features.Geometry(obj, n_visit, ...
                render_context, base, parents, siblings);
            
            if n_visit ~= 1
                return;
            end
            
            render_options = obj.define_render_options();
            render_options = hdng.utilities.struct_to_name_value_sequence(render_options);
            
            render_context.renderer.render_text(...
                obj.values_by_identifier.text_x, ...
                obj.values_by_identifier.text_y, ...
                obj.values_by_identifier.text_x_is_increment, ...
                obj.values_by_identifier.text_y_is_increment, ...
                obj.values_by_identifier.text, ...
                render_context, ...
                render_options{:} ...
            );
        end
    end
end
