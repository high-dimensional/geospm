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

classdef FeatureExpression < handle
    %FeatureExpression Summary.  
    %   Detailed description 
    
    properties
        assigned_identifiers
    end
    
    properties (Dependent, Transient)
        dependencies_by_identifier
        attributes_per_scale
        constants_per_scale
        scale_identifiers
    end
    
    properties (Access=private)
        dependencies_by_identifier_
        attributes_per_scale_
        constants_per_scale_
        delegate_
    end

    methods

        function result = get.attributes_per_scale(obj)
            result = obj.attributes_per_scale_;
        end

        function result = get.constants_per_scale(obj)
            result = obj.constants_per_scale_;
        end

        function result = get.scale_identifiers(obj)
            result = unique([fieldnames(obj.attributes_per_scale_);
                             fieldnames(obj.constants_per_scale_)]);
        end
        
        function result = get.dependencies_by_identifier(obj)

            if ~isstruct(obj.dependencies_by_identifier_)
                obj.dependencies_by_identifier_ = obj.compute_dependencies();
            end

            result = obj.dependencies_by_identifier_;
        end
        
        function obj = FeatureExpression(assigned_identifiers, delegate, ...
                dependencies_by_identifier, attributes_per_scale, constants_per_scale)

            if ~exist('attributes_per_scale', 'var') || isempty(attributes_per_scale)
                attributes_per_scale = struct();
            end

            if ~exist('constants_per_scale', 'var')
                constants_per_scale = struct();
            end
            
            obj.assigned_identifiers = assigned_identifiers;
            obj.delegate_ = delegate;
            obj.dependencies_by_identifier_ = dependencies_by_identifier;
            obj.attributes_per_scale_ = attributes_per_scale;
            obj.constants_per_scale_ = constants_per_scale;
        end
        
        function compute(obj, context, scaled_values, constants)
            obj.delegate_(obj.assigned_identifiers, context, ...
                scaled_values, constants);
        end
    end

    methods (Access=protected)

        function result = compute_dependencies(obj)
            result = struct();
        end

    end
end
