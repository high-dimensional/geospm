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

classdef Table < handle
    
    %Table [Description]
    %
    
    properties
    end
    
    properties (Dependent, Transient)
        row_labels
        column_labels
        
        row_header_labels
        column_header_labels
        
        attachment_keys
    end
    
    properties (GetAccess=private, SetAccess=private, Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
       size_
       spans_
       
       row_label_map_
       column_label_map_
       attachment_map_
    end
    
    methods
        
        function result = get.row_labels(obj)
            result = obj.row_label_map_.keys();
        end
        
        function result = get.column_labels(obj)
            result = obj.column_label_map_.keys();
        end
        
        function result = get.row_header_labels(obj)
            result = obj.header_labels(obj.size_(1), obj.row_label_map_);
        end
        
        function result = get.column_header_labels(obj)
            result = obj.header_labels(obj.size_(1), obj.column_label_map_);
        end
        
        function result = get.attachment_keys(obj)
            result = obj.attachment_map_.keys();
        end
        
        function result = size(obj)
            result = obj.size_;
        end
        
        function obj = Table()
            obj.size_ = [0, 0];
            obj.spans_ = {};
            
            obj.row_label_map_ = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.column_label_map_ = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.attachment_map_ = containers.Map('KeyType', 'char', 'ValueType', 'int64');
        end
        
        function result = end(obj, k, ~)
            
            result = obj.size_(k);
            %result = builtin('end', obj, k, n);
        end
        
        function varargout = subsref(obj,s)
            
           switch s(1).type
               
              case '()'
                 
                 if numel(s(1).subs) < 2 || numel(s(1).subs) > 3
                     error('hdng.documents.Table(): Requires (row(s), column(s)) and optional attachment subscripts.');
                 end
                 
                 row_specifiers = s(1).subs{1};
                 column_specifiers = s(1).subs{2};
                 attachment = '';
                 
                 if numel(s(1).subs) == 3
                     attachment = s(1).subs{3};
                 end
                 
                 
                 result = obj.at_specifiers(row_specifiers, column_specifiers, attachment);
                 
                 if numel(s) > 1
                    varargout = {subsref(result, s(2:end))};
                 else
                    varargout = {result};
                 end
                 
              otherwise
              	 [varargout{1:nargout}] = builtin('subsref', obj, s);
           end
        end
        
        function obj = subsasgn(obj, s, varargin)

           switch s(1).type
               
              case '()'
                  
                 if numel(s) ~= 1
                     error('hdng.documents.Table(): Nested assignment not possible.');
                 end
                 
                 if numel(varargin) ~= 1
                     error('hdng.documents.Table(): Multiple assignment not possible.');
                 end
                 
                 if numel(s(1).subs) < 2 || numel(s(1).subs) > 3
                     error('hdng.documents.Table(): Requires (row(s), column(s)) and optional attachment subscripts.');
                 end
                 
                 row_specifiers = s(1).subs{1};
                 column_specifiers = s(1).subs{2};
                 attachment = '';
                 
                 if numel(s(1).subs) == 3
                     attachment = s(1).subs{3};
                 end
                 
                 obj.assign_specifiers(row_specifiers, column_specifiers, varargin{:}, isempty(attachment), attachment);
                 
              otherwise
                 obj = builtin('subsasgn', obj, s, varargin);
           end
        end
    end
    
    methods (Access=protected)
        
        function result = header_labels(~, length, label_map)
            
            result = cell(length, 1);
            
            labels = label_map.keys();
            
            label_indices = zeros(numel(labels), 1);
            
            for i=1:numel(labels)
                label = labels{i};
                label_indices(i) = label_map(label);
            end
            
            [label_indices, label_order] = sort(label_indices);
            labels = labels(label_order);
            
            for i=1:numel(labels)
                label = labels{i};
                index = label_indices(i);
                result{index} = label;
            end
        end
        
        function [row_indices, column_indices] = ...
                resolve_specifiers(obj, row_specifiers, column_specifiers, do_insert)
            
            if ~exist('do_insert', 'var')
                do_insert = false;
            end
            
            if ischar(row_specifiers)

                if strcmp(row_specifiers, ':')
                    row_specifiers = num2cell(1:obj.size_(1));
                else
                    row_specifiers = {row_specifiers};
                end
                
            elseif isnumeric(row_specifiers)
                row_specifiers = num2cell(row_specifiers);
            end
            
            if ischar(column_specifiers)

                if strcmp(column_specifiers, ':')
                    column_specifiers = num2cell(1:obj.size_(2));
                else
                    column_specifiers = {column_specifiers};
                end
                
            elseif isnumeric(column_specifiers)
                column_specifiers = num2cell(column_specifiers);
            end
            
            specifiers = [row_specifiers(:); column_specifiers(:)];
            indices = zeros(size(specifiers));
            
            N_row_specifiers = numel(row_specifiers);
            
            new_size = obj.size_;
            
            for i=1:numel(specifiers)
                
                specifier = specifiers{i};
                
                if ischar(specifier)
                    if i <= N_row_specifiers
                        label_map = obj.row_label_map_;
                        d = 1;
                    else
                        label_map = obj.column_label_map_;
                        d = 2;
                    end
                    
                    if ~isKey(label_map, specifier)
                        if do_insert
                            new_size(d) = new_size(d) + 1;
                            index = new_size(d);
                            label_map(specifier) = index; %#ok<NASGU>
                        else
                            index = 0;
                        end
                    else
                        index = label_map(specifier);
                    end
                    
                    indices(i) = index;
                    
                elseif isnumeric(specifier)
                    indices(i) = specifier;
                else
                    
                    if i <= N_row_specifiers
                        error('Table.resolve_specifiers(): Invalid row specifier type %s.', class(specifier));
                    else
                        error('Table.resolve_specifiers(): Invalid column specifier type %s.', class(specifier));
                    end
                end
            end
            
            row_indices = indices(1:N_row_specifiers);
            column_indices = indices(N_row_specifiers + 1:end);
        end
        
        function values = at_indices(obj, row_indices, column_indices, attachment)
            
            if ~exist('attachment', 'var')
                attachment = '';
            end
            
            values = cell(numel(row_indices), numel(column_indices));
            
            for i=1:numel(row_indices)
                
                row_index = row_indices(i);
                
                for j=1:numel(column_indices)
                    
                    column_index = column_indices(j);
                    
                    value = obj.load_span_element(row_index, column_index, attachment);
                    values{i, j} = value;
                end
            end
            
            if numel(values) == 1
                values = values{1};
            end
        end
        
        function assign_indices(obj, row_indices, column_indices, values, do_insert, attachment)
            
            if ~exist('do_insert', 'var')
                do_insert = false;
            end
            
            if ~exist('attachment', 'var')
                attachment = '';
            end
            
            [row_indices, row_order] = sort(row_indices);
            [column_indices, column_order] = sort(column_indices);
            
            invalid_rows = row_indices <= 0;
            invalid_columns = column_indices <= 0;
            
            if any(invalid_rows)
                error('Table.assign_indices(): Invalid row indices.');
            end
               
            if any(invalid_columns)
                error('Table.assign_indices(): Invalid column indices.');
            end
            
            if ~iscell(values) && numel(row_indices) == 1 && numel(column_indices) == 1
                values = {values};
            end
            
            values = values(row_order, column_order);
            
            row_insertions = row_indices > obj.size_(1);
            column_insertions = column_indices > obj.size_(2);
            
            row_insertions = row_indices(find(row_insertions, 1):end);
            
            if ~isempty(row_insertions)
                
                if ~do_insert
                    error('Table.assign_indices(): Non-existing row indices.');
                end
                
                for i=1:numel(row_insertions)
                    index = row_insertions(i);
                    obj.insert_span(1, index);
                end
            end
            
            column_insertions = column_indices(find(column_insertions, 1):end);
            
            if ~isempty(column_insertions)
                
                if ~do_insert
                    error('Table.assign_indices(): Non-existing column indices.');
                end
                
                for i=1:numel(column_insertions)
                    index = column_insertions(i);
                    obj.insert_span(2, index);
                end
            end
            
            for i=1:numel(row_indices)
                
                row_index = row_indices(i);
                
                for j=1:numel(column_indices)
                    
                    column_index = column_indices(j);
                    
                    value = values{i, j};
                    obj.store_span_element(row_index, column_index, value, attachment);
                end
            end
        end
        
        
        function values = at_specifiers(obj, row_specifiers, column_specifiers, attachment)
            
            if ~exist('attachment', 'var')
                attachment = '';
            end
            
            [row_indices, column_indices] = ...
                obj.resolve_specifiers(row_specifiers, column_specifiers, false);
            
            values = obj.at_indices(row_indices, column_indices, attachment);
        end
        
        function assign_specifiers(obj, row_specifiers, column_specifiers, values, do_insert, attachment)
            
            if ~exist('do_insert', 'var')
                do_insert = false;
            end
            
            if ~exist('attachment', 'var')
                attachment = '';
            end
            
            [row_indices, column_indices] = ...
                obj.resolve_specifiers(row_specifiers, column_specifiers, do_insert);
            
            obj.assign_indices(row_indices, column_indices, values, do_insert, attachment);
        end
        
        function element = create_element(~)
            element = {[], struct()};
        end
        
        
        function element = load_span_element(obj, span_index, element_index, attachment)
            span = obj.spans_{span_index};
            element_wrapper = span{element_index};
            
            if isempty(attachment)
                element = element_wrapper{1};
            elseif isfield(element_wrapper{2}, attachment)
                element = element_wrapper{2}.(attachment);
            else
                element = [];
            end
        end
        
        function store_span_element(obj, span_index, element_index, element, attachment)
            
            span = obj.spans_{span_index};
            element_wrapper = span{element_index};
            
            if isempty(attachment)
                element_wrapper{1} = element;
            else
                
                if ~isfield(element_wrapper{2}, attachment)
                    if ~isKey(obj.attachment_map_, attachment)
                        obj.attachment_map_(attachment) = 0;
                    end
                    
                    obj.attachment_map_(attachment) = obj.attachment_map_(attachment) + 1;
                end
                    
                element_wrapper{2}.(attachment) = element;
            end
            
            span{element_index} = element_wrapper;
            obj.spans_{span_index} = span;
        end
        
        function insert_span_element(obj, span_index, element_index)
            span = obj.spans_{span_index};
            
            if element_index <= numel(span)
                element = obj.create_element();
                span = [span(1:index - 1) {element} span(index:end)];
            else
                N_extra = element_index - numel(span);
                span = [span cell(1, N_extra)];
                
                for i=element_index - N_extra + 1:element_index
                    span{i} = obj.create_element();
                end
            end
            
            obj.spans_{span_index} = span;
        end
        
        
        function span = create_span(obj)
            span = cell(1, obj.size_(2));
            
            for i=1:numel(span)
                span{i} = obj.create_element();
            end
        end
        
        function insert_span(obj, dimension, index)
                
            if index <= 0
                error('Table.insert_span(): Invalid index: %d', index);
            end

            if dimension == 1
                
                if index <= numel(obj.spans_)
                    
                    N_extra = 1;
                    
                    span = obj.create_span();
                    obj.spans_ = [obj.spans_(1:index - 1); {span}; obj.spans_(index:end)];
                    
                    obj.size_(1) = obj.size_(1) + N_extra;
                else
                    
                    N_extra = index - numel(obj.spans_);
                    
                    obj.spans_ = [obj.spans_; cell(N_extra, 1)];

                    for i=index - N_extra + 1:index
                        span = obj.create_span();
                        obj.spans_{i} = span;
                    end
                    
                    obj.size_(1) = obj.size_(1) + N_extra;
                end
                
            elseif dimension == 2
                
                
                if index <= obj.size_(2)
                    N_extra = 1;
                else
                    N_extra = index - obj.size_(2);
                end
                
                for i=1:obj.size_(1)
                    obj.insert_span_element(i, index);
                end
                
                obj.size_(2) = obj.size_(2) + N_extra;
            else
                error('Table.insert_span(): Invalid span dimension: %d', dimension);
            end
        end
        
        
    end
    
    methods (Static, Access=public)
    end
    
end
