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

function [image, alpha] = generate_map_image(crs, min_location, max_location, ...
                    resolution, layer, service_identifier)

    if ~exist('layer', 'var')
        layer = 'mask';
    end

    if ~exist('service_identifier', 'var')
        service_identifier = 'default';
    end

    mapping_service = hdng.maps.MappingService.lookup(service_identifier);
    
    [image, alpha] = mapping_service.generate( ...
        crs, ...
        min_location, ...
        max_location, ...
        resolution(1:2), ...
        {layer});
    
    image = image{1};
    alpha = alpha{1};
end
