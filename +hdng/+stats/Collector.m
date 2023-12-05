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

classdef Collector < handle
    %Collector Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=immutable)
    end
    
    properties (GetAccess=private, SetAccess=private)
        statistics
    end
    
    
    methods
        
        function obj = Collector()
            obj.statistics = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end
        
        function result = require_statistic(obj, identifier, parameters)
            
            if ~isKey(obj.statistics, identifier)
                entries = {};
                method = hdng.stats.Collector.method_registry('query', identifier);
            else
                entries = obj.statistics(identifier);
                method = entries{1}.method;
            end
            
            statistic = hdng.stats.Statistic(numel(entries) + 1, identifier, method, parameters);
            
            for i=1:numel(entries)
                entry = entries{i};
                
                if entry.matches(statistic)
                    result = entry;
                    return
                end
            end
            
            result = statistic;
            entries = [entries {statistic}];
            obj.statistics(identifier) = entries;
        end
        
        function result = compute_statistics(obj, batch)
            
            result = struct();
            identifiers = keys(obj.statistics);
            
            for i=1:numel(identifiers)
                identifier = identifiers{i};
                entries = obj.statistics(identifier);
                values = cell(numel(entries), 1);
                
                if numel(entries) > 0
                    method = entries{1}.method;
                    values = method(batch, entries);
                end
                
                result.(identifier) = values;
            end
        end
    end
    
    methods (Static)
        
        function result = constant_function(~, entries)
            result = cell(1, numel(entries));
            
            for i=1:numel(entries)
                entry = entries{i};
                result{i} = entry.parameters.value;
            end
        end
        
        function result = min_function(batch, ~)
            
            N = numel(batch);
            result = zeros(1, N); 
            
            for i=1:N
                data = batch{i};
                result(i) = min(data(:));
            end
            
            result = { min( result ) };
        end
        
        function result = at_most_function(batch, entries)

            N = numel(batch);
            K = numel(entries);
            result = zeros(K, N); 
            
            for i=1:N
                data = batch{i};
                data_max = min(data(:));
                
                for j=1:K
                    
                    entry = entries{j};
                    result(j, i) = data_max;
                    
                    if result(j, i) > entry.parameters.value
                        result(j, i) = entry.parameters.value;
                    end
                end
            end
            
            result = num2cell(min( result, [], 2 ));
        end
        
        function result = max_function(batch, ~)
            
            N = numel(batch);
            result = zeros(1, N); 
            
            for i=1:N
                data = batch{i};
                result(i) = max(data(:));
            end
            
            result = { max( result ) };
        end
        
        function result = at_least_function(batch, entries)
            
            N = numel(batch);
            K = numel(entries);
            result = zeros(K, N); 
            
            for i=1:N
                data = batch{i};
                data_max = max(data(:));
                
                for j=1:K
                    
                    entry = entries{j};
                    result(j, i) = data_max;
                    
                    if result(j, i) < entry.parameters.value
                        result(j, i) = entry.parameters.value;
                    end
                end
            end
            
            result = num2cell(max( result, [], 2 ));
        end
        
        function result = quantile_function(batch, entries)
            
            result = zeros(1, numel(entries));
            p = result;
            
            % Gather all unique conditions from the quantile entries

            conditions = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            for i=1:numel(entries)
                entry = entries{i};
                
                if isfield(entry.parameters, 'condition')
                    condition = entry.parameters.condition;
                else
                    condition = '';
                end
                
                if ~isKey(conditions, condition)
                    conditions(condition) = i;
                else
                    conditions(condition) = [conditions(condition) i];
                end
                
                p(i) = entry.parameters.value;
            end
            
            % Evaluate each unique condition and assign result to all
            % relevant entries

            condition_keys = keys(conditions);
            
            for i=1:numel(condition_keys)
                key = condition_keys{i};
                indices = conditions(key);
                
                data = [];
                
                for j=1:numel(batch)
                    element = batch{j};
                    data = [data; element(:)]; %#ok<AGROW>
                end
                
                if ~isempty(key)
                    selector = hdng.stats.Collector.evaluate(data, key);
                    data = data(selector);
                end
                
                result(indices) = quantile(data, p(indices));
            end
            
            result = num2cell(result);
        end
        
        function result = evaluate(x, expr) %#ok<INUSL>
            result = eval(expr);
        end
        
        function result = method_registry(action, identifier, F)
            
            persistent functions;
            
            if isempty(functions)
                functions = containers.Map('KeyType', 'char', 'ValueType', 'any');
                
                functions('constant') = @hdng.stats.Collector.constant_function;
                functions('min') = @hdng.stats.Collector.min_function;
                functions('at_most') = @hdng.stats.Collector.at_most_function;
                functions('max') = @hdng.stats.Collector.max_function;
                functions('at_least') = @hdng.stats.Collector.at_least_function;
                functions('quantile') = @hdng.stats.Collector.quantile_function;
            end
            
            result = [];
            
            if strcmp(action, 'add')
                
                functions(identifier) = F;
            
            elseif strcmp(action, 'query')
                
                if isKey(functions, identifier)
                    result = functions(identifier);
                end
                
            elseif strcmp(action, 'remove')
                
                if isKey(functions, identifier)
                    remove(functions, identifier);
                end
            else
                error('Unknown method registry action: %s', action);
            end
        end
    end
end
