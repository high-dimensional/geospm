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

classdef ChangeRenderScope < hdng.diagrams.FeatureDirective
    %ChangeRenderScope Summary.
    %   Detailed description 
    
    properties
        type
        name
        arguments
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = ChangeRenderScope(varargin)

            obj@hdng.diagrams.FeatureDirective(varargin{:});

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'type')
                options.type = 'undefined';
            end

            if ~isfield(options, 'name')
                options.name = 'unnamed';
            end

            if ~isfield(options, 'style_definitions')
                options.style_definitions = {};
            end

            obj.type = options.type; options = rmfield(options, 'type');
            obj.name = options.name; options = rmfield(options, 'name');
            obj.arguments = options;
        end

        function result = format_string(~, string, feature)

            if isempty(feature.data_scope)
                result = string;
                return;
            end

            expr = '<(?<attribute>\w+)(?<specifier>:\w+)?>';
            
            [extents, tokens]= ...
                regexp(string, expr, 'tokenExtents', 'names');

            previous = 1;
            result = '';

            for index=1:numel(tokens)
                attribute = tokens(index).attribute;
                specifier = tokens(index).specifier;

                ranges = extents{index};
                range = [ranges(1, 1), max(ranges(1, 2), ranges(2, 2))];

                result = [result, string(previous:range(1) - 2)]; %#ok<AGROW>
                previous = range(2) + 2;
                
                if isfield(feature.data_scope.attributes, attribute)
                    attribute = feature.data_scope.attributes.(attribute);
                end

                if ~isempty(specifier)
                    specifier = specifier(2:end);
                    attribute = sprintf(specifier, attribute);
                end

                result = [result, attribute]; %#ok<AGROW>
            end

            result = [result, string(previous:end)];
        end

        function invoke_in_render(obj, feature, context)
            %{ 
                n_visit, render_context, base, parents, siblings
            %}
            
            if context.n_visit == 1
                
                scope_name = obj.format_string(obj.name, feature);
                args = hdng.utilities.struct_to_name_value_sequence(obj.arguments);
                
                context.render_context.enter_scope(obj.type, scope_name, args{:});

            elseif feature.is_last_visit(context.n_visit)

                context.render_context.exit_scope();
            end
        end
    end
end
