% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2022,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef RasterTest < matlab.unittest.TestCase
 
    properties
        directory
        output_directory
        expected_directory
    end
 
    methods(TestClassSetup)
        
        function initialise(obj)
            [obj.directory, ~, ~] = fileparts(mfilename('fullpath'));
            obj.output_directory = fullfile(obj.directory, 'output');
            obj.expected_directory = fullfile(obj.directory, 'expected');
        end
        
    end
 
    methods(TestClassTeardown)
    end
 
    methods
    end
    
    methods(Test)
        
        function test_raster_context_1(obj)

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
            
            output_image = fullfile(obj.output_directory, 'test_1');
            expected_image = fullfile(obj.expected_directory, 'test_1_001.png');
            
            %{
            ctx.save_canvas_as_png([dest_path '1'], '', [1 0 0]);
            ctx.save_canvas_as_png([dest_path '2'], '', [0 1 0]);
            ctx.save_canvas_as_png([dest_path '3'], '', [0 0 1]);
            %}
            
            ctx.save_canvas_as_png(output_image);
            
            output_image = [output_image '_001.png'];
            
            [I_test, ~, alpha_test] = imread(output_image);
            [I_expected, ~, alpha_expected] = imread(expected_image);
            
            obj.verifyEqual(I_test, I_expected, 'Image RGB data does not match pre-rendered version.');
            obj.verifyEqual(alpha_test, alpha_expected, 'Image alpha data does not match pre-rendered version.');
        end
            
    end
end
