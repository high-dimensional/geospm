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

classdef CovariogramModel < handle
    %CovariogramModel 
    %   
    
    properties
        name
    end
    
    properties (Dependent, Transient)
        component_labels
        N_components
        variograms
        N_variograms
    end
    
    properties (GetAccess=private, SetAccess=private)
        component_labels_
        variogram_cells
        component_indices
    end
    
    methods
        
        function obj = CovariogramModel()
            obj.name = '';
            obj.component_labels_ = {};
            obj.component_indices = containers.Map('KeyType', 'char', 'ValueType', 'int64');
            obj.variogram_cells = {};
        end
        
        function result = get.component_labels(obj)
            result = obj.component_labels_;
        end
        
        function result = get.N_components(obj)
            result = numel(obj.component_labels_);
        end
        
        function result = get.variograms(obj)
            result = obj.variogram_cells;
        end
        
        function result = get.N_variograms(obj)
            result = numel(obj.variogram_cells);
        end
        
        function result = max_y_at_x(obj, x, steps)
            
            y_range = zeros(obj.N_variograms, 1);
            
            for index=1:obj.N_variograms
                [~, y] = obj.variogram_cells{index}.evaluate(0, x, steps);
                y_range(index) = max(y);
            end
            
            result = max(y_range);
        end
        
        function result = variogram_model_for(obj, component1, component2)
            
            if ~isKey(obj.component_indices, component1)
                error(['CovariogramModel.variogram_for(): Unknown component label: ''' component1 '']);
            end
            
            component1_index = obj.component_indices(component1);
            
            if ~exist('component2', 'var')
                component2_index = component1_index;
            else
                
                if ~isKey(obj.component_indices, component2)
                    error(['CovariogramModel.variogram_for(): Unknown component label: ''' component2 '']);
                end
                
                component2_index = obj.component_indices(component2);
            end
            
            index = obj.xy_to_index(component1_index, component2_index);
            result = obj.variogram_cells{index};
        end
        
        
        function initialise_from_parameters(obj, parameters, variogram_labels, correlation_labels)
            
            tmp_component_labels = {};
            tmp_component_indices = containers.Map('KeyType', 'char', 'ValueType', 'int64');
            tmp_variogram_cells = {};
            
            
            for index=1:numel(variogram_labels)
                label = variogram_labels{index};
                
                parts = split(label, '.');
                indices = zeros(1, numel(parts));
                
                for j=1:numel(parts)
                    part = parts{j};
                    
                    if ~isKey(tmp_component_indices, part)
                        tmp_component_labels{end + 1} = part; %#ok<AGROW>
                        tmp_component_indices(part) = numel(tmp_component_labels);
                    end
                    
                    indices(j) = tmp_component_indices(part);
                end
                
                if numel(parts) == 1
                    indices = [indices, indices]; %#ok<AGROW>
                end
                
                variogram_index = obj.xy_to_index(indices(1), indices(2));
                
                indices = find(parameters.label == index);
                
                params = struct();
                
                params.model = parameters.model(indices);
                params.psill = parameters.psill(indices);
                params.range = parameters.range(indices);
                params.kappa = parameters.kappa(indices);
                params.ang1 = parameters.ang1(indices);
                params.ang2 = parameters.ang2(indices);
                params.ang3 = parameters.ang3(indices);
                params.anis1 = parameters.anis1(indices);
                params.anis2 = parameters.anis2(indices);
                
                variogram_model = geospm.variograms.VariogramModel();
                variogram_model.initialise_from_parameters(params, correlation_labels);
                variogram_model.name = label;
                
                if isfield(parameters, 'sserr')
                    variogram_model.sum_of_squared_error = parameters.sserr(indices(1));
                end
                
                if isfield(parameters, 'converged')
                    variogram_model.converged = parameters.converged(indices(1));
                end
                
                tmp_variogram_cells{variogram_index} = variogram_model; %#ok<AGROW>
            end
            
            obj.component_labels_ = tmp_component_labels;
            obj.component_indices = tmp_component_indices;
            obj.variogram_cells = tmp_variogram_cells;
        end
        
        function plot(obj, range_min, range_max, steps)
            
            [~] = gcf;
            
            ax = gca;
            axis(ax, 'equal', 'auto');
            
            
            for i=1:obj.N_components
                component1 = obj.component_labels_{i};
                
                for j=1:i
                    component2 = obj.component_labels_{j};
                    
                    variogram = obj.variogram_model_for(component1, component2);
                    
                    k = (i - 1) * obj.N_components + j;
                    subplot(obj.N_components, obj.N_components, k);
                    
                    variogram.plot(range_min, range_max, steps);
                end
            end
        end
        
        function result = as_json(obj)
            
            result = struct();
            result.name = obj.name;
            result.component_labels = obj.component_labels;
            result.variogram_models = cell(1, obj.N_variograms);
            
            for index=1:obj.N_variograms
                variogram = obj.variogram_cells{index};
                result.variogram_models{index} = variogram.as_json();
            end
        end
    end
    
    methods (Static)
        
        function result = from_json(json_struct)
            
            result = geospm.variograms.CovariogramModel();
            
            result.name = json_struct.name;
            result.component_labels_ = json_struct.component_labels;
            
            for index=1:numel(result.component_labels)
                component_label = json_struct.component_labels{index};
                result.component_indices(component_label) = index;
            end
            
            N_variograms = numel(json_struct.variogram_models);
            
            for index=1:N_variograms
                model_json = json_struct.variogram_models(index);
                result.variogram_cells{index} = geospm.variograms.VariogramModel.from_json(model_json);
            end
        end
        
        function result = xy_to_index(x, y)
            
            if x < y
                tmp = x;
                x = y;
                y = tmp;
            end
            
            result = x * (x - 1) / 2 + y;
        end
        
        function [x, y] = index_to_xy(index)
            
            x = floor((sqrt(1 + 8 * (index - 1)) - 1) / 2) + 1;
            y = index - x * (x - 1) / 2;
        end
        
    end
end
