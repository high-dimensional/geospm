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

function result = collection_from_bounding_box_csv(file_path)

    loader = hdng.utilities.CSVLoader();

    loader.define_column('easting_min',  0, true, false);
    loader.define_column('northing_min', 0, true, false);
    loader.define_column('easting_max',  0, true, false);
    loader.define_column('northing_max', 0, true, false);

    [N_rows, bounds, ~] = loader.load_csv(file_path);

    N_vertices = N_rows * 4;

    coordinates = zeros(N_vertices, 2);
    coordinates(1:4:N_vertices, 1) = bounds{1};
    coordinates(1:4:N_vertices, 2) = bounds{2};
    coordinates(2:4:N_vertices, 1) = bounds{3};
    coordinates(2:4:N_vertices, 2) = bounds{2};
    coordinates(3:4:N_vertices, 1) = bounds{3};
    coordinates(3:4:N_vertices, 2) = bounds{4};
    coordinates(4:4:N_vertices, 1) = bounds{1};
    coordinates(4:4:N_vertices, 2) = bounds{4};

    vertices = hdng.geometry.Vertices.define(coordinates);
    ring_offsets = hdng.geometry.Buffer.define(1:4:N_vertices);
    polygon_offsets = hdng.geometry.Buffer.define(1:N_rows);

    result = hdng.geometry.Polygon.define_collection(vertices, ring_offsets, polygon_offsets, 0, 0);

end
