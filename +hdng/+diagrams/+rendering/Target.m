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

classdef Target < handle
    %Target Summary.
    %   Detailed description 
    
    properties
        position
    end

    properties (Dependent, Transient)
        binary
        text
    end
    
    properties (SetAccess=private)
    end

    methods
        
        function set.binary(obj, value)
            obj.write_bytes(value);
        end
        
        function set.text(obj, value)
            obj.write_text(value);
        end

        function obj = Target(varargin)

            %options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            obj.position = 'start';
        end

        function seek_start(obj)
            obj.position = 'start';
        end

        function seek_end(obj)
            obj.position = 'end';
        end
        
        function write_bytes(obj, output) %#ok<INUSD>
        end

        function write_text(obj, output) %#ok<INUSD>
        end

        function finalise(obj, delegate, context) %#ok<INUSD>
        end
    end
end
