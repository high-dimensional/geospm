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

function result = collection_from_wkt_geometry(wkt_geometry)
    
    result = [];

    coordinates = zeros(wkt_geometry.N_points, 3);
    rings = zeros(wkt_geometry.N_points, 1);
    offsets = zeros(wkt_geometry.N_points, 1); 
    %m = zeros(wkt_geometry.N_points, 1);

    element_type = wkt_geometry.element_type;

    if strcmp(element_type, 'hdng.wkt.WKTPoint')

        has_z = wkt_geometry.N_elements > 0;

        for i=1:wkt_geometry.N_elements
            element = wkt_geometry.nth_element(i);
            coordinates(i, 1) = element.x;
            coordinates(i, 2) = element.y;
            coordinates(i, 3) = element.z;
            has_z = has_z && element.has_z;
        end

        if ~has_z
            coordinates = coordinates(:,1:2);
        end

        vertices = hdng.geometry.Vertices.define(coordinates);
        result = hdng.geometry.Point.define_collection(vertices);

    elseif strcmp(element_type, 'hdng.wkt.WKTLineString')

        start = 1;
        has_z = wkt_geometry.N_elements > 0;

        for i=1:wkt_geometry.N_elements
            element = wkt_geometry.nth_element(i);
            last = start + element.N_points - 1;

            offsets(i) = start;

            coordinates(start:last, 1) = element.x;
            coordinates(start:last, 2) = element.y;
            coordinates(start:last, 3) = element.z;

            start = last + 1;
            has_z = has_z && element.has_z;
        end

        if ~has_z
            coordinates = coordinates(:,1:2);
        end

        vertices = hdng.geometry.Vertices.define(coordinates);
        offsets = hdng.geometry.Buffer.define(offsets(1:wkt_geometry.N_elements));

        result = hdng.geometry.Polyline.define_collection(vertices, offsets, false, 0);

    elseif strcmp(element_type, 'hdng.wkt.WKTPolygon')

        N_rings = 0;
        start = 1;
        has_z = wkt_geometry.N_elements > 0;

        for i=1:wkt_geometry.N_elements
            element = wkt_geometry.nth_element(i);

            offsets(i) = start;

            for j=1:element.N_rings
                ring = element.nth_ring(j);
                rings(i + j - 1) = start;

                last = start + ring.N_points - 1;

                coordinates(start:last, 1) = ring.x;
                coordinates(start:last, 2) = ring.y;
                coordinates(start:last, 3) = ring.z;

                start = start + ring.N_points;
                N_rings = N_rings + 1;
                has_z = has_z && ring.has_z;
            end
        end

        if ~has_z
            coordinates = coordinates(:,1:2);
        end

        vertices = hdng.geometry.Vertices.define(coordinates(1:start - 1, :));
        rings = hdng.geometry.Buffer.define(rings(1:N_rings));
        offsets = hdng.geometry.Buffer.define(offsets(1:wkt_geometry.N_elements));

        result = hdng.geometry.Polygon.define_collection(vertices, rings, offsets, 0, 0);
    else
    end

    %{
    elseif strcmp(element_type, 'MULTIPOINT')

        start = 1;

        for i=1:wkt_geometry.N_elements
            element = wkt_geometry.nth_element(i);
            last = start + element.N_points - 1;

            offsets(i) = start;

            coordinates(start:last, 1) = element.x;
            coordinates(start:last, 2) = element.y;
            coordinates(start:last, 3) = element.y;

            start = last + 1;

            for j=1:element.N_rings
                ring = element.nth_ring(j);
                rings(i + j - 1) = start;
                start = start + ring.N_points;
            end
        end

    elseif strcmp(element_type, 'MULTILINESTRING')
    elseif strcmp(element_type, 'MULTIPOLYGON')
    else
    end
    %}
end
