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

classdef WKTAxis < matlab.mixin.Copyable
    %WKTAxis Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        name
        bearing
    end
    
    methods
        
        function obj = WKTAxis(name, bearing)
            
            if ~ischar(name)
                error('Expected char array value for ''name'' attribute.');
            end
            
            if ~isa(bearing, 'hdng.wkt.WKTBearing')
                error('Expected WKTBearing value for ''bearing'' attribute.');
            end
            
            obj.name = name;
            obj.bearing = bearing;
        end
    end
end
