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

function result = create_grid(options)

    %{
        
        Also see geospm.configure_grid_specifier().
    %}

    if ~isfield(options, 'min_location') || isempty(options.min_location)
        error('min_location must be defined and non-empty.');
    end

    if ~isfield(options, 'max_location') || isempty(options.max_location)
        error('max_location must be defined and non-empty.');
    end

    if ~isfield(options, 'cell_marker_alignment')
        error('cell_marker_alignment must be defined.');
    end
    
    if ~isfield(options, 'cell_marker_scale')
        error('cell_marker_scale must be defined.');
    end

    range = options.max_location - options.min_location;

    spatial_resolution = geospm.auxiliary.compute_spatial_resolution(range, options);    

    result = geospm.Grid();

    result.span_frame( ...
        options.min_location, ...
        options.max_location, ...
        spatial_resolution);

    result.cell_marker_alignment = ...
        options.cell_marker_alignment;

    result.cell_marker_scale = ...
        options.cell_marker_scale;
end
