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

classdef BufferedTarget < hdng.diagrams.rendering.Target
    %BufferedTarget Summary.
    %   Detailed description 
    
    properties
    end

    properties (Dependent, Transient)
    end

    properties (SetAccess=private)
        bytes
        encoding
    end

    methods
        
        function obj = BufferedTarget(varargin)
            obj = obj@hdng.diagrams.rendering.Target(varargin{:});

            %options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            obj.bytes = [];
            obj.encoding = "UTF-8";
        end
        
        function write_bytes(obj, output)
            obj.bytes = [obj.bytes; output(:)];
        end
        
        function write_text(obj, output)
            output_bytes = unicode2native(output, obj.encoding);
            obj.write_bytes(output_bytes);
        end

        function finalise(obj, target, context) %#ok<INUSD>
            target.write_bytes(obj.bytes);
        end
    end
end
