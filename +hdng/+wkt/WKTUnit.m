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

classdef WKTUnit < matlab.mixin.Copyable
    %WKTUnit Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        name
        conversion_factor
        authority
    end
    
    methods
        
        function obj = WKTUnit(name, conversion_factor, authority)
            
            
            if ~ischar(name)
                error('Expected char array value for ''name'' attribute.');
            end
            
            if ~isnumeric(conversion_factor)
                error('Expected numeric value for ''conversion_factor'' attribute.');
            end
            
            if exist('authority','var')
                if ~isa(authority, 'hdng.wkt.WKTAuthority')
                    error('Expected WKTAuthority value for ''authority'' attribute.');
                end
            else
                authority = hdng.wkt.WKTAuthority.empty;
            end
            
            obj.name = name;
            obj.conversion_factor = conversion_factor;
            obj.authority = authority;
        end
    end
end
