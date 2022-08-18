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

classdef VariogramModel < handle
    %VariogramModel 
    %   
    
    properties
        name
        partial_sills
        correlations
        sum_of_squared_error
        converged
    end
    
    properties (Dependent, Transient)
        N_components
        nugget_sills
        nugget_components
    end
    
    methods
        
        function obj = VariogramModel()
            obj.name = '';
            obj.partial_sills = [];
            obj.correlations = {};
            obj.sum_of_squared_error = [];
            obj.converged = [];
        end
        
        function result = get.N_components(obj)
            result = numel(obj.partial_sills);
        end
        
        function result = get.nugget_sills(obj)
            result = obj.partial_sills(...
                        cellfun(@(x) strcmp(x.name, 'Nugget'), ...
                        obj.correlations));
        end
        
        function result = get.nugget_components(obj)
            result = cellfun(@(x) strcmp(x.name, 'Nugget'), ...
                        obj.correlations);
        end
        
        function add_component(obj, correlation, partial_sill)
            obj.correlations{end + 1} = correlation;
            obj.partial_sills(end + 1) = partial_sill;
        end
        
        function result = as_json(obj)
            result = struct();
            result.name = obj.name;
            result.correlations = cell(1, obj.N_components);
            
            if ~isempty(obj.sum_of_squared_error)
                result.sum_of_squared_error = obj.sum_of_squared_error;
            end
            
            if ~isempty(obj.converged)
                result.converged = obj.converged;
            end
            
            for index=1:obj.N_components
                correlation = obj.correlations{index};
                json_correlation = struct();
                json_correlation.name = correlation.name;
                json_correlation.parameters = correlation.parameters;
                
                result.correlations{index} = json_correlation;
            end
            
            result.partial_sills = obj.partial_sills;
        end
        
        function y = evaluate_at(obj, x)
            [y, ~] = obj.evaluate(x, x, 1);
        end
        
        function [x, y] = evaluate(obj, range_min, range_max, steps)
            
            if steps > 1
                x = (0:steps - 1)' / (steps - 1) * (range_max - range_min) + range_min;
            else
                x = range_min;
            end
            
            y = zeros(steps, 1);
            
            for index=1:obj.N_components
                [~, component_y] = obj.correlations{index}.evaluate(range_min, range_max, steps);
                component_y = obj.partial_sills(index) * (1.0 - component_y);
                y = y + component_y;
            end
        end
        
        function plot(obj, range_min, range_max, steps, varargin)
            
            [~] = gcf;
            
            ax = gca;
            axis(ax, 'equal', 'auto');
            
            obj.plot_impl(range_min, range_max, steps, varargin{:});
        end
        
        function [x, y] = plot_impl(obj, range_min, range_max, steps, varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            [x, y] = obj.evaluate(range_min, range_max, steps);
            
            value = sum(obj.nugget_sills);
            y(1) = value;
            
            h = plot(x, y);
            
            if isfield(options, 'LineWidth')
                h.LineWidth = options.LineWidth;
            end
            
            if ~isempty(obj.name)
                title(obj.name);
            end
        end
        
        function initialise_from_parameters(obj, parameters, correlation_labels)
            
            tmp_partial_sills = zeros(1, numel(parameters.model));
            tmp_correlations = cell(1, numel(parameters.model));
            
            for index=1:numel(parameters.model)
                
                label_index = parameters.model(index);
                correlation_name = correlation_labels{label_index};
                
                tmp_partial_sills(index) = parameters.psill(index);
                
                params = struct();
                
                params.range = parameters.range(index);
                params.smoothness = parameters.kappa(index);
                
                params.ang1 = parameters.ang1(index);
                params.ang2 = parameters.ang2(index);
                params.ang3 = parameters.ang3(index);
                params.anis1 = parameters.anis1(index);
                params.anis2 = parameters.anis2(index);
                
                correlation = geospm.variograms. ...
                    Function.create_correlation_function(correlation_name);
                
                correlation.parameters = params;
                
                tmp_correlations{index} = correlation;
            end
            
            obj.partial_sills = tmp_partial_sills;
            obj.correlations = tmp_correlations;
        end
    end
    
    methods (Static)
        
        function result = from_json(json_struct)
            result = geospm.variograms.VariogramModel();
            result.name = json_struct.name;
            
            if isfield(json_struct, 'sum_of_squared_error')
                result.sum_of_squared_error = json_struct.sum_of_squared_error;
            end
            
            if isfield(json_struct, 'converged')
                result.converged = json_struct.converged;
            end
            
            for index=1:numel(json_struct.correlations)
                
                json_correlation = json_struct.correlations(index);
                
                correlation = geospm.variograms. ...
                    Function.create_correlation_function(json_correlation.name);
                
                correlation.parameters = json_correlation.parameters;
                
                result.correlations{index} = correlation;
                result.partial_sills(index) = json_struct.partial_sills(index);
            end
        end
    end
    
    methods (Access=protected)
        
    end
end
