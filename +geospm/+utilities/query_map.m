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

function result = query_map(crs, min_location, max_location, entity, ...
                    service_identifier)
    
    if ~exist('service_identifier', 'var')
        service_identifier = 'default';
    end

    mapping_service = hdng.maps.MappingService.lookup(service_identifier);
    
    result = mapping_service.query( ...
        crs, ...
        min_location, ...
        max_location, ...
        entity);
end
