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

classdef BinarySearchTest < matlab.unittest.TestCase
 
    properties
        N
        K
        R
    end
 
    methods(TestMethodSetup)
        
        function initialise(obj)
            obj.N = 1000;
            obj.K = 10;
            obj.R = 1;
        end
        
    end
 
    methods(TestMethodTeardown)
    end
 
    methods
        
        function values = create_searchable_numbers(~, N)

            values = randperm(N * 100, N);
        end
        
        function values = create_searchable_numeric_strings(obj, N)

            values = num2cell(obj.create_searchable_numbers(N));

            for i=1:N
                value = values{i};
                value = num2str(value, '%d');
                values{i} = value;
            end
        end
        
        function values = create_searchable_random_strings(~, N)

            values = hdng.utilities.randidentifier(3, 8, N)';
        end
        
        function test_sorted_insertion(obj, values, p)
            
            V = numel(values);
            
            for i=1:V
                test_index = p(i);
                test_values = [values(1:test_index - 1) values(test_index + 1:end)];
                [result_index, insert_at] = hdng.utilities.binary_search(test_values, values{test_index});
                obj.verifyEqual(result_index, 0, sprintf('A value was found at [%d] although it is not contained in the test array.', result_index));
                obj.verifyEqual(insert_at, test_index, sprintf('A value was expected to be inserted at [%d], but instead would be inserted at [%d].', test_index, insert_at));
            end
        end
        
    end
    
    methods(Test)
        
        function search_numeric_strings(obj)
            
            for i=1:obj.N
                
                values = obj.create_searchable_numeric_strings(obj.K);
                values = sort(values);
                
                obj.test_sorted_insertion(values, 1:obj.K);
                obj.test_sorted_insertion(values, obj.K:-1:1);
                
                for j=1:obj.R
                    p = randperm(obj.K);
                    obj.test_sorted_insertion(values, p);
                end
            end
        end
        
        function search_random_strings(obj)
            
            for i=1:obj.N
                
                values = obj.create_searchable_random_strings(obj.K);
                values = sort(values);
                
                obj.test_sorted_insertion(values, 1:obj.K);
                obj.test_sorted_insertion(values, obj.K:-1:1);
                
                for j=1:obj.R
                    p = randperm(obj.K);
                    obj.test_sorted_insertion(values, p);
                end
            end
        end
        
        function search_numbers(obj)
            
            for i=1:obj.N
                
                values = obj.create_searchable_numbers(obj.K);
                values = num2cell(sort(values));
                
                
                obj.test_sorted_insertion(values, 1:obj.K);
                obj.test_sorted_insertion(values, obj.K:-1:1);
                
                for j=1:obj.R
                    p = randperm(obj.K);
                    obj.test_sorted_insertion(values, p);
                end
                
            end
            
        end
    end
end
