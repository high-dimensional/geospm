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

classdef Renderer < handle

    %Renderer Summary.
    %   Detailed description 
    
    properties
        resource_manager
    end

    properties (Dependent, Transient)
    end

    properties (GetAccess=private, SetAccess=private)
    end

    methods
        
        function obj = Renderer(varargin)

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'resource_manager')
                options.resource_manager = hdng.resources.ResourceManager();
            end

            obj.resource_manager = options.resource_manager;
        end
        
        %{
        function result = create_context_for(obj, stack, callback, render_options)
            result = render_options;
            result.callback = callback;
            result.stack = stack;

            result.host_name = obj.resource_manager.host_name;
            result.resource_identifier_expr = obj.resource_manager.resource_identifier_expr;
        end
        %}

        function render_shared_resources(obj, resources, context, varargin) %#ok<INUSD>
        end

        function render_image(obj, image, context, varargin) %#ok<INUSD>
        end
        
        function begin_rect(obj, x1, x2, y1, y2, context, varargin) %#ok<INUSD>
        end

        function end_rect(obj, context) %#ok<INUSD>
        end

        function render_rect(obj, x1, x2, y1, y2, context, varargin) %#ok<INUSD>
        end
        
        function begin_line(obj, x1, x2, y1, y2, context, varargin) %#ok<INUSD>
        end

        function end_line(obj, context) %#ok<INUSD>
        end
        
        function render_line(obj, x1, x2, y1, y2, context, varargin) %#ok<INUSD>
        end
        
        function begin_circle(obj, cx, cy, r, context, varargin) %#ok<INUSD>
        end

        function end_circle(obj, context) %#ok<INUSD>
        end

        function render_circle(obj, cx, cy, r, context, varargin) %#ok<INUSD>
        end
        
        function begin_text(obj, x, y, x_is_increment, y_is_increment, text, context, varargin) %#ok<INUSD>
        end

        function end_text(obj, context) %#ok<INUSD>
        end

        function render_text(obj, x, y, x_is_increment, y_is_increment, text, context, varargin) %#ok<INUSD>
        end
        
        function lines = layout_text(~, text, style, max_width, alignment)
            
            if ~exist('style', 'var') || isempty(style)
                style = hdng.typesetting.Style();
                style.font_family = 'Barlow';
                style.font_size = 10;
            end

            if ~exist('max_width', 'var') || isempty(max_width)
                max_width = Inf;
            end

            if ~exist('alignment', 'var') || isempty(alignment)
                alignment = 'start';
            end
            
            t = hdng.typesetting.Typesetter();
            t.units = 'pixels';
            
            tokens = struct('text', {text}, 'style', {style});
            lines = t.layout(tokens, max_width, alignment);
        end
        
        function begin_group(obj, x, y, context, varargin) %#ok<INUSD>
        end

        function end_group(obj, x, y, context, varargin) %#ok<INUSD>
        end

        function define_linear_gradient(obj, id, stops, transform, context) %#ok<INUSD>
            % stops is a struct array with fields offset and colour
        end

        function render_style_definitions(obj, style_definitions, context, varargin) %#ok<INUSD>
        end
        
        function result = create_target_proxy(obj) %#ok<MANU>
            result = hdng.diagrams.rendering.TargetProxy();
        end
    end
    
end
