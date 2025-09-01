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

classdef Quantile < hdng.diagrams.Generator
    %Quantile Summary.
    %   Detailed description 
    
    properties
        field
        p_values
        names
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Quantile(varargin)

            obj = obj@hdng.diagrams.Generator();

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'field')
                options.field = 'value';
            end

            if ~isfield(options, 'p_values')
                options.p_values = [0.25, 0.5, 0.75];
            end

            if ~isfield(options, 'names')
                options.names = {};

                for index=1:numel(options.p_values)
                    p = options.p_values(index);
                    options.names{index} = sprintf('p%3.f', p * 1000);
                end
            end
            
            obj.field = options.field;
            obj.p_values = options.p_values;
            obj.names = options.names;
        end

        function children = apply(obj, scope, child_data_level)

            q_values = quantile(scope.records.fields.(obj.field), obj.p_values);
            
            result = struct();

            for index=1:numel(obj.names)
                name = obj.names{index};
                result.(name) = q_values(index);
            end

            result = hdng.utilities.RecordTable(result);
            
            scope = hdng.diagrams.DataScope(child_data_level, scope.attributes, result);
            
            children = {scope};
        end
    end
end
