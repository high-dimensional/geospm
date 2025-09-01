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

classdef Aggregate < hdng.diagrams.Generator
    %Aggregate Summary.
    %   Detailed description 
    
    %{
        
        field
        func
        arguments
        names

    %}

    properties
        output_mode
        specifiers
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Aggregate(output_mode, varargin)

            obj = obj@hdng.diagrams.Generator();

            obj.specifiers = varargin;
            obj.output_mode = output_mode;
        end

        function children = apply(obj, scope, child_data_level)
            
            record = struct();

            switch obj.output_mode

                case 'records'
            
                case 'attributes'

                    record = scope.attributes;

                otherwise
                    error('Aggregate:UnknownOutputMode', 'Output mode not known: %s', obj.output_mode);
            end
            
            for index=1:numel(obj.specifiers)
                specifier = obj.specifiers{index};
                func = obj.resolve_function(specifier);
                
                values = scope.records.fields.(specifier.field);
                values = func(specifier, values);
                
                for name_index=1:numel(specifier.names)
                    name = specifier.names{name_index};
                    record.(name) = values(:, name_index);
                end
            end

            switch obj.output_mode

                case 'records'

                    attributes = scope.attributes;
                    records = hdng.utilities.RecordTable(record);
            
                case 'attributes'

                    attributes = record;
                    records = hdng.utilities.RecordTable();

                otherwise
                    error('Aggregate:UnknownOutputMode', 'Output mode not known: %s', obj.output_mode);
            end

            scope = hdng.diagrams.DataScope(child_data_level, attributes, records);
            children = {scope};
        end
    end

    methods (Static, Access=public)
        
        function specifier = min(field, name)
            
            if ~exist('name', 'var')
                name = [field '_min'];
            end

            specifier = hdng.diagrams.generators.Aggregate.create_specifier( ...
                field, 'min', {name});
        end
        
        function specifier = max(field, name)

            if ~exist('name', 'var')
                name = [field '_max'];
            end

            specifier = hdng.diagrams.generators.Aggregate.create_specifier( ...
                field, 'max', {name});
        end
        
        function specifier = mean(field, name)

            if ~exist('name', 'var')
                name = [field '_mean'];
            end

            specifier = hdng.diagrams.generators.Aggregate.create_specifier( ...
                field, 'mean', {name});
        end
        
        function specifier = count(field, name)

            if ~exist('name', 'var')
                name = [field '_count'];
            end

            specifier = hdng.diagrams.generators.Aggregate.create_specifier( ...
                field, 'count', {name});
        end
        
        function specifier = quantile(field, p_values, names)

            if ~exist('names', 'var')
                
                names = {};

                for index=1:numel(p_values)
                    p = p_values(index);
                    names{index} = sprintf('%s_p%3.f', field, p * 1000); %#ok<AGROW>
                end
            end
            
            arguments = struct();
            arguments.p_values = p_values;

            specifier = hdng.diagrams.generators.Aggregate.create_specifier( ...
                field, 'quantile', names, arguments);
        end

    end

    methods (Static, Access=protected)
        
        function result = create_specifier(field, func, names, arguments)
            
            if ~exist('arguments', 'var')
                arguments = struct();
            end

            result = struct();
            
            result.field = field;
            result.func = func;
            result.arguments = arguments;
            result.names = names;
        end

        function result = resolve_function(specifier)
            result = str2func(['hdng.diagrams.generators.Aggregate.compute_' specifier.func]);
        end

        function result = compute_min(~, values)
            result = min(values(:));
        end
    
        function result = compute_max(~, values)
            result = max(values(:));
        end
    
        function result = compute_mean(~, values)
            result = mean(values(:));
        end
    
        function result = compute_count(~, values)
            result = numel(values(:));
        end
    
        function result = compute_quantile(specifier, values)
            result = quantile(values, specifier.arguments.p_values);
        end
    
    end
end
