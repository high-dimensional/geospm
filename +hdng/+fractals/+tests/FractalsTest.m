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

classdef FractalsTest < matlab.unittest.TestCase
 
    properties
        test_figure
    end
 
    methods(TestClassSetup)
        
        function initialise(obj)
            obj.test_figure = figure;
        end
        
    end
 
    methods(TestClassTeardown)
        
        
        function teardown(obj)
            close(obj.test_figure);
        end
        
    end
 
    methods
    end
    
    methods(Test)
        
        function test_koch_curve(~)
            hdng.fractals.Fractals.KochCurve.show(struct('levels', 5));
        end
        
        function test_koch_snowflake(~)
            hdng.fractals.Fractals.KochSnowflake.show(struct('levels', 5));
        end
        
        function test_koch_antisnowflake(~)
            hdng.fractals.Fractals.KochAntisnowflake.show(struct('levels', 5));
        end
        
        function test_gosper_curve(~)
            hdng.fractals.Fractals.GosperCurve.show(struct('levels', 5));
        end
        
        function test_christmas_tree(~)
            hdng.fractals.Fractals.ChristmasTree.show(struct('levels', 5));
        end
        
        function test_ventrella_root_4(~)
            hdng.fractals.Fractals.VentrellaRoot4.show(struct('levels', 7));
        end
        
        function test_serpinski_arrowhead_curve(~)
            hdng.fractals.Fractals.SerpinskiArrowheadCurve.show(struct('levels', 7));
        end
        
        function test_quartet(~)
            hdng.fractals.Fractals.Quartet.show(struct('levels', 5));
        end
        
        function test_ventrella_root_7(~)
            hdng.fractals.Fractals.VentrellaRoot7.show(struct('levels', 5));
        end
        
        function test_ventrella_root_8(~)
            hdng.fractals.Fractals.VentrellaRoot8.show(struct('levels', 5));
        end
        
        function test_snowflake_sweep(~)
            hdng.fractals.Fractals.SnowflakeSweep.show(struct('levels', 5));
        end
        
        function test_unravelled_carpet(~)
            hdng.fractals.Fractals.UnravelledCarpet.show(struct('levels', 5));
        end
        
        function test_ventrella_root_13(~)
            hdng.fractals.Fractals.VentrellaRoot13.show(struct('levels', 4));
        end
        
        function test_ventrella_root_16(~)
            hdng.fractals.Fractals.VentrellaRoot16.show(struct('levels', 3));
        end
        
        function test_eps_export(~)
            
            [directory, ~, ~] = fileparts(mfilename('fullpath'));
            
            graphic = hdng.fractals.Fractals.KochAntisnowflake.generate(struct('levels', 4));
            graphic.write_as_eps(fullfile(directory, 'koch_antisnowflake_4.eps'));
        end
    end
end
