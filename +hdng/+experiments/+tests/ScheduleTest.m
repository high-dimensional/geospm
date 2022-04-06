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

classdef ScheduleTest < matlab.unittest.TestCase
 
    properties
        schedule
        study
    end
 
    methods(TestMethodSetup)
        
        function initialise(obj)
            
            dataset_url = '/Users/work/UCL/Projects/regra/data/ukb42604_covid.csv';

            obj.schedule = hdng.experiments.Schedule();

            dataset_url = hdng.experiments.Variable(obj.schedule, 'dataset_url', hdng.experiments.ValueList.from(dataset_url));
            variables = hdng.experiments.Variable(obj.schedule, 'variable_names', hdng.experiments.VariableNames.from(), {dataset_url});
            response = hdng.experiments.Variable(obj.schedule, 'response', hdng.experiments.ValueList.from('tested_positive'), {variables}, 'description', 'Response');
            
            combinations = hdng.experiments.NameCombinations.from('exclude_names', {'eid', 'tested_positive'}, 'choose_k', 2, 'variable_names_requirement', 'variable_names');
            max_combinations = hdng.experiments.AtMostValues.from(100, combinations);
            
            predictors = hdng.experiments.Variable(obj.schedule, 'predictors', max_combinations, {variables, response}, 'description', 'Predictors');
            hdng.experiments.Variable(obj.schedule, 'method', hdng.experiments.ValueList.from('bayesreg', 'logreg', 'randomforest', 'xgboost'), {predictors});
            
            % schedule.define_variable("post_processing", as_apply_function(lambda method: Value(method.content, method.label + "_post_processed")), method)
            

            evaluator = hdng.experiments.SimulatedEvaluator();
            
            simulate_curve = @(rng, configuration, arguments) hdng.experiments.Value.from(false);
            compute_curve_auc = @(rng, configuration, arguments) hdng.experiments.Value.from(false);
            
            curve_result = hdng.experiments.Variable(evaluator.results, 'curve', hdng.experiments.SimulatedResult.from(simulate_curve), {evaluator.configuration_variable, evaluator.rng_variable}, 'description', 'Curve');
            hdng.experiments.Variable(evaluator.results, 'auc', hdng.experiments.SimulatedResult.from(compute_curve_auc), {evaluator.configuration_variable, evaluator.rng_variable, curve_result}, 'description', 'Area under Curve');
            
            
            strategy = hdng.experiments.SimpleStrategy();
            strategy.schedule = obj.schedule;
            strategy.evaluator = evaluator;
            
            obj.study = hdng.experiments.Study();
            obj.study.strategy = strategy;
            
        end
        
    end
 
    methods(TestMethodTeardown)
    end
 
    methods        
    end
    
    methods(Test)
        
        function test_study(obj)
            
            datetime_string = hdng.experiments.tests.ScheduleTest.now();
            study_path = sprintf('%s%s%s', pwd, filesep, datetime_string);
            
            obj.study.execute(study_path);
        end
        
    end
    
    methods (Static)
        
        function result = now()
            result = datetime('now', 'TimeZone', 'local', 'Format', 'yyyy_MM_dd_HH_mm_ss');
        end
        
    end
end
