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

function result = select_by_surfaces(spatial_data, surfaces)
    
    if ~isa(surfaces, 'hdng.geometry.Collection')
        error('select_by_surfaces(): Expected a geometry collection for the surfaces argument.');
    end
    
    superClasses = surfaces.element_type.SuperclassList;
    has_surface_elements = false;
    
    for j=1:numel(superClasses)
        sc = superClasses(j);

        if strcmp(sc.Name, 'hdng.geometry.Surface')
            has_surface_elements = true;
            break;
        end
    end
    
    if ~has_surface_elements
        error('select_by_surfaces(): Expected elements of surfaces collection to be surfaces.');
    end
    
    N_surfaces = surfaces.N_elements;
    selector = zeros(spatial_data.N, 1, 'logical');
    
    for i=1:spatial_data.N
        
        x = spatial_data.x(i);
        y = spatial_data.y(i);
        
        p = hdng.geometry.Point.define(x, y);
        
        keep_point = false;
        
        for j=1:N_surfaces
            surface = surfaces.nth_element(j);
            if surface.contains(p)
                keep_point = true;
                break
            end
        end
        
        selector(i) = keep_point;
    end
    
    result = spatial_data.select(selector);
end
