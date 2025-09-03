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

classdef SVGBufferedTarget < hdng.diagrams.rendering.Target
    %SVGBufferedTarget Summary.
    %   Detailed description 
    
    properties
    end

    properties (Dependent, Transient)
    end

    properties (SetAccess=private)
        renderer
        part
        text_buffer
        encoding
    end

    methods
        
        function obj = SVGBufferedTarget(varargin)
            obj = obj@hdng.diagrams.rendering.Target(varargin{:});

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'renderer')
                options.renderer = [];
            end

            if ~isfield(options, 'part')
                options.part = '';
            end

            obj.renderer = options.renderer;
            obj.part = options.part;
        
            obj.text_buffer = [];
            obj.encoding = "UTF-8";
        end
        
        function write_bytes(obj, output)
            error('SVGBufferedTarget:WriteBytesUnsupported', 'write_bytes() not supported on SVGBufferedTarget');
        end
        
        function write_text(obj, output)
            obj.text_buffer = [obj.text_buffer, output];
        end

        
        function finalise(obj, target, context)

            if ~isempty(obj.renderer) && ~isempty(obj.part)
                final_text = obj.renderer.format_svg_part(obj.part, obj.text_buffer, context);
                target.write_text(final_text);
            end
        end
    end
end
