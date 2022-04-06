% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2020,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function result = trace_slices(bw_volume)
    
    [components, N_components] = spm_bwlabel(bw_volume, 18);
    
    N_levels = size(bw_volume, 3);
    
    result = cell(N_levels, 2);
    
    for i=1:N_levels
        
        components_level = components(:,:,i);
        
        level_coords   = [];
        level_rings    = [];
        level_polygons = [];
        
        component_attr = [];
        
        for j=1:N_components
            
            component = components_level == j;
            [coords, rings, polygons] = geospm.volumes.trace_slice(component);
            
            N_component_polygons = size(polygons, 1);
            
            ring_base    = size(level_coords, 1);
            polygon_base = size(level_rings, 1);
            
            level_coords   = [level_coords; coords]; %#ok<AGROW>
            level_rings    = [level_rings; rings + ring_base]; %#ok<AGROW>
            level_polygons = [level_polygons; polygons + polygon_base]; %#ok<AGROW>
            
            %component_attr = [component_attr; j * ones(N_component_polygons, 1)]; %#ok<AGROW>
            
            component_attr = [component_attr; j, N_component_polygons]; %#ok<AGROW>
        end
        
        level_collection = hdng.geometry.Polygon.define_collection(level_coords, level_rings, level_polygons);
    
        result{i, 1} = level_collection;
        result{i, 2} = component_attr;
    end
end
