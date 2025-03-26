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

classdef GaussianCDFTest < matlab.unittest.TestCase
 
    properties
    end

    methods

        function assign_instance(obj)
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
    
        function result = specify_distribution(~, dimensions, mean, covariance, method)
        
            result = struct();
            
            result.dimensions = dimensions;
            result.mean = mean;
            result.covariance = covariance;
            result.method = method;

        end
        
        function result = evaluate_distribution(~, distribution)
            
            result = geospm.utilities.discretise_gaussian(distribution.dimensions, ...
                distribution.mean, distribution.covariance, distribution.method);

        end

        function delta_mag_histogram = check_mass(obj, distribution, result, delta_mag_histogram)
            
            %{
            span = size(result);
            origin = ones([1, numel(span)]);
            
            locations = (geospm.utilities.cdf_mesh(origin) - 1) .* span;
            
            P = mvncdf(locations, distribution.mean, distribution.covariance);
            P = reshape(P, origin + 1);
            
            expected_mass = geospm.utilities.cdf_mass(P);
            %}


            result_expected = geospm.utilities.discretise_gaussian(distribution.dimensions, ...
                distribution.mean, distribution.covariance, 'cdf');

            expected_mass = sum(result_expected, 'all');
            
            mass = sum(result, 'all');
            
            delta = abs(expected_mass - mass);

            delta_mag = abs(round(log10(delta)));

            delta_mag_histogram(delta_mag) = delta_mag_histogram(delta_mag) + 1;

            obj.verifyLessThanOrEqual( ...
                delta, 1e-5, ...
                'Mass of result is not within [expected mass - 1e-5, expected mass + 1e-5].' );
            
        end

        function check_mean(obj, distribution, result)

            max_value = max(result, [], 'all');        
            locations = find(result == max_value);
            [x, y, z] = ind2sub(size(result), locations);

            mean_location = distribution.mean;

            if numel(mean_location) < 3
                mean_location(end + 1: 3) = ones([1, 3 - numel(mean_location)]);
            end

            % We allow maximum values to be within +/- 1 cells of the
            % specified mean.

            for index=1:size(locations, 1)
                location = [x(index), y(index), z(index)];

                obj.assertTrue(all(location >= mean_location - 1), 'Mean location is below distribution mean along at least one dimension.');
                obj.assertTrue(all(location <= mean_location + 1), 'Mean location is above distribution mean along at least one dimension.');
                
            end
        end
    end
    
    methods(Test)

        function test_2d(obj)
            
            N = 100000;


            delta_mag_histogram = zeros(20, 1);

            dimension_choices = {
                [10, 10];
                [100, 100];
                [150, 50];
                [50, 150];
                [1000, 10];
                [10, 1000];

            };

            variance_choices = {
                diag([1, 1])
            };

            dimension_indices = randi(numel(dimension_choices), [N, 1]);
            variance_indices = randi(numel(variance_choices), [N, 1]);

            distributions = [
                obj.specify_distribution([10, 10], [0, 0], diag([1, 1]), 'matic2');
                obj.specify_distribution([10, 10], [10, 10], diag([1, 1]), 'matic2');
                obj.specify_distribution([10, 10], [10, 0], diag([1, 1]), 'matic2');
                obj.specify_distribution([10, 10], [0, 10], diag([1, 1]), 'matic2')
            ];
            
            for index=1:N
                
                d = dimension_choices{dimension_indices(index)};
                v = variance_choices{variance_indices(index)};

                %m = [rand() * 2 * d(1) - d(1), rand * 2 * d(2) - d(2)];
                
                m = [rand() * d(1), rand() * d(2)];

                d = obj.specify_distribution(d, m, v, 'matic2');
                distributions = [distributions; d]; %#ok<AGROW>
            end
            


            for index=1:numel(distributions)
                d = distributions(index);
                result = obj.evaluate_distribution(d);
    
                delta_mag_histogram = obj.check_mass(d, result, delta_mag_histogram);
                obj.check_mean(d, result);
            end

            figure;
            scatter(-1:-1:-20, delta_mag_histogram);
        end

    end
end
