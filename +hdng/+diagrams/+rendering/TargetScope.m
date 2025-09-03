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

classdef TargetScope < hdng.diagrams.rendering.RenderScope
    %TargetScope Summary.
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
        target_proxy
    end

    properties (Access=private)
        saved_target_scope
        style_definitions
        target_proxy_
        save_target_proxy_on_exit_
    end
    
    methods

        function result = get.target_proxy(obj)
            result = obj.access_target_proxy();
        end
        
        function obj = TargetScope(varargin)
            obj@hdng.diagrams.rendering.RenderScope(varargin{:});
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'target_proxy_ctor')
                options.target_proxy_ctor = @(r) r.create_target_proxy();
            end
            
            if ~isfield(options, 'target_proxy')
                options.target_proxy = options.target_proxy_ctor(obj.renderer);
            end

            if ~isfield(options, 'style_definitions')
                options.style_definitions = {};
            end

            if ~isfield(options, 'save_target_proxy_on_exit')
                options.save_target_proxy_on_exit = false;
            end
            
            obj.style_definitions = options.style_definitions;
            obj.target_proxy_ = options.target_proxy;
            obj.save_target_proxy_on_exit_ = options.save_target_proxy_on_exit;
        end

        function enter(obj, context)
            enter@hdng.diagrams.rendering.RenderScope(obj, context);

            obj.saved_target_scope = context.target_scope;
            context.target_scope = obj;
        end
        
        function exit(obj, context)
            
            if ~isempty(obj.style_definitions)
                context.renderer.render_style_definitions(obj.style_definitions, context);
            end
            
            exit@hdng.diagrams.rendering.RenderScope(obj, context);
            
            obj.target_proxy_.finalise([], context);
            
            if obj.save_target_proxy_on_exit_
                context.saved_target_proxies(obj.name) = obj.target_proxy_;
            end
            
            context.target_scope = obj.saved_target_scope;
        end

        function write_bytes(obj, output)
            obj.target_proxy_.write_bytes(output);
        end

        function write_text(obj, output)
            obj.target_proxy_.write_text(output);
        end
    end

    methods (Access=protected)
    
        function result = access_target_proxy(obj)
            result = obj.target_proxy_;
        end
    
    end
end
