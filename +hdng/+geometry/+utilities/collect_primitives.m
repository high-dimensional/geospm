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

function result = collect_primitives(primitives)
    
    types = containers.Map('KeyType', 'char', 'ValueType', 'any');
    N = numel(primitives);
    
    for i=1:N
        
        value = primitives{i};
        
        if ~isKey(types, value.element_type)
            types(value.element_type) = {};
        end

        types(value.element_type) = [types(value.element_type) {value}];
    end
    
    [vertices, offsets] = hdng.geometry.utilities.concat_vertices(primitives);
    
    if types.length == 1
        type_ids = keys(types);
        element_type = type_ids{1};
        
        if strcmp(element_type, 'hdng.geometry.Point')
            result = hdng.geometry.Point.define_collection(vertices);
            return;
            
        elseif strcmp(element_type, 'hdng.geometry.Polyline')
            
            offsets = hdng.geometry.Buffer.define(offsets, 1);
            
            is_simple = zeros(N, 1, 'logical');
            
            for i=1:N
                value = primitives{i};
                is_simple(i) = value.is_simple;
            end
            
            is_simple = hdng.geometry.Buffer.define(is_simple, 1);
            
            result = hdng.geometry.Polyline.define_collection(vertices, offsets, is_simple);
            return;
            
        elseif strcmp(element_type, 'hdng.geometry.Polygon')
            
            
            polygon_offsets = zeros(N, 1, 'int64');
            
            N_rings = 0;
            
            for i=1:N
                value = primitives{i};
                polygon_offsets(i) = 1 + N_rings;
                N_rings = N_rings + value.N_rings;
            end
            
            ring_offsets = zeros(N_rings, 1, 'int64');
            ring_base = 0;
            
            for i=1:N
                value = primitives{i};
                
                for j=1:value.N_rings
                    ring = value.nth_ring(j);
                    ring_offsets(i) = 1 + ring_base;
                    ring_base = ring_base + ring.N_points;
                end
            end
            
            polygon_offsets = hdng.geometry.Buffer.define(polygon_offsets, 1);
            ring_offsets = hdng.geometry.Buffer.define(ring_offsets, 1);
            
            result = hdng.geometry.Polygon.define_collection(vertices, ring_offsets, polygon_offsets);
            return;
        end
        
    else
        element_type = 'hdng.geometry.Primitive';
    end
    
    error(['Unsupported geometry type: ' element_type]);
end
