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

classdef SimulatedEvaluator < hdng.experiments.Evaluator
    
    %SimulatedEvaluator Encapsulates a method of generating stages in a study.
    %
    
    properties
        results
        configuration_variable
        rng_variable
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
        seed
        rng
        configuration_generator
        rng_generator
    end
    
    methods
        
        function obj = SimulatedEvaluator()
            obj = obj@hdng.experiments.Evaluator();
            obj.results = hdng.experiments.Schedule();
            
            obj.seed = 383917;
            obj.rng = RandStream.create('mt19937ar', 'Seed', obj.seed);
            
            obj.configuration_generator = hdng.experiments.ValueList.from();
            obj.rng_generator = hdng.experiments.ValueList.from(...
                hdng.experiments.Value.from(obj.rng, 'rng', missing, 'builtin.missing'));
            
            obj.configuration_variable = hdng.experiments.Variable(obj.results, 'configuration', obj.configuration_generator, {});
            obj.rng_variable = hdng.experiments.Variable(obj.results, 'rng', obj.rng_generator, {});
        end
        
        function apply(obj, evaluation, options) %#ok<INUSD>
            
            obj.configuration_generator.values = {hdng.experiments.Value.from(evaluation.configuration, 'configuration', missing, 'builtin.missing')};
            
            iterator = obj.results.iterate_configurations();
            
            while true
                
                [is_valid, value] = iterator.next();
                
                if ~is_valid
                    break;
                end
                
                value.values.remove('configuration');
                value.values.remove('rng');
                
                evaluation.results = value.values;
                break;
            end
        end
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
