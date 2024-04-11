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

classdef ObservationTransform < geospm.stages.SpatialAnalysisStage
    
    properties (Constant)
        
        IDENTITY = 'identity'
        CENTER_AT_MEAN = 'center_at_mean'
        STANDARDIZE = 'standardize'
        
    end
    
    properties
        data_requirement
        spatial_index_requirement
        transform_requirement

        data_product
        spatial_index_product
    end
    
    methods
        
        function obj = ObservationTransform(analysis, varargin)
            obj = obj@geospm.stages.SpatialAnalysisStage(analysis);
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'data_requirement')
                options.data_requirement = 'spatial_data';
            end
            
            if ~isfield(options, 'spatial_index_requirement')
                options.spatial_index_requirement = 'spatial_index';
            end
            
            if ~isfield(options, 'data_product')
                options.data_product = 'spatial_data';
            end
            
            if ~isfield(options, 'spatial_index_product')
                options.spatial_index_product = 'spatial_index';
            end
            
            if ~isfield(options, 'transform_requirement')
                options.transform_requirement = 'observation_transform';
            end
            
            obj.data_requirement = options.data_requirement;
            obj.spatial_index_requirement = options.spatial_index_requirement;
            obj.transform_requirement = options.transform_requirement;
            obj.data_product = options.data_product;
            obj.spatial_index_product = options.spatial_index_product;
            
            obj.define_requirement(obj.data_requirement);
            obj.define_requirement(obj.spatial_index_requirement);
            
            obj.define_requirement(obj.transform_requirement, ...
                struct(), 'is_optional', true, 'default_value', ...
                geospm.stages.ObservationTransform.IDENTITY);
            
            obj.define_product(obj.data_product);
            obj.define_product(obj.spatial_index_product);
        end
        
        function result = run(obj, arguments)
            
            result = struct();
            
            transform = obj.resolve_transform(arguments.(obj.transform_requirement));
            [result.(obj.data_product), result.(obj.spatial_index_product)] = transform(obj, arguments.(obj.data_requirement), arguments.(obj.spatial_index_requirement), arguments);
        end
    end
    
    methods (Access=protected)
        
        function method = resolve_transform(~, transform)
            
            switch transform
                case geospm.stages.ObservationTransform.IDENTITY
                    method = @(object, spatial_data, spatial_index, arguments) object.identity(spatial_data, spatial_index, arguments);
                case geospm.stages.ObservationTransform.CENTER_AT_MEAN
                    method = @(object, spatial_data, spatial_index, arguments) object.center_at_mean(spatial_data, spatial_index, arguments);
                case geospm.stages.ObservationTransform.STANDARDIZE
                    method = @(object, spatial_data, spatial_index, arguments) object.standardize(spatial_data, spatial_index, arguments);
                
                otherwise
                    method = @(object, spatial_data, spatial_index, arguments) object.report_unknown_transform(transform, spatial_data, spatial_index, arguments);
            end
        end
        
        function [result, spatial_index] = identity(~, spatial_data, spatial_index, ~)
            result = spatial_data.select([], []);
        end
        
        function [result, spatial_index] = center_at_mean(obj, spatial_data, spatial_index, ~)
            result = spatial_data.select([], [], @(specifier, modifier) obj.center_at_mean_impl(specifier, modifier));
        end
        
        function [result, spatial_index] = standardize(obj, spatial_data, spatial_index, ~)
            result = spatial_data.select([], [], @(specifier, modifier) obj.standardize_impl(specifier, modifier));
        end
        
        
        function specifier = center_at_mean_impl(~, specifier, modifier) %#ok<INUSD>
            
            P = size(specifier.data, 2);
            
            S = 1;
            
            for index=S:P
                variable = specifier.data(:, index);
                specifier.data(:, index) = variable - mean(variable);
            end
        end
        
        function specifier = standardize_impl(~, specifier, modifier) %#ok<INUSD>
            
            P = size(specifier.data, 2);
            
            S = 1;
            
            for index=S:P
                variable = specifier.data(:, index);
                specifier.data(:, index) = ...
                    (variable - mean(variable)) / std(variable);
            end
        end
        
        
        function report_unknown_transform(~, transform, ~, ~, ~)
            error('geospm.stages.ObservationTransform: Unknown transform ''%s''', transform);
        end
        
    end
end
