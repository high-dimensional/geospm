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

function test_raster_context()

    %{
    fractal = hdng.fractals.Fractals.KochSnowflake;
    
    fractal_parameters = struct('levels', 4);
    fractal_attributes = struct('raster_fit_mode', 'at', ...
                   'centre', [0.5 0.5], ...
                   'scale', 0.7);
    %}
    
    ctx = hdng.rasters.RasterContext([600 400 3]);

    ctx.save();
    
    %{
    ctx.begin_mask();
    
    r = fractal.generate(fractal_parameters);

    fractal_attributes.raster_width  = 300;
    fractal_attributes.raster_height = 300;

    map = r.generate_raster(fractal_attributes);
    
    ctx.end_mask();
    %}
    
    ctx.set_fill([255 255 0]);
    ctx.fill_ellipse(150, 280, 120, 120);
    
    ctx.set_fill([255 0 255]);
    ctx.fill_ellipse(450, 280, 120, 120);
    
    ctx.set_fill([0 255 255]);
    ctx.fill_ellipse(300, 120, 120, 120);
    
    ctx.set_fill(hdng.rasters.NoEffect(), [255 255 255]);
    ctx.fill_ellipse(300, 200, 200, 200);
    
    ctx.set_stroke(10.0, [255, 230, 20]);
    ctx.stroke_ellipse(300, 200, 200, 200);
    
    ctx.restore();
    
    [dest_path, ~, ~] = fileparts(mfilename('fullpath'));
    dest_path = fullfile(dest_path, 'test');
    
    ctx.save_canvas_as_png(dest_path);
end
