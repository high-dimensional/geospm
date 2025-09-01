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

classdef ScaleUsage < handle
    %ScaleUsage Summary.
    %   Detailed description 
    
    properties
    end

    properties (GetAccess=public, SetAccess=private)
        evaluation_group

        scale
        scale_feature
    end
    
    properties (Dependent, Transient)
        declarator_identifier
        expression
        scale_identifier
        scale_declarator
        scale_declarator_identifier
    end
    
    methods

        function result = get.declarator_identifier(obj)
            result = obj.evaluation_group.declarator.identifier;
        end
        
        function result = get.expression(obj)
            result = obj.evaluation_group.declarator.expression;
        end
        
        function result = get.scale_identifier(obj)
            result = obj.scale.identifier;
        end

        function result = get.scale_declarator(obj)
            result = obj.scale_feature.feature_declarator;
        end

        function result = get.scale_declarator_identifier(obj)
            result = obj.scale_declarator.identifier;
        end

        function obj = ScaleUsage(...
                           evaluation_group, ...
                           scale, ...
                           scale_feature ...
                       )
            
            obj.evaluation_group = evaluation_group;
            obj.scale = scale;
            obj.scale_feature = scale_feature;
        end
        
        function [flat_values, stratified_values] = gather_values(obj)
            
            if ~isfield(obj.expression.attributes_per_scale, obj.scale.identifier)
                flat_values = [];
                stratified_values = {};
                return;
            end

            attributes = obj.expression.attributes_per_scale.(obj.scale.identifier);
            [flat_values, stratified_values] = obj.evaluation_group.gather_values(attributes);
        end
        
        function flat_constants = gather_constants(obj)
            
            if ~isfield(obj.expression.constants_per_scale, obj.scale.identifier)
                flat_constants = [];
                return;
            end
            
            flat_constants = obj.expression.constants_per_scale.(obj.scale.identifier);

        end
        
        function result = compute_scaled_values(obj, stratified_values)
            
            result = struct();
            
            attributes = fieldnames(stratified_values);
            
            for a_index=1:numel(attributes)
                attribute = attributes{a_index};
                values = stratified_values.(attribute);
                scaled_values = obj.scale.apply(values);
                result.(attribute) = scaled_values;
            end
        end

        function update_scaled_values(obj, scaled_stratified_values, constants)
            
            value_attributes = fieldnames(scaled_stratified_values);
            
            for index=1:numel(obj.evaluation_group.features)
                feature = obj.evaluation_group.features{index};
                
                feature_scaled_values = struct();

                for a_index=1:numel(value_attributes)
                    attribute = value_attributes{a_index};
                    
                    values = scaled_stratified_values.(attribute);
                    feature_scaled_values.(attribute) = values{index};
                end

                feature.update_scaled_values(obj.scale.identifier, feature_scaled_values, constants);
            end
        end
    end
    
    methods (Static)

        function [scale, scale_feature] = lookup_scale(identifier, parent_feature, base, parents)

            scale = [];
            scale_feature = [];
            
            while ~isempty(parent_feature)
                if isfield(parent_feature.scales_by_identifier, identifier)
                    scale = parent_feature.scales_by_identifier.(identifier);
                    scale_feature = parent_feature;
                    break;
                end

                parent_feature = parents.inward(parent_feature, base);

                if ~isempty(parent_feature)
                    parent_feature = parent_feature{1};
                end
            end
        end
        
        function result = gather_scale_usages(evaluation_groups, base, parents, check_fn)
            
            if ~exist('check_fn', 'var')
                check_fn = [];
            end
            
            result = {};
            
            for g_index=1:numel(evaluation_groups)

                evaluation_group = evaluation_groups{g_index};
                
                if isempty(evaluation_group.expression)
                    continue
                end
                
                expression = evaluation_group.expression;
                
                %{
                scale_identifiers = join(expression.scale_identifiers, ', ');
                scale_identifiers = scale_identifiers{1};

                if ~isempty(scale_identifiers)
                    fprintf('Expression scale identifiers:\n%s\n', scale_identifiers);
                end
                %}

                for s_index=1:numel(expression.scale_identifiers)
    
                    s_identifier = expression.scale_identifiers{s_index};
                    
                    [scale, scale_feature] = ...
                        hdng.diagrams.ScaleUsage.lookup_scale(...
                            s_identifier, evaluation_group.parent_feature, ...
                            base, parents);
                    
                    if isempty(scale)
                        continue;
                    end

                    if ~isempty(check_fn) && ~check_fn(evaluation_group, s_identifier, scale, scale_feature)
                        continue;
                    end
    
                    result{end + 1} = ...
                        hdng.diagrams.ScaleUsage(...
                            evaluation_group, scale, scale_feature); %#ok<AGROW>
                end
            end
        end
    end
end
