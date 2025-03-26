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

classdef DeviationConversionsTest < matlab.unittest.TestCase
 
    properties
        N
        p_values
        diameters
    end

    methods

        function assign_instance(obj)

            obj.N = 10000;

            obj.p_values = [
                0.0625;
                0.125;
                0.25;
                0.5;
                0.75;
                0.875;
                0.9375
            ];

            obj.diameters = [
                0.1;
                1;
                10;
                100;
            ];

        end

        function initialise_with_options(obj, varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            obj.assign_instance();
        end
    end
    
    methods(TestMethodSetup)
        
        function initialise1(obj)
            obj.initialise_with_options();
        end
        
    end
 
    methods(TestMethodTeardown)
    end

    methods
    
    end
    
    methods(Test)

        function test_1d(obj)
            

            for index=1:obj.N
                p = obj.p_values(randi(numel(obj.p_values)));
                d = obj.diameters(randi(numel(obj.diameters)));

                stddev = geospm.utilities.stddev_from_p_diameter(p, d, 1);

                p_test = geospm.utilities.p_from_stddev_diameter(stddev, d, 1);

                obj.verifyLessThanOrEqual( ...
                    abs(p_test - p), 1e-12, ...
                    'Computed p is not within [expected p - 1e-12, exptected p + 1e-12].' );

                d_test = geospm.utilities.diameter_from_p_stddev(p, stddev, 1);

                obj.verifyLessThanOrEqual( ...
                    abs(d_test - d), 1e-12, ...
                    'Computed d is not within [expected d - 1e-12, exptected d + 1e-12].' );

                fwhm = geospm.utilities.fwhm_from_stddev(stddev);
                stddev_test = geospm.utilities.stddev_from_fwhm(fwhm);

                obj.verifyLessThanOrEqual( ...
                    abs(stddev_test - stddev), 1e-12, ...
                    'Computed stddev is not within [expected stddev - 1e-12, exptected stddev + 1e-12].' );
            end
        end

        function test_2d(obj)
            

            for index=1:obj.N
                p = obj.p_values(randi(numel(obj.p_values)));
                d = obj.diameters(randi(numel(obj.diameters)));

                stddev = geospm.utilities.stddev_from_p_diameter(p, d, 2);

                p_test = geospm.utilities.p_from_stddev_diameter(stddev, d, 2);

                obj.verifyLessThanOrEqual( ...
                    abs(p_test - p), 1e-9, ...
                    'Computed p is not within [expected p - 1e-9, exptected p + 1e-9].' );

                d_test = geospm.utilities.diameter_from_p_stddev(p, stddev, 2);

                obj.verifyLessThanOrEqual( ...
                    abs(d_test - d), 1e-9, ...
                    'Computed d is not within [expected d - 1e-9, exptected d + 1e-9].' );

                fwhm = geospm.utilities.fwhm_from_stddev(stddev);
                stddev_test = geospm.utilities.stddev_from_fwhm(fwhm);

                obj.verifyLessThanOrEqual( ...
                    abs(stddev_test - stddev), 1e-12, ...
                    'Computed stddev is not within [expected stddev - 1e-12, exptected stddev + 1e-12].' );
            end
        end

        function test_3d(obj)
            

            for index=1:obj.N
                p = obj.p_values(randi(numel(obj.p_values)));
                d = obj.diameters(randi(numel(obj.diameters)));

                stddev = geospm.utilities.stddev_from_p_diameter(p, d, 3);

                p_test = geospm.utilities.p_from_stddev_diameter(stddev, d, 3);

                obj.verifyLessThanOrEqual( ...
                    abs(p_test - p), 1e-9, ...
                    'Computed p is not within [expected p - 1e-9, exptected p + 1e-9].' );

                d_test = geospm.utilities.diameter_from_p_stddev(p, stddev, 3);

                obj.verifyLessThanOrEqual( ...
                    abs(d_test - d), 1e-9, ...
                    'Computed d is not within [expected d - 1e-9, exptected d + 1e-9].' );

                fwhm = geospm.utilities.fwhm_from_stddev(stddev);
                stddev_test = geospm.utilities.stddev_from_fwhm(fwhm);

                obj.verifyLessThanOrEqual( ...
                    abs(stddev_test - stddev), 1e-12, ...
                    'Computed stddev is not within [expected stddev - 1e-12, exptected stddev + 1e-12].' );
            end
        end
        
    end
end
