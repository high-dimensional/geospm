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

classdef FeatureDeclarator < hdng.diagrams.Definition
    %FeatureDeclarator Summary.
    %   Detailed description 
    
    properties
        identifier
        
        children
        children_by_identifier
        
        generating_data_level

        expression

        values_by_identifier

        scale_declarators
        scale_declarators_by_identifier

        directives
    end
    
    properties (Dependent, Transient)
        
    end
    
    methods
        
        
        function obj = FeatureDeclarator(varargin)
            obj = obj@hdng.diagrams.Definition('feature_declarator');
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'identifier')
                options.identifier = [obj.category '_' obj.uuid_as_identifier];
            end

            if ~isfield(options, 'data_level')
                options.data_level = [];
            end

            if ~isfield(options, 'children')
                options.children = {};
            end

            if ~isfield(options, 'expression')
                options.expression = [];
            end

            if ~isfield(options, 'directives')
                options.directives = {};
            end
            
            if ~isfield(options, 'values_by_identifier')
                options.values_by_identifier = struct();
            end
            
            
            if ~isfield(options, 'scale_declarators')
                options.scale_declarators = {};
            end
            

            obj.identifier = options.identifier;
            
            obj.children = {};
            obj.children_by_identifier = struct();
            
            obj.generating_data_level = options.data_level;
            
            obj.expression = options.expression;

            obj.values_by_identifier = options.values_by_identifier;

            obj.scale_declarators = {};
            obj.scale_declarators_by_identifier = struct();
            
            obj.directives = {};

            obj.add_children(options.children{:});
            obj.add_directives(options.directives{:});
            obj.add_scale_declarators(options.scale_declarators{:})
        end
        
        function add_child(obj, child)
            
            obj.children{end + 1} = child;

            if ~isempty(child.identifier)
                obj.children_by_identifier.(child.identifier) = child;
            end
        end
        
        function add_children(obj, varargin)
            
            for index=1:numel(varargin)
                child = varargin{index};
                obj.add_child(child);
            end
        end
        
        function add_directive(obj, directive)
            obj.directives{end + 1} = directive;
        end
        
        function add_directives(obj, varargin)
            
            for index=1:numel(varargin)
                directive = varargin{index};
                obj.add_directive(directive);
            end
        end

        function clear_directives(obj)
            obj.directives = {};
        end
        
        function add_scale_declarator(obj, scale_declarator)
            
            obj.scale_declarators{end + 1} = scale_declarator;

            if ~isempty(scale_declarator.identifier)
                obj.scale_declarators_by_identifier.(scale_declarator.identifier) = scale_declarator;
            end
        end
        
        function add_scale_declarators(obj, varargin)
            
            for index=1:numel(varargin)
                scale_declarator = varargin{index};
                obj.add_scale_declarator(scale_declarator);
            end
        end
        
        function root_feature = generate_feature(obj, data_scope, parent_stack)
            
            if ~exist('data_scope', 'var')
                data_scope = [];
            end

            scales = obj.generate_scales();
            
            root_feature = obj.create_feature('identifier', obj.identifier, ...
                'feature_declarator', obj, 'data_scope', data_scope, ...
                'values_by_identifier', obj.values_by_identifier, ...
                'scales', scales, 'parent_stack', parent_stack(:));
            
            for index=1:numel(obj.children)
                child = obj.children{index};
                
                root_feature.add_child(child.generate_feature(data_scope, [parent_stack(:); {root_feature}]));
            end
        end
    end
    
    methods (Access=protected)
    
        function result = access_nested_definitions(obj)
            result = obj.children;
        end
        
        function result = create_feature(~, varargin)
            result = hdng.diagrams.Feature(varargin{:});
        end

        function result = generate_scales(obj)
            result = cell(numel(obj.scale_declarators), 1);

            for index=1:numel(obj.scale_declarators)
                declarator = obj.scale_declarators{index};
                result{index} = declarator.generate_scale();
            end
        end
    end
end
