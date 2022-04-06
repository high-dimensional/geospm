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

%%#ok<*CPROPLC>

classdef TransformSequence < handle
    %TransformSequence Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        length
    end
    
    methods
        
        function obj = TransformSequence()
            obj.length = 0;
        end
        
        function allocate(obj, length) %#ok<INUSD>
            error('TransformSequence.allocate() must be implemented by a subclass.');
        end
        
        function copy = truncate(obj, length) %#ok<STOUT,INUSD>
            error('TransformSequence.truncate() must be implemented by a subclass.');
        end
        
        function result = get_transform(obj, index) %#ok<STOUT,INUSD>
            error('TransformSequence.get_transform() must be implemented by a subclass.');
        end
        
        function set_transform(obj, index) %#ok<INUSD>
            error('Sequence.set_transform() must be implemented by a subclass.');
        end
    end
end
