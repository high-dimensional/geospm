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

function result = build_slice_shapes(origin, span, resolution, shape_paths, slice_names, source_ref)

    if ~exist('slice_names', 'var')
        slice_names = [];
    end

    if ~exist('source_ref', 'var')
        source_ref = '';
    end


    result = hdng.experiments.SliceShapes();
    result.origin = origin;
    result.span = span;
    result.resolution = resolution;
    result.shape_paths = shape_paths(:);
    result.slice_names = slice_names;
    result.source_ref = source_ref;
end
