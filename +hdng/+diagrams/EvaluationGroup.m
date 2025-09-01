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

classdef EvaluationGroup < handle
    %EvaluationGroup Summary.
    %   Detailed description 
    
    properties
    end

    properties (GetAccess=public, SetAccess=private)
        declarator
        parent_feature
    end
    
    properties (Dependent, Transient)
        features
        declarator_identifier
        expression
    end
    
    methods

        function result = get.features(obj)
            result = obj.parent_feature.children_by_identifier.(...
                obj.declarator_identifier);
        end

        function result = get.declarator_identifier(obj)
            result = obj.declarator.identifier;
        end
        
        function result = get.expression(obj)
            result = obj.declarator.expression;
        end

        function obj = EvaluationGroup(...
                         declarator, ...
                         parent_feature ...
                       )

            obj.declarator = declarator;
            obj.parent_feature = parent_feature;
        end
        
        function [flat_values, stratified_values] = gather_values(obj, attributes)
            
            stratified_values = struct();
            
            flat_size = numel(attributes) * numel(obj.features);
            flat_index = 1;
            flat_values = cell(flat_size, 1);

            for a_index=1:numel(attributes)
                attribute = attributes{a_index};

                values = cell(numel(obj.features), 1);

                for index=1:numel(obj.features)
                    feature = obj.features{index};
                    scope = feature.data_scope;
                    
                    value = scope.attributes.(attribute);
                    values{index} = value;

                    flat_values{flat_index} = value;
                    flat_index = flat_index + 1;
                end

                stratified_values.(attribute) = values;
            end
        end
    end
    
    methods (Static)

        function result = gather_evaluation_groups(root_feature)
            
            result = {};
            stack = {{root_feature, 0}};

            while ~isempty(stack)
                entry = stack{end};
                parent_feature = entry{1};
                child_index = entry{2} + 1;
                
                stack{end} = {parent_feature, child_index};

                if child_index == 1

                    group_names = fieldnames(parent_feature.children_by_identifier);

                    for g_index=1:numel(group_names)
                        group_name = group_names{g_index};

                        features = parent_feature.children_by_identifier.(group_name);

                        if isempty(features)
                            continue;
                        end

                        declarator = features{1}.feature_declarator;
                        
                        result{end + 1} = hdng.diagrams.EvaluationGroup(...
                            declarator, parent_feature); %#ok<AGROW>

                    end
                end
                
                if child_index > numel(parent_feature.children)
                    stack = stack(1:end - 1);
                    continue;
                end

                child = parent_feature.children{child_index};
                stack{end + 1} = {child, 0}; %#ok<AGROW>
            end
        end

    end

end
