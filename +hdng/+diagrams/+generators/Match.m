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

classdef Match < hdng.diagrams.Generator
    %Match Summary.
    %   Detailed description 
    
    properties
        fields
        match_values
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Match(varargin)

            obj = obj@hdng.diagrams.Generator();

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'fields')
                options.fields = {};
            end

            if ~isfield(options, 'match_values')
                options.match_values = struct();
            end

            obj.fields = options.fields;
            obj.match_values = options.match_values;
        end

        function children = apply(obj, scope, child_data_level)

            queue = {{scope.records, scope.attributes}};

            for f_index=1:numel(obj.fields)
                
                field = obj.fields{f_index};
                field_match_values = hdng.utilities.struct_get_value_at_path(obj.match_values, field, {});
                field_match_values = field_match_values(:)';
                
                next_queue = {};

                while ~isempty(queue)
                    
                    state = queue{1}; queue = queue(2:end);
                    records = state{1};
                    attributes = state{2};
                    
                    match_fn = @hdng.diagrams.generators.Match.cross_compare;

                    matched_records = records.select_matching_rows(@(x) any(match_fn(x.fields.(field), field_match_values), 2));
                    
                    next_queue{end + 1} = {matched_records, attributes}; %#ok<AGROW>
                end

                queue = next_queue;
            end

            children = cell(numel(queue), 1);
    
            for index=1:numel(queue)
                
                state = queue{index};
                records = state{1};
                attributes = state{2};
                scope = hdng.diagrams.DataScope(child_data_level, attributes, records);
                children{index} = scope;
            end
        end
    end

    methods (Static)
            
        function result = cross_compare(vertical, horizontal)
            
            if iscell(vertical)

                result = zeros([numel(vertical), numel(horizontal)], 'logical');

                for index=1:numel(vertical)
                    value = vertical{index};
                    result(index, :) = strcmp(value, horizontal);
                end
            else
                result = vertical == horizontal;
            end
        
        end
    
    end

end
