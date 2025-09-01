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

classdef SVGPseudoTarget < hdng.diagrams.rendering.Target
    %SVGPseudoTarget Summary.
    %   Detailed description 
    
    properties
    end

    properties (Dependent, Transient)
    end

    properties (SetAccess=private)
        renderer
        part
    end

    methods
        
        function obj = SVGPseudoTarget(varargin)

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'renderer')
                options.renderer = [];
            end

            if ~isfield(options, 'part')
                options.part = '';
            end

            obj.renderer = options.renderer;
            obj.part = options.part;
        end
        
        function write_bytes(obj, output)
        end
        
        function write_text(obj, output)
        end

        function finalise(obj, target, context)

            if ~isempty(obj.renderer) && ~isempty(obj.part)
                text = obj.renderer.format_svg_part(obj.part, context);
                target.write_text(text);
            end
        end
    end
end
