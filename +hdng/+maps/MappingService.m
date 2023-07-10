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

classdef MappingService < handle
    %MAPPINGSERVICE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function obj = MappingService()
            
        end
        
        function generate(obj, crs, min_location, max_location, spatial_resolution) %#ok<INUSD> 
            error('MappingService.generate() must be implemented by a subclass');
        end        
    end

    methods (Static, Access=public)
        
        function service = lookup(identifier)
            if ~strcmp(identifier, 'default')
                error(['MappingService.lookup(): Unknown mapping service: ' identifier]);
            end
            
            global default_service; %#ok<GVMIS> 

            if isempty(default_service)
                default_service = hdng.maps.PrerenderedMap();
            end
            
            service = default_service;
        end
    end
end
