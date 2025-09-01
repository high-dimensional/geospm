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

classdef Shape < hdng.diagrams.features.Geometry
    %Shape Summary.  
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Shape(varargin)
             obj@hdng.diagrams.features.Geometry(varargin{:});
        end


        function next_child = render(obj, n_visit, render_context, base, parents, siblings)
            next_child = render@hdng.diagrams.features.Geometry(obj, n_visit, ...
                render_context, base, parents, siblings);
            
            if n_visit == 1
            
                render_options = obj.define_render_options();
                render_options = hdng.utilities.struct_to_name_value_sequence(render_options);
                
                
                names = obj.feature_declarator.value_names_for_shape(obj.values_by_identifier.shape);
    
                values = cell(numel(names), 1);
    
                for index=1:numel(names)
                    name = names{index};
                    values{index} = obj.values_by_identifier.(name);
                end 
    
                shape_method = ['begin_' obj.values_by_identifier.shape];
                
                render_context.renderer.(shape_method)(...
                    values{:}, ...
                    render_context, ...
                    render_options{:} ...
                );
            end
            
            if obj.is_last_visit(n_visit)
                shape_method = ['end_' obj.values_by_identifier.shape];
                
                render_context.renderer.(shape_method)(...
                    render_context ...
                );
            end
        end
    end
end
