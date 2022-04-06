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

classdef Parameter < handle
    %Parameter Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        generator
        type
        name
        identifier
        nth_parameter
    end
    
    methods
        
        function obj = Parameter(generator, name, type, identifier, varargin)
            
            if numel(name) == 0
                error('Parameter.ctor(): Expected non-empty name.');
            end
            
            if ~exist('identifier', 'var') || numel(identifier) == 0
                identifier = regexprep(lower(name), '[^\w]+', '_');
            end
            
            obj.generator = generator;
            obj.type = type;
            obj.name = name;
            obj.identifier = identifier;
            obj.nth_parameter = obj.generator.add_parameter(obj);
        end
        
        function result = load_dependencies(~)
            result = {};
        end
        
        function compute(obj, model, metadata) %#ok<INUSD>
        	error('Parameter.render() must be implemented by a subclass.');
        end
    end
    
    methods (Static, Access=public)
        
        
        function render(model, metadata, parameters, get_dependencies)
            
            if ~exist('get_dependencies', 'var')
                get_dependencies = @(parameter) parameter.load_dependencies();
            end
            
            N_parameters = numel(parameters);
            
            forward  = cell(N_parameters, 1);
            backward = cell(N_parameters, 1);
            
            for i=1:N_parameters
                backward{i} = zeros(0,1, 'int32');
            end
            
            available = zeros(N_parameters,1);
            n_available = 0;
            
            for i=1:N_parameters
                
                parameter = parameters{i};
                
                dep_params = get_dependencies(parameter);
                
                k = numel(dep_params);
                dep_indices = zeros(k, 1, 'int32');
                
                for j=1:k
                    dep_indices(j) = dep_params{j}.nth_parameter;
                    backward{dep_indices(j)}(end + 1) = i;
                end
                
                if k == 0
                    % record the ith parameter as available since it has
                    % no dependencies
                    n_available = n_available + 1;
                    available(n_available) = i;
                end
                
                forward{i} = dep_indices;
            end
            
            viable = zeros(N_parameters,1);
            n_viable = 0; 
            
            while n_available > 0
            
                for i=1:n_available
                    
                    parameter_index = available(i);
                    parameter = parameters{parameter_index};
                    
                    % the parameter has no more dependencies, so compute it
                    parameter.compute(model, metadata);
                    
                    % Update the dependency structure now that another
                    % parameter has been computed
                    
                    % back_deps are the dependencies which directly depend
                    % on the computed parameter
                    
                    back_deps = backward{parameter_index};
                    
                    for j=1:numel(back_deps)
                    
                        b = back_deps(j);
                        
                        % update b's forward dependencies
                        
                        if isempty(forward{b})
                            error('Parameter.render(): Error, detected inconsistency in depencency structure.');
                        end
                        
                        
                        forw_deps = forward{b};
                        
                        %We no longer erase all forward dependencies in one
                        %step to allow for multiple dependencies between
                        %the same pair of parameters (i.e. the dependency graph
                        % is a multi-edge graph)
                        %forw_deps = forw_deps(forw_deps ~= parameter_index);
                        
                        forw_deps(find(forw_deps == parameter_index, 1)) = [];
                        
                        forward{b} = forw_deps;
                        
                        % if b's forward dependencies are empty, mark it as
                        % viable
                        
                        if numel(forw_deps) == 0
                            n_viable = n_viable + 1;
                            viable(n_viable) = b;
                        end
                    end
                
                end
                
                % designate the parameters marked as viable as available
                
                tmp = available;
                available = viable;
                n_available = n_viable;
                viable = tmp;
                n_viable = 0;
            end
        end
    end
    
    methods (Static, Access=private)
    end
    
end
