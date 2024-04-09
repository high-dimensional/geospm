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

classdef TabularData < handle
    %TabularData A base class for data arranged in rows.
    %
    
    properties (Dependent, Transient)
        
        N % number of rows
        C % number of columns

        row_attachment_names
        column_attachment_names
    end
    
    properties (GetAccess = private, SetAccess = private)
        N_
        C_
    end
    
    methods
        
        function value = get.N(obj)
            value = obj.N_;
        end
        
        function value = get.C(obj)
            value = obj.C_;
        end
        
        function result = get.row_attachment_names(obj)
            result = obj.access_row_attachment_names();
        end

        function result = get.column_attachment_names(obj)
            result = obj.access_column_attachment_names();
        end
        

        function obj = TabularData(N, C)
            %Construct a TabularData object with the given number of rows.
            % N ? The number of rows in the data.
            
            if ~exist('N', 'var') || isempty(N)
                N = 0;
            end

            if ~exist('C', 'var') || isempty(C)
                C = 0;
            end
            
            obj.N_ = N;
            obj.C_ = C;
        end
        
        function result = row_attachments(obj, row_selection)
            
            if ~exist('row_selection', 'var')
                row_selection = ones(obj.N, 1, 'logical');
            end
           
            names = obj.row_attachment_names;
            result = struct();
            
            for index=1:numel(names)
                name = names{index};
                result.(name) = obj.(name)(row_selection);
            end
        end
        
        function result = column_attachments(obj, column_selection)
            
            if ~exist('column_selection', 'var')
                column_selection = ones(1, obj.C, 'logical');
            end
            
            names = obj.column_attachment_names;
            result = struct();
            
            for index=1:numel(names)
                name = names{index};
                result.(name) = obj.(name)(column_selection);
            end
        end
        
        function assign_row_attachments(obj, from, row_map)
            
            % assign_row_attachments  Assign selected row attachments of from to this object using the row map
            %   from - a data object from which row attachments are to be assigned
            %   row_map - each entry maps the corresponding row in this object to a row in from
            
            if ~exist('row_map', 'var') || isempty(row_map)
                % By default, select every row in from
                row_map = 1:from.N;
            end
            
            row_attachments = from.row_attachments;
            
            names = fieldnames(row_attachments);

            for index=1:numel(names)
                name = names{index};

                if ~isprop(obj, name)
                    continue;
                end

                obj.assign_row_attachment_impl(name, row_attachments, row_map);
            end
        end

        function assign_column_attachments(obj, from, column_map)
            % assign_column_attachments  Assign selected column attachments of from to this object using the column map
            %   from - a data object from which column attachments are to be assigned
            %   column_map - each entry maps the corresponding row in this object to a row in from
            
            if ~exist('column_map', 'var') || isempty(column_map)
                column_map = 1:obj.C;
            end
            
            column_attachments = from.column_attachments;
            
            names = fieldnames(column_attachments);
            
            for index=1:numel(names)
                name = names{index};

                if ~isprop(obj, name)
                    continue;
                end
                
                obj.assign_column_attachment_impl(name, column_attachments, column_map);
            end
        end
        
        function result = select(obj, row_selection, column_selection, transform)
        
            if ~exist('row_selection', 'var')
                row_selection = [];
            end
            
            if isempty(row_selection)
                row_selection = 1:obj.N;
            end
            
            if ~exist('column_selection', 'var')
                column_selection = [];
            end
            
            if isempty(column_selection)
                column_selection = 1:obj.C;
            end
            
            if ~exist('transform', 'var')
                transform = @(arguments) arguments;
            end
            
            [row_selection, column_selection] = obj.normalise_selection(row_selection, column_selection);
            
            result = obj.clone(row_selection, column_selection, transform);
        end


        
        function [result, row_map, column_map] = clone(obj, row_selection, column_selection, transform)
            % clone  Clone this data object using the selected rows, columns and transform.
            %   row_selection - a numeric vector of row indices
            %   column_selection - a numeric vector of column indices
            %   transform - a function handle that expects an argument struct and returns a result struct
            %
            %   The transform function is passed a struct with at least the
            %   following fields:
            %
            %   row_map - a vector of row indices: each entry maps a row in
            %   the cloned object to a row in the original object
            %   column_map - a vector of column indices: each entry maps a
            %   column in the cloned object to a column in the original
            %   object
            %
            %   A zero index in either the row or column map specified that
            %   the corresponding row or column in the cloned object keeps
            %   its previous attachment
            
            
            if isempty(row_selection)
                row_selection = 1:obj.N;
            end
            
            if isempty(column_selection)
                column_selection = 1:obj.C;
            end

            args = obj.define_clone_arguments(row_selection, column_selection);
            args = obj.apply_clone_transform(args, transform);
            
            result = obj.create_clone_from_arguments(args);
            
            row_map = args.row_map;
            column_map = args.column_map;
            
            result.assign_row_attachments(obj, row_map);
            result.assign_column_attachments(obj, column_map);
        end
    end
    
    methods (Access = protected)
        
        
        function [row_selection, column_selection] = normalise_selection(obj, row_selection, column_selection)
            % Normalises the arguments to arrays of row and column indices

            if ~exist('row_selection', 'var') || isempty(row_selection)
                row_selection = 1:obj.N;
            end

            if ~exist('column_selection', 'var') || isempty(column_selection)
                column_selection = 1:obj.C;
            end
            
            if ~isnumeric(row_selection)
                
                if islogical(row_selection)
                    if numel(row_selection) ~= obj.N
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
                    tmp = (1:obj.N)';
                    tmp = tmp(row_selection); %#ok<NASGU>
                    clear('tmp');
                catch
                    error('normalise_selection(): One or more row selection indices are out of bounds.');
                end
            end
            
            
            if ~isnumeric(column_selection)
                
                if islogical(column_selection)
                    if numel(column_selection) ~= obj.C
                        error('normalise_selection(): The length of a logical column selection vector must be equal to the number of columns.');
                    end

                    column_selection = find(column_selection);
                    column_selection = column_selection(:);
                else
                    error('normalise_selection(): column selection vector must be a numeric or logical array.');
                end
            else
                column_selection = column_selection(:);

                try
                    tmp = 1:obj.C;
                    tmp = tmp(column_selection); %#ok<NASGU>
                    clear('tmp');
                catch
                    error('normalise_selection(): One or more column selection indices are out of bounds.');
                end
            end
        end
        
        function result = access_row_attachment_names(~)
            result = {};
        end

        function result = access_column_attachment_names(~)
            result = {};
        end
        
        function assign_property(obj, name, values)
            obj.(name) = values;
        end

        function assign_row_attachment_impl(obj, name, from, row_map)
            
            from_values = from.(name);
            row_values = obj.(name);
            
            
            assign_rows = row_map ~= 0;
            assign_rows = assign_rows(1:min([size(row_values, 1), size(from_values, 1)]));
            from_rows = row_map(assign_rows);
            
            row_values(assign_rows, :) = from_values(from_rows, :);
            
            obj.assign_property(name, row_values);
        end
        
        function assign_column_attachment_impl(obj, name, from, column_map)
            
            from_values = from.(name);
            column_values = obj.(name);
            
            
            assign_columns = column_map ~= 0;
            assign_columns = assign_columns(1:min([size(column_values, 2), size(from_values, 2)]));
            from_columns = column_map(assign_columns);
            
            column_values(:, assign_columns) = from_values(:, from_columns);
            
            obj.assign_property(name, column_values);
        end
        

        function result = apply_clone_transform(~, arguments, transform)
            
            result = transform(arguments);
            
            names = fieldnames(arguments);
            
            for i=1:numel(names)
                
                name = names{i};
                
                if isfield(result, name)
                    continue;
                end
                
                result.(name) = arguments.(name);
            end
            
        end

        function result = define_clone_arguments(~, row_selection, column_selection)
            result = struct();
            result.row_map = row_selection;
            result.column_map = column_selection;
        end

        function result = create_clone_from_arguments(~, args) %#ok<INUSD>
            result = geospm.TabularData();
        end
    end
end
