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

classdef EmpiricalCovariogram < handle
    %EmpiricalCovariogram 
    %   
    
    properties
        name
    end
    
    properties (Dependent, Transient)
        component_labels
        N_components
        variograms
        N_variograms
        
        max_distance
        max_gamma
    end
    
    properties (GetAccess=private, SetAccess=private)
        component_labels_
        variogram_cells
        component_indices
    end
    
    methods
        
        function obj = EmpiricalCovariogram()
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
        
        function result = get.max_distance(obj)
            result = max(arrayfun(@(x) x{1}.max_distance, obj.variogram_cells));
        end
        
        function result = get.max_gamma(obj)
            result = max(arrayfun(@(x) x{1}.max_gamma, obj.variogram_cells));
        end
        
        function result = variogram_for(obj, component1, component2)
            
            if ~isKey(obj.component_indices, component1)
                error(['EmpiricalCovariogram.variogram_for(): Unknown component label: ''' component1 '']);
            end
            
            component1_index = obj.component_indices(component1);
            
            if ~exist('component2', 'var')
                component2_index = component1_index;
            else
                
                if ~isKey(obj.component_indices, component2)
                    error(['EmpiricalCovariogram.variogram_for(): Unknown component label: ''' component2 '']);
                end
                
                component2_index = obj.component_indices(component2);
            end
            
            index = obj.xy_to_index(component1_index, component2_index);
            result = obj.variogram_cells{index};
        end
        
        function initialise_from_parameters(obj, parameters, variogram_labels)
            
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
                
                indices = find(parameters.id == index);
                
                params = struct();
                
                params.np = parameters.np(indices);
                params.distance = parameters.dist(indices);
                params.gamma = parameters.gamma(indices);
                params.dir_hor = parameters.dir_hor(indices);
                params.dir_ver = parameters.dir_ver(indices);
                
                variogram = geospm.variograms.EmpiricalVariogram();
                variogram.define(params.distance, params.gamma, params.np);
                variogram.name = label;
                
                tmp_variogram_cells{variogram_index} = variogram; %#ok<AGROW>
            end
            
            obj.component_labels_ = tmp_component_labels;
            obj.component_indices = tmp_component_indices;
            obj.variogram_cells = tmp_variogram_cells;
        end
        
        function plot(obj, fitted_model, varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'plot_resolution')
                options.plot_resolution = 100;
            end
            
            if ~isfield(options, 'layout')
                options.layout = 'square';
            end
            
            if ~isfield(options, 'distance_limit')
                options.distance_limit = obj.max_distance;
            end
            
            if ~isfield(options, 'gamma_limit')
                options.gamma_limit = [];
            end
            
            arguments = hdng.utilities.struct_to_name_value_sequence(rmfield(options, 'plot_resolution'));
            
            [~] = gcf;
            
            y_range = zeros(1, obj.N_variograms);
            
            for index=1:obj.N_variograms
                variogram = obj.variogram_cells{index};
                y_range(index) = variogram.max_gamma_at_distance(options.distance_limit);
            end
            
            for i=1:obj.N_components
                component1 = obj.component_labels_{i};
                
                for j=1:i
                    component2 = obj.component_labels_{j};
                    
                    variogram = obj.variogram_for(component1, component2);
                    variogram_index = geospm.variograms.CovariogramModel.xy_to_index(i, j);
                    
                    switch options.layout
                        case 'row'
                            k = variogram_index;
                            subplot(1, obj.N_variograms + 1, k);
                            
                        otherwise
                            k = (i - 1) * obj.N_components + j;
                            subplot(obj.N_components, obj.N_components, k);
                    end
                    
                    hold on;
                    
                    variogram.plot_impl(arguments{:});
                    
                    if exist('fitted_model', 'var')
                        variogram_model = fitted_model.variogram_model_for(component1, component2);
                        [~, y] = variogram_model.plot_impl(0, options.distance_limit, options.plot_resolution, arguments{:});
                        y_range(variogram_index) = max([y_range(variogram_index), max(y)]);
                    end
                    
                    hold off;
                end
            end
            
            if isempty(options.gamma_limit)
                options.gamma_limit = max(y_range);
            end
            
            for i=1:obj.N_components
                
                for j=1:i
                            
                    variogram_index = geospm.variograms.CovariogramModel.xy_to_index(i, j);
                    
                    switch options.layout
                        case 'row'
                            k = variogram_index;
                            subplot(1, obj.N_variograms + 1, k);
                            
                        otherwise
                            k = (i - 1) * obj.N_components + j;
                            subplot(obj.N_components, obj.N_components, k);
                    end
                    
                    xlim([0.0, options.distance_limit]);
                    ylim([0.0, options.gamma_limit]);
                end
            end
        end
        
        function result = as_json(obj)
            
            result = struct();
            result.name = obj.name;
            result.component_labels = obj.component_labels;
            result.empirical_variograms = cell(1, obj.N_variograms);
            
            for index=1:obj.N_variograms
                variogram = obj.variogram_cells{index};
                result.empirical_variograms{index} = variogram.as_json();
            end
        end
    end
    
    methods (Static)
        
        
        function result = from_json(json_struct)
            
            result = geospm.variograms.EmpiricalCovariogram();
            
            result.name = json_struct.name;
            result.component_labels_ = json_struct.component_labels;
            
            for index=1:numel(result.component_labels)
                component_label = json_struct.component_labels{index};
                result.component_indices(component_label) = index;
            end
            
            N_variograms = numel(json_struct.empirical_variograms);
            
            for index=1:N_variograms
                variogram_json = json_struct.empirical_variograms(index);
                result.variogram_cells{index} = geospm.variograms.EmpiricalVariogram.from_json(variogram_json);
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
