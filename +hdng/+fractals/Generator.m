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

classdef Generator < matlab.mixin.Copyable
    %Generator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
    end
    
    methods
        
        function obj = Generator()
        end
        
        function state = render(obj, fractal, arguments) %#ok<STOUT,INUSD>
            error('Generator.render() must be implemented by a subclass.');
        end
    end
end
