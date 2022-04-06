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

function result = collection_from_shapes(shapevector)

    N_shapes = numel(shapevector);

    if N_shapes == 0
        result = [];
    else

        [shapes, parts, coordinates] = hdng.geometry.utilities.disassemble_shapevector(shapevector);

        vertices = hdng.geometry.Vertices.define(coordinates);

        shape_type = shapevector(1).Geometry;

        if strcmpi(shape_type, 'Point')
            result = hdng.geometry.Point.define_collection(vertices);
        elseif strcmpi(shape_type, 'MultiPoint')
        elseif strcmpi(shape_type, 'Line')
            offsets = hdng.geometry.Buffer.define(parts(shapes));
            result = hdng.geometry.Polyline.define_collection(vertices, offsets);
        elseif strcmpi(shape_type, 'Polygon')
            ring_offsets = hdng.geometry.Buffer.define(parts);
            polygon_offsets = hdng.geometry.Buffer.define(shapes);
            result = hdng.geometry.Polygon.define_collection(vertices, ring_offsets, polygon_offsets);
        end
    end
end
