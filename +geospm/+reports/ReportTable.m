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

classdef ReportTable
    
    %ReportTable 
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
        
        function obj = ReportTable(contents, length)

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
                obj1 = geospm.reports.ReportTable;
            end

            if numel(obj2) == 0
                obj2 = geospm.reports.ReportTable;
            end

            tmp_contents = hdng.utilities.concatenate_tabular_structs(obj1.contents, obj2.contents, obj1.length, obj2.length);
            result = geospm.reports.ReportTable(tmp_contents, obj1.length + obj2.length);
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

            result = geospm.reports.ReportTable(tmp_contents, len);
        end

        function result = select_matching_rows(obj, match_fn)

            selector = match_fn(obj);

            tmp_contents = struct();
            
            names = obj.fieldnames;

            for index=1:numel(names)
                name = names{index};
                tmp_contents.(name) = obj.contents.(name)(selector);
            end

            result = geospm.reports.ReportTable(tmp_contents);
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

    end
end
