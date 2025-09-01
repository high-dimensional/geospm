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

classdef Augment < hdng.diagrams.Generator
    %Augment Summary.
    %   Detailed description 
    
    %{
        name
        func
        arguments

    %}

    properties
        specifiers
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Augment(varargin)

            obj = obj@hdng.diagrams.Generator();

            obj.specifiers = varargin;
        end
        
        function children = apply(obj, scope, child_data_level)
            
            result = hdng.utilities.RecordTable(struct());
            
            for r_index=1:scope.records.length

                record = scope.records(r_index);

                for index=1:numel(obj.specifiers)
                    specifier = obj.specifiers{index};
                    func = obj.resolve_function(specifier);
                    
                    record.(specifier.name) = func(specifier, record);
                end
                
                result = result + hdng.utilities.RecordTable(record, 1);
            end
            
            scope = hdng.diagrams.DataScope(child_data_level, scope.attributes, result);
            children = {scope};
        end
    end

    methods (Static, Access=public)
        
        function specifier = map(field, scale, name)
            
            args = struct();
            args.field = field;
            args.scale = scale;

            specifier = hdng.diagrams.generators.Augment.create_specifier( ...
                name, 'map', args);
        end

    end

    methods (Static, Access=protected)
        
        function result = create_specifier(name, func, arguments)
            
            if ~exist('arguments', 'var')
                arguments = struct();
            end

            result = struct();
            
            result.name = name;
            result.func = func;
            result.arguments = arguments;
        end

        function result = resolve_function(specifier)
            result = str2func(['hdng.diagrams.generators.Augment.compute_' specifier.func]);
        end

        function result = compute_map(specifier, record)
            value = record.(specifier.arguments.field);
            
            if ~iscell(value)
                value = {value};
            end
            
            result = specifier.arguments.scale.apply(value);
            result = result{1};
        end
    
    end
end
