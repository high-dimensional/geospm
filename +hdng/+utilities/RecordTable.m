% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2020,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef RecordTable
    
    %RecordTable 
    %

    properties (GetAccess=public, SetAccess=private)
        length
    end

    properties (GetAccess=private, SetAccess=private)
        contents
    end

    properties (Dependent, Transient)
        fields
        fieldnames
    end
    
    methods

        function result = get.fields(obj)
            result = obj.contents;
        end

        function result = get.fieldnames(obj)
            result = fieldnames(obj.contents); %#ok<CPROP>
        end
        
        function obj = RecordTable(contents, length)

            if ~exist('contents', 'var')
                contents = struct();
            end

            if ~exist('length', 'var')

                names = fieldnames(contents);

                if ~isempty(names)                
                    lengths = cellfun(@(x) numel(contents.(x)), names, 'UniformOutput', true);
                    length = max(lengths);
                else
                    length = 0;
                end
            end

            obj.contents = contents;
            obj.length = length;
        end

        function result = numel(obj)
            result = obj.length;
        end
            
        function result = plus(obj1, obj2)

            if numel(obj1) == 0
                obj1 = hdng.utilities.RecordTable;
            end

            if numel(obj2) == 0
                obj2 = hdng.utilities.RecordTable;
            end

            tmp_contents = hdng.utilities.concatenate_tabular_structs(obj1.contents, obj2.contents, obj1.length, obj2.length);
            result = hdng.utilities.RecordTable(tmp_contents, obj1.length + obj2.length);
        end

        function result = assign_field(obj, name, values)
        
            n_values = numel(values);

            len = obj.length;

            if len == 0
                len = n_values;
            end

            if n_values ~= len
                if n_values ~= 1
                    error('Number of field values must match length of ReportTable.');
                end

                values = repmat(values, obj.length, 1);
            end

            tmp_contents = obj.contents;
            tmp_contents.(name) = values;

            result = hdng.utilities.RecordTable(tmp_contents, len);
        end

        function result = remove_field(obj, name)
            
            result = obj;
            result.contents = rmfield(result.contents, name);

            if isempty(result.fieldnames)
                result.length = 0;
            end
        end

        function result = select_matching_rows(obj, match_fn, selector)
            
            if ~isempty(match_fn)
                selector = match_fn(obj);
            end

            tmp_contents = struct();
            
            names = obj.fieldnames;

            for index=1:numel(names)
                name = names{index};
                tmp_contents.(name) = obj.contents.(name)(selector);
            end

            result = hdng.utilities.RecordTable(tmp_contents);
        end
        
        function [result, values] = group_rows_by_field(obj, name, match_values)
            
            result = cell(numel(obj), 1);
            values = cell(numel(obj), 1);

            blank = zeros(numel(obj), 1, 'logical');
            available = ones(numel(obj), 1, 'logical');

            index = 1;
            value_index = 1;

            while index <= numel(obj)
                
                value = obj.contents.(name)(index);

                selector = blank;
                
                if ~iscell(obj.contents.(name))
                    selector(index:end) = value == obj.contents.(name)(index:end);
                else
                    value = value{1};
                    selector(index:end) = cellfun(@(x) isequal(x, value), obj.contents.(name)(index:end), 'UniformOutput', true);
                end

                available(index:end) = available(index:end) & ~selector(index:end);
                
                result{value_index} = obj.select_matching_rows([], selector);
                values{value_index} = value;

                value_index = value_index + 1;

                index = index + find(available(index:end), 1) - 1;
            end

            result = result(1:value_index - 1);
            values = values(1:value_index - 1);

            if exist('match_values', 'var') && ~isempty(match_values)
                
                matched_results = cell.empty;

                for index=1:numel(match_values)
                    match_value = match_values(index);
                    
                    value_index = find(values == match_value, 1);
                    
                    if ~isempty(value_index)
                        matched_results{end + 1} = result{value_index}; %#ok<AGROW>
                    else
                        matched_results{end + 1} = []; %#ok<AGROW>
                    end
                end
                
                result = matched_results;
                values = match_values;
            end
        end


        function [result, column_names] = as_cells(obj, varargin)
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'field_order')
                options.field_order = obj.fieldnames;
            end
            
            result = cell(obj.length, numel(options.field_order));

            for index=1:numel(options.field_order)
                
                name = options.field_order{index};

                if ~isfield(obj.contents, name)
                    continue;
                end

                values = obj.contents.(name);

                if ~iscell(values)

                    for k=1:numel(values)
                        result{k, index} = values(k);
                    end
                else
                    result(:, index) = values; 
                end
            end

            column_names = options.field_order;
        end


        function write(obj, filename, varargin)
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'field_order')
                options.field_order = [];
            end

            [cell_values, column_names] = obj.as_cells('field_order', options.field_order);

            writecell([column_names; cell_values], filename);
        end

        function n = numArgumentsFromSubscript(obj, s, indexingContext)
           
            switch s(1).type
            
                case {'()'}

                    if indexingContext == matlab.mixin.util.IndexingContext.Expression
                        n = 1;
                    else
                        n = builtin('numArgumentsFromSubscript', obj, s, indexingContext);
                    end

                otherwise
                    n = builtin('numArgumentsFromSubscript', obj, s, indexingContext);
            end
        end
        
        function varargout = subsref(obj,s)
            
           switch s(1).type
               
              case '()'
                 
                 if numel(s(1).subs) > 1
                     error('hdng.utilities.RecordTable: Only one subscript argument is supported.');
                 end

                 key = s(1).subs{1};

                 result = struct();

                 for index=1:numel(obj.fieldnames)
                    name = obj.fieldnames{index};
                    values = obj.contents.(name);
                    result.(name) = values(key);
                 end

                 varargout = {result};
                 
              otherwise
              	 [varargout{1:nargout}] = builtin('subsref',obj,s);
           end
        end

    end
end
