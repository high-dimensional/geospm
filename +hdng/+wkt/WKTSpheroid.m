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

classdef WKTSpheroid < matlab.mixin.Copyable
    %WKTSpheroid Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        name
        semimajor_axis
        inverse_flattening
        authority
    end
    
    methods
        
        function obj = WKTSpheroid(name, semimajor_axis, ...
                                   inverse_flattening, authority)
            
            if ~ischar(name)
                error('Expected char array value for ''name'' attribute.');
            end
            
            if ~isnumeric(semimajor_axis) && ~ischar(semimajor_axis)
                error('Expected numeric value or char array for ''semimajor_axis'' attribute.');
            end
            
            if ~isnumeric(inverse_flattening) && ~ischar(inverse_flattening)
                error('Expected numeric value or char array for ''inverse_flattening'' attribute.');
            end
            
            if exist('authority','var')
                if ~isa(authority, 'hdng.wkt.WKTAuthority')
                    error('Expected WKTAuthority value for ''authority'' attribute.');
                end
            else
                authority = hdng.wkt.WKTAuthority.empty;
            end
            
            obj.name = name;
            obj.semimajor_axis = semimajor_axis;
            obj.inverse_flattening = inverse_flattening;
            obj.authority = authority;
        end
    end
end
