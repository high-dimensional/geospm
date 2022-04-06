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

function [result_x, result_y] = fit_points(x, y, fit_mode, raster_size, arguments)

    %fit_points Fits points to the given dimensions of a raster.
    %
    %   x
    %       x coordinates of the polygon
    %
    %   y
    %       y coordinates of the polygon
    %
    %   fit_mode
    %
    %       'contain' Scales the point coordinates uniformly to fit inside
    %                 the specified raster size
    %
    %       'at'      Scales and translates the point coordinates
    %                 relative to the raster size. Specify additional
    %                 arguments 'centre' and 'scale', both in units of
    %                 the raster size, to define the transformation.
    %
    %   raster_size
    %
    %       the x and y size of the raster
    %
    %   arguments
    %       
    %       additional arguments required by the specified fit mode
    %
    
    points = [x y];

    bounds_min = min(points);
    bounds_max = max(points);

    switch lower(fit_mode)
        case 'contain'

            aligned_points = points - bounds_min;
            bounds_max = bounds_max - bounds_min;

            nonuniform_scale = raster_size ./ bounds_max;
            uniform_scale = min(nonuniform_scale);
            aligned_points = uniform_scale * aligned_points;

            extra = 0.5 * raster_size - 0.5 * uniform_scale * bounds_max;
            result = aligned_points + extra;

        case 'at'

            if ~isfield(arguments, 'centre')
                arguments.centre = [0.5 0.5];
            end

            if ~isfield(arguments, 'scale')
                arguments.scale = [1 1];
            end

            aligned_points = points - bounds_min;
            bounds_max = bounds_max - bounds_min;
            
            nonuniform_scale = (raster_size ./ bounds_max) .* arguments.scale;
            uniform_scale = nonuniform_scale(1);
            uniform_scale = min(nonuniform_scale);
            aligned_points = uniform_scale * aligned_points;
            
            extra = arguments.centre .* raster_size - 0.5 * uniform_scale * bounds_max;
            result = aligned_points + extra;
            
        otherwise
            result = points;
    end

   result_x = result(:,1);
   result_y = result(:,2);
end
