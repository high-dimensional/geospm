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

classdef DataLevel < hdng.diagrams.Definition
    %DataLevel Summary.
    %   Detailed description 
    
    properties
        identifier
        generator_list
        children
        children_by_identifier

        assignments
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = DataLevel(varargin)
            obj = obj@hdng.diagrams.Definition('data_level');

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'identifier')
                options.identifier = '';
            end

            if ~isfield(options, 'generator_list')
                options.generator_list = {};
            end

            if ~isfield(options, 'children')
                options.children = {};
            end

            if ~isfield(options, 'assignments')
                options.assignments = {};
            end

            obj.identifier = options.identifier;
            obj.generator_list = options.generator_list;
            obj.children = {};
            obj.children_by_identifier = struct();

            obj.assignments = options.assignments;

            obj.add_children(options.children{:});
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
        
        function scopes = generate_scopes_from(obj, parent_scope)

            if isempty(obj.generator_list)
                scopes = {};
                return
            end

            scopes = {parent_scope};

            for index=1:numel(obj.generator_list)
                generator = obj.generator_list{index};
                scopes = obj.apply_generator(generator, scopes);
            end
        
        end

    end

    methods (Access=protected)
    
        function result = access_nested_definitions(obj)
            result = obj.children;
        end

        function generated_scopes = apply_generator(obj, generator, scopes)
            
            generated_scopes = {};

            for index=1:numel(scopes)
                scope = scopes{index};
                generated_scopes = [generated_scopes; generator.apply(scope, obj)]; %#ok<AGROW>
            end
        end
        
    end
end
