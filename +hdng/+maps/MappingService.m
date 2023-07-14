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
    
    properties (Dependent, Transient)
        layers
    end

    methods
        
        function obj = MappingService()
            
        end
        
        function result = get.layers(obj)
            result = obj.access_layers();
        end

        function layer_images = generate(obj, crs, min_location, max_location, ...
                          spatial_resolution, layers) %#ok<STOUT,INUSD> 
            error('MappingService.generate() must be implemented by a subclass');
        end        
    end

    methods (Access=protected)
        function result = access_layers(~) %#ok<STOUT> 
            error('MappingService.access_layers() must be implemented by a subclass.');
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
