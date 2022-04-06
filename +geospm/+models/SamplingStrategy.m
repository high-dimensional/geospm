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

classdef SamplingStrategy < handle
    %SamplingStrategy Summary
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function obj = SamplingStrategy()
        end
        
        function result = observe(obj, model, N_samples, seed) %#ok<INUSD,STOUT>
        	error('SamplingStrategy.observe() must be implemented by a subclass.');
        end
    end
    
    methods (Static, Access=public)

        function result = create(strategy_type, varargin)
            
            builtins = geospm.models.SamplingStrategy.builtin_sampling_strategies();
            
            if ~isKey(builtins, strategy_type)
                error(['SamplingStrategy.create(): Unknown builtin experiment type: ' strategy_type]);
            end
            
            ctor = builtins(strategy_type);
            result = ctor(varargin{:});
        end
        
        function result = builtin_sampling_strategies()
            
            persistent BUILTIN_SAMPLING_STRATEGIES;
            
            if isempty(BUILTIN_SAMPLING_STRATEGIES)
            
                where = mfilename('fullpath');
                [base_dir, ~, ~] = fileparts(where);
                regions_dir = fullfile(base_dir, '+sampling');

                result = what(regions_dir);
                    
                BUILTIN_SAMPLING_STRATEGIES = containers.Map('KeyType', 'char','ValueType', 'any');
                
                for i=1:numel(result.m)
                    class_file = fullfile(regions_dir, result.m{i});
                    [~, class_name, ~] = fileparts(class_file);
                    class_type = ['geospm.models.sampling.' class_name];

                    if exist(class_type, 'class')
                        identifier = join(lower(hdng.utilities.split_camelcase(class_name)), '_');
                        identifier = identifier{1};
                        BUILTIN_SAMPLING_STRATEGIES(identifier) = str2func(class_type);
                    end
                end
            end
            
            result = BUILTIN_SAMPLING_STRATEGIES;
        end
        
    
    end
    
end
