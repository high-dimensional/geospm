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

classdef WKTPrimeMeridian < matlab.mixin.Copyable
    %WKTPrimeMeridian Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        name
        longitude
        authority
    end
    
    methods
        
        function obj = WKTPrimeMeridian(name, longitude, authority)
            
            if ~ischar(name)
                error('Expected char array value for ''name'' attribute.');
            end
            
            if ~isnumeric(longitude)
                error('Expected numeric value for ''longitude'' attribute.');
            end
            
            if exist('authority','var')
                if ~isa(authority, 'hdng.wkt.WKTAuthority')
                    error('Expected WKTAuthority value for ''authority'' attribute.');
                end
            else
                authority = hdng.wkt.WKTAuthority.empty;
            end
            
            obj.name = name;
            obj.longitude = longitude;
            obj.authority = authority;
        end
    end
end
