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

classdef ObservationTransform < geospm.SpatialAnalysisStage
    
    properties (Constant)
        
        IDENTITY = 'identity'
        CENTER_AT_MEAN = 'center_at_mean'
        STANDARDIZE = 'standardize'
        
    end
    
    properties
        data_requirement
        transform_requirement
        data_product
    end
    
    methods
        
        function obj = ObservationTransform(analysis, varargin)
            obj = obj@geospm.SpatialAnalysisStage(analysis);
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'data_requirement')
                options.data_requirement = 'spatial_data';
            end
            
            if ~isfield(options, 'data_product')
                options.data_product = 'spatial_data';
            end
            
            if ~isfield(options, 'transform_requirement')
                options.transform_requirement = 'observation_transform';
            end
            
            obj.data_requirement = options.data_requirement;
            obj.transform_requirement = options.transform_requirement;
            obj.data_product = options.data_product;
            
            obj.define_requirement(obj.data_requirement);
            
            obj.define_requirement(obj.transform_requirement, ...
                struct(), 'is_optional', true, 'default_value', ...
                geospm.stages.ObservationTransform.IDENTITY);
            
            obj.define_product(obj.data_product);
        end
        
        function result = run(obj, arguments)
            
            result = struct();
            
            transform = obj.resolve_transform(arguments.(obj.transform_requirement));
            result.(obj.data_product) = transform(obj, arguments.(obj.data_requirement), arguments);
        end
    end
    
    methods (Access=protected)
        
        function method = resolve_transform(~, transform)
            
            switch transform
                case geospm.stages.ObservationTransform.IDENTITY
                    method = @(object, spatial_data, arguments) object.identity(spatial_data, arguments);
                case geospm.stages.ObservationTransform.CENTER_AT_MEAN
                    method = @(object, spatial_data, arguments) object.center_at_mean(spatial_data, arguments);
                case geospm.stages.ObservationTransform.STANDARDIZE
                    method = @(object, spatial_data, arguments) object.standardize(spatial_data, arguments);
                
                otherwise
                    method = @(object, spatial_data, arguments) object.report_unknown_transform(transform, spatial_data, arguments);
            end
        end
        
        function result = identity(~, spatial_data, ~)
            result = spatial_data.select([], []);
        end
        
        function result = center_at_mean(obj, spatial_data, ~)
            result = spatial_data.select([], [], @(args) obj.center_at_mean_impl(args));
        end
        
        function result = standardize(obj, spatial_data, ~)
            result = spatial_data.select([], [], @(args) obj.standardize_impl(args));
        end
        
        
        function args = center_at_mean_impl(~, args)
            
            P = size(args.observations, 2);
            
            S = 1;
            
            for index=S:P
                variable = args.observations(:, index);
                args.observations(:, index) = variable - mean(variable);
            end
        end
        
        function args = standardize_impl(~, args)
            
            P = size(args.observations, 2);
            
            S = 1;
            
            for index=S:P
                variable = args.observations(:, index);
                args.observations(:, index) = ...
                    (variable - mean(variable)) / std(variable);
            end
        end
        
        
        function report_unknown_transform(~, transform, ~, ~)
            error('geospm.stages.ObservationTransform: Unknown transform ''%s''', transform);
        end
        
    end
end
