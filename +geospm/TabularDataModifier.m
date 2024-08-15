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

classdef TabularDataModifier < handle
    %TabularDataModifier A class that provides operations for modifying
    % a TabularData specifier.
    %
    
    methods
        
        function obj = TabularDataModifier()
        end
        
        function specifier = insert_rows_op(obj, specifier, index, data, per_row)
            
            if ~exist('per_row', 'var')
                per_row = struct();
            end

            K = size(data, 1);

            specifier.data = [specifier.data(1:index - 1, :); 
                              data;
                              specifier.data(index:end, :)];

            names = fieldnames(specifier.per_row);

            for i=1:numel(names)
                name = names{i};
                values = specifier.per_row.(name);
                
                if isfield(per_row, name)
                    insertion_values = per_row.(name);
                else
                    insertion_values = obj.generate_row_values(specifier, name, index, K);
                end

                if numel(insertion_values) ~= K
                    error('Number of insertion values for row attachment ''%s'' does not match insertion data.', name);
                end

                specifier.per_row.(name) = [values(1:index - 1); 
                                            insertion_values;
                                            values(index:end)];
            end

            %specifier.N = size(specifier.data, 1);
        end

        function specifier = insert_columns_op(obj, specifier, index, data, per_column)

            if ~exist('per_column', 'var')
                per_column = struct();
            end
            
            K = size(data, 2);

            specifier.data = [specifier.data(:, 1:index - 1), ...
                              data, ...
                              specifier.data(:, index:end)];

            names = fieldnames(specifier.per_column);

            for i=1:numel(names)
                name = names{i};
                values = specifier.per_column.(name);
                
                if isfield(per_column, name)
                    insertion_values = per_column.(name);
                else
                    insertion_values = obj.generate_column_values(specifier, name, index, K);
                end

                if numel(insertion_values) ~= K
                    error('Number of insertion values for column attachment ''%s'' does not match insertion data.', name);
                end

                specifier.per_column.(name) = [values(1:index - 1), ...
                                               insertion_values, ...
                                               values(index:end)];

            end

            %specifier.C = size(specifier.data, 2);
        end

        function specifier = select_op(obj, specifier, row_selection, column_selection)
            
            N = size(specifier.data, 1);
            C = size(specifier.data, 2);

            [row_indices, column_indices] = obj.normalise_selection(N, C, row_selection, column_selection);
            
            specifier.data = specifier.data(row_indices, column_indices);

            names = fieldnames(specifier.per_row);
            
            for i=1:numel(names)
                name = names{i};
                values = specifier.per_row.(name);
                specifier.per_row.(name) = values(row_indices);
            end

            names = fieldnames(specifier.per_column);
            
            for i=1:numel(names)
                name = names{i};
                values = specifier.per_column.(name);
                specifier.per_column.(name) = values(column_indices);
            end

            %specifier.N = size(specifier.data, 1);
            %specifier.C = size(specifier.data, 2);
        end

        function specifier = delete_op(~, specifier, row_indices, column_indices)

            row_selector = ones(size(specifier.data, 1), 1, 'logical');
            row_selector(row_indices) = 0;

            col_selector = ones(size(specifier.data, 2), 1, 'logical');
            col_selector(column_indices) = 0;

            specifier.data = specifier.data(row_selector, col_selector);

            names = fieldnames(specifier.per_row);
            
            for i=1:numel(names)
                name = names{i};
                values = specifier.per_row.(name);
                specifier.per_row.(name) = values(row_selector);
            end

            names = fieldnames(specifier.per_column);
            
            for i=1:numel(names)
                name = names{i};
                values = specifier.per_column.(name);
                specifier.per_column.(name) = values(col_selector);
            end

            %specifier.N = size(specifier.data, 1);
            %specifier.C = size(specifier.data, 2);
        end

        function specifier = permutate_op(~, specifier, row_permutation, column_permutation)
            
            if isempty(row_permutation)
                row_permutation = 1:size(specifier.data, 1);
            end

            if isempty(column_permutation)
                column_permutation = 1:size(specifier.data, 2);
            end

            specifier.data = specifier.data(row_permutation, column_permutation);
            
            names = fieldnames(specifier.per_row);
            
            for i=1:numel(names)
                name = names{i};
                values = specifier.per_row.(name);
                specifier.per_row.(name) = values(row_permutation);
            end

            names = fieldnames(specifier.per_column);
            
            for i=1:numel(names)
                name = names{i};
                values = specifier.per_column.(name);
                specifier.per_column.(name) = values(column_permutation);
            end
        end
        
        function result = generate_row_values(~, specifier, name, index, count) %#ok<INUSD>
            
            values = specifier.per_row.(name);
            
            if isnumeric(values)
                result = zeros(count, 1, class(values));
            elseif ischar(values)
                result = char(repelem(32, count));
            elseif iscell(values)
                result = cell(count, 1);
            else
                error('Unsupported row attachment type.');
            end
        end
        
        function result = generate_column_values(obj, specifier, name, index, count) %#ok<INUSD>
            
            values = specifier.per_column.(name);
            
            if isnumeric(values)
                result = zeros(1, count, class(values));
            elseif ischar(values)
                result = char(repelem(32, count));
            elseif iscell(values)
                result = cell(1, count);
            else
                error('Unsupported column attachment type.');
            end
        end
    end

    methods (Access=protected)

        function [row_selection, column_selection] = normalise_selection(~, N, C, row_selection, column_selection)
            % Normalises the arguments to arrays of row and column indices.
            % 

            if ~exist('row_selection', 'var') || isempty(row_selection)
                row_selection = 1:N;
            end

            if ~exist('column_selection', 'var') || isempty(column_selection)
                column_selection = 1:C;
            end
            
            if ~isnumeric(row_selection)
                
                if islogical(row_selection)
                    if numel(row_selection) ~= N
                        error('normalise_selection(): The length of a logical row selection vector must be equal to the number of observations.');
                    end

                    row_selection = find(row_selection);
                    row_selection = row_selection(:);
                else
                    error('normalise_selection(): row selection vector must be a numeric or logical array.');
                end
            else
                row_selection = row_selection(:);

                try
                    tmp = (1:N)';
                    tmp = tmp(row_selection); %#ok<NASGU>
                    clear('tmp');
                catch
                    error('normalise_selection(): One or more row selection indices are out of bounds.');
                end
            end
            
            
            if ~isnumeric(column_selection)
                
                if islogical(column_selection)
                    if numel(column_selection) ~= C
                        error('normalise_selection(): The length of a logical column selection vector must be equal to the number of columns.');
                    end

                    column_selection = find(column_selection);
                    column_selection = column_selection(:);
                else
                    error('normalise_selection(): column selection vector must be a numeric or logical array.');
                end
            else
                column_selection = column_selection(:)';

                try
                    tmp = 1:C;
                    tmp = tmp(column_selection); %#ok<NASGU>
                    clear('tmp');
                catch
                    error('normalise_selection(): One or more column selection indices are out of bounds.');
                end
            end
        end
    end

end
