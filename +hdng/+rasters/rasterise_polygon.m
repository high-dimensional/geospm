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

function raster = rasterise_polygon(x, y, fit_mode, raster_size, arguments)
    
    %rasterise_polygon Rasterize a polygon
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
    %       Additional arguments required by the specified fit mode, plus:
    %
    %       border    Add a uniform border around the raster.
    %
    
    
    [x, y] = hdng.rasters.fit_points(x, y, fit_mode, raster_size, arguments);

    raster = poly2mask(x, y, raster_size(2), raster_size(1));

    if isfield(arguments, 'border')
        
        border = zeros(arguments.border, raster_size(1));
        raster = [border; raster; border];

        border = zeros(raster_size(2) + 2 * arguments.border, ...
                       arguments.border);

        raster = [border, raster, border];
    end
    
    raster = raster(end:-1:1,:);
end
