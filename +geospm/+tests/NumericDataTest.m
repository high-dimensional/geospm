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

classdef NumericDataTest < matlab.unittest.TestCase
 
    properties
        N
        P
        observations
        variable_names
        labels
        categories

        data
    end

    methods

        function assign_instance(obj)
            obj.data = geospm.NumericData(obj.observations);
            obj.data.set_variable_names(obj.variable_names);
            obj.data.set_labels(obj.labels);
            obj.data.set_categories(obj.categories);
        end

        function initialise_with_options(obj, varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            obj.N = randi(1000);
            
            if isfield(options, 'N') && ~isempty(options.N)
                obj.N = options.N;
            end

            obj.P = randi(1000);
            
            if isfield(options, 'P') && ~isempty(options.P)
                obj.P = options.P;
            end
            
            obj.observations = rand([obj.N, obj.P]);
            
            obj.variable_names = obj.rand_unique_words(obj.P);

            word_list = webread('https://random-word-api.herokuapp.com/word');
            word = word_list{1};

            obj.labels = cell(obj.N, 1);

            for index=1:obj.N
                obj.labels{index} = sprintf('%s-%d', word, index);
            end
            
            K = randi(obj.N);
            obj.categories = cast(randi(K, [obj.N, 1]), 'int64');

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
 
    methods(Static)

        function result = rand_unique_words(N)

            result = cell(1, N);

            name_map = containers.Map('KeyType', 'char', 'ValueType', 'logical');
            result_index = 1;

            while result_index <= numel(result)

                word_list = webread(sprintf('https://random-word-api.herokuapp.com/word?number=%d', N));
                
                for index=1:numel(word_list)
                    
                    word = word_list{index};

                    if isKey(name_map, word)
                        continue
                    end

                    name_map(word) = true;

                    result{result_index} = word;
                    result_index = result_index + 1;

                    if result_index > N
                        break;
                    end
                end
            end
        end

    end
    
    methods(Test)
        
        function test_N(obj)
            [~] = obj.data.N;
        end

        function test_P(obj)
            [~] = obj.data.P;
        end

        function test_observations(obj)
            [~] = obj.data.observations;
        end
        
        function test_N_observations_consistent(obj)
            obj.verifyEqual(obj.data.N, size(obj.observations, 1), 'N and number of observation rows do not agree');
        end

        function test_P_observations_consistent(obj)
            obj.verifyEqual(obj.data.P, size(obj.observations, 2), 'P and number of observation columns do not agree');
        end
        
        function test_ctor(obj)

            obj.verifyEqual(obj.data.N, obj.N, 'N and N attribute do not agree');
            obj.verifyEqual(obj.data.P, obj.P, 'P and P attribute do not agree');

            obj.verifyEqual(obj.data.observations, obj.observations, 'observations ctor argument and observations attribute do not agree');
        end
        
        function test_mean(obj)
            obj.verifyEqual(obj.data.mean, mean(obj.observations), 'The mean row vector does not agree with the computed one.');
        end
        
        function test_median(obj)
            obj.verifyEqual(obj.data.median, median(obj.observations), 'The median row vector does not agree with the computed one.');
        end

        function test_covariance(obj)
            obj.verifyEqual(obj.data.covariance, cov(obj.observations), 'The covariance matrix does not agree with the computed one.');
        end
        
        function test_variable_names(obj)
            obj.verifyEqual(obj.data.variable_names, obj.variable_names, 'The variable names do not agree with the specification.');

            variable_indices = zeros(1, numel(obj.variable_names));

            for index=1:numel(obj.variable_names)
                variable_name = obj.variable_names{index};
                variable_indices(index) = obj.data.index_for_variable_name(variable_name);
            end

            obj.verifyEqual(variable_indices, 1:obj.P, 'The variable name indices retrieved via index_for_variable_name() are not correct.');
        end
        
        function test_label_names(obj)
            obj.verifyEqual(obj.data.labels, obj.labels, 'The labels do not agree with the specification.');
        end
        
        function test_categories(obj)
            obj.verifyEqual(obj.data.categories, obj.categories, 'The categories do not agree with the specification.');
        end

        function test_set_variable_names(obj)
            
            test_names = obj.rand_unique_words(obj.P);

            obj.data.set_variable_names(test_names);

            obj.verifyEqual(obj.data.variable_names, test_names, 'Variable names were not updated correctly.');
            
            variable_indices = zeros(1, obj.P);

            for index=1:obj.P
                variable_name = test_names{index};
                variable_indices(index) = obj.data.index_for_variable_name(variable_name);
            end
            
            obj.verifyEqual(variable_indices, 1:obj.P, 'After updating the variable names, the indices retrieved via index_for_variable_name() are not correct.');

            obj.data.set_variable_names(obj.variable_names);
        end

        %{
        function test_row_attachments(obj)

            selection = cast(randi(2, [obj.N, 1]) - 1, 'logical');
            attachments = obj.data.row_attachments(selection);
            
            obj.verifyTrue(isfield(attachments, 'labels'), 'Row attachments are missing ''labels'' field.');
            obj.verifyTrue(isfield(attachments, 'categories'), 'Row attachments are missing ''categories'' field.');
            
            obj.verifyEqual(attachments.labels, obj.labels(selection), 'Selected label row attachment does not match specification.');
            obj.verifyEqual(attachments.categories, obj.categories(selection), 'Selected categories row attachment does not match specification.');
        end
        
        function test_column_attachments(obj)
            
            selection = cast(randi(2, [1, obj.P]) - 1, 'logical');
            attachments = obj.data.column_attachments(selection);
            
            obj.verifyTrue(isfield(attachments, 'variable_names'), 'Column attachments are missing ''variable_names'' field.');
            obj.verifyEqual(attachments.variable_names, obj.variable_names(selection), 'Selected variable_names column attachment does not match specification.');
        end

        function test_assign_row_attachments(obj)

            test = geospm.tests.NumericDataTest();
            test.initialise_with_options('P', obj.P);
            
            N_previous = test.data.N;
            N_common = min([test.N, obj.N]);
            row_selection = randperm(obj.N, N_common);

            test.data.assign_row_attachments(obj.data, row_selection);

            obj.verifyEqual(test.data.N, N_previous, 'N should not change under assignment.');

            obj.verifyEqual(test.data.labels(1:N_common), obj.labels(row_selection), 'Selected label row attachment does not match specification.');
            obj.verifyEqual(test.data.categories(1:N_common), obj.categories(row_selection), 'Selected categories row attachment does not match specification.');
        end


        function test_assign_column_attachments(obj)

            test = geospm.tests.NumericDataTest();
            test.initialise_with_options('N', obj.N);
            
            P_previous = test.data.P;
            P_common = min([test.P, obj.P]);
            column_selection = randperm(obj.P, P_common);

            test.data.assign_column_attachments(obj.data, column_selection);

            obj.verifyEqual(test.data.P, P_previous, 'P should not change under assignment.');

            obj.verifyEqual(test.data.variable_names(1:P_common), obj.variable_names(column_selection), 'Selected variable names column attachment does not match specification.');
        end
        %}

        function test_select(obj)
            
            p = randi(obj.P);
            column_selection = randperm(obj.P, p);

            n = randi(obj.N);
            row_selection = randperm(obj.N, n);

            result = obj.data.select(row_selection, column_selection);
            
            selection = obj.observations(row_selection, column_selection);

            obj.verifyEqual(result.observations, selection, 'Selected observations do not match specification.');

            obj.verifyEqual(result.labels, obj.labels(row_selection), 'Selected label row attachment does not match specification.');
            obj.verifyEqual(result.categories, obj.categories(row_selection), 'Selected categories row attachment does not match specification.');
            obj.verifyEqual(result.variable_names, obj.variable_names(column_selection), 'Selected variable names column attachment does not match specification.');
        end
        
        function test_concat_variables(obj)
        
            test = geospm.tests.NumericDataTest();
            test.initialise_with_options('N', obj.N);

            insertion_index = randi(test.P + 1);
            
            result = test.data.concat_variables(obj.observations, obj.variable_names, insertion_index);

            concat = [test.observations(:, 1:insertion_index - 1), obj.observations, test.observations(:, insertion_index:end)];
            combined_variable_names = [test.variable_names(1:insertion_index - 1), obj.variable_names, test.variable_names(insertion_index:end)];

            obj.verifyEqual(result.observations, concat, 'Concatenated observations do not match specification.');

            obj.verifyEqual(result.labels, test.data.labels, 'Combined label row attachment does not match specification.');
            obj.verifyEqual(result.categories, test.data.categories, 'Combined categories row attachment does not match specification.');
            obj.verifyEqual(result.variable_names, combined_variable_names, 'Combined variable names column attachment does not match specification.');
        end
    end
end
