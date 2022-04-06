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

classdef WKTDatum < handle
    %WKTDatum Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name
        spheroid
        towgs84
        authority
    end
    
    methods
        
        function obj = WKTDatum()
            
            obj.name = '';
            obj.spheroid = hdng.wkt.WKTSpheroid.empty;
            obj.towgs84 = hdng.wkt.WKTWGS84Transformation.empty;
            obj.authority = hdng.wkt.WKTAuthority.empty;
        end
        
        function set.name(obj, value)
            
            if ~ischar(value)
                error('Expected char array value for ''name'' attribute.');
            end
            
            obj.name = value;
        end
        
        function set.spheroid(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTSpheroid')
                error('Expected WKTSpheroid value for ''spheroid'' attribute.');
            end
            
            obj.spheroid = value;
        end
        
        function set.towgs84(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTWGS84Transformation')
                error('Expected WKTWGS84Transformation value for ''towgs84'' attribute.');
            end
            
            obj.towgs84 = value;
        end
        
        function set.authority(obj, value)
            
            if ~isa(value, 'hdng.wkt.WKTAuthority')
                error('Expected WKTAuthority value for ''authority'' attribute.');
            end
            
            obj.authority = value;
        end
    end
end
