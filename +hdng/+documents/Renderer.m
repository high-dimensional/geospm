% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2020,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef Renderer < handle
    
    %Renderer [Description]
    %
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = Renderer()
        end
    
        function render(obj, node, context)
            render_type = matlab.lang.makeValidName(node.render_type);
            method_name = ['render_' render_type];
            
            try
                obj.(method_name)(node, context);
                
            catch ME
                
                if ~strcmp(ME.identifier, 'MATLAB:noSuchMethodOrField')
                    rethrow(ME);
                end
                
                obj.render_unknown(node, context);
            end
        end
        
        function render_unknown(obj, node, context) %#ok<INUSD>
        end
        
        function render_document(obj, node, context) %#ok<INUSD>
        end
        
        function render_page(obj, node, context) %#ok<INUSD>
        end
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
