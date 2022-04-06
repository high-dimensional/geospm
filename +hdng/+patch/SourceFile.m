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

classdef SourceFile < handle
    %SourceFile Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name
        ext
    end
    
    properties (Dependent, Transient)
        functions
        function_names
        fragments
    end
    
    properties (Access=private)
        function_indices_
        functions_
        fragments_
    end
    
    
    methods
        
        function obj = SourceFile()
            
            obj.name = [];
            obj.ext = [];
            obj.fragments_ = {};
            
            obj.function_indices_ = [];
            
            obj.functions_ = struct();
        end
        
        function result = get.functions(obj)
            names = fieldnames(obj.functions_);
            result = cell(numel(names), 1);
            
            for i=1:numel(names)
                fname = names{i};
                f = obj.functions_.(fname);
                result{i} = f;
            end 
        end
        
        function result = get.function_names(obj)
            result = fieldnames(obj.functions_);
        end
        
        function result = function_for_name(obj, name)
            result = hdng.patch.Function.empty;
            
            if ~isfield(obj.functions_, name)
                return;
            end
            
            result = obj.functions_.(name);
        end
        
        function result = get.fragments(obj)
            result = obj.fragments_;
        end
        
        function parse(obj, path)
            
            [~, obj.name, obj.ext] = fileparts(path);
            
            string = hdng.utilities.load_text(path);

            match_expr = '(?<linebreak>(\r\n|\r|\n))|(?<comment>\%(\{|\}|[^\{\}\r\n]*))|function(((\s*\[[^]]+\s*|\s+[A-Za-z][A-Za-z_0-9]*\s*)=\s*)|\s+)(?<function>[A-Za-z][A-Za-z_0-9]*)(\s*\([^\)]*\))?';
            
            [starts, ends, token_matrix, tokens] = ...
                regexp(string, match_expr, 'start', 'end', 'names', 'tokens');
            
            function result = text_in_range(string, range)
                result = string(range(1):range(2));
            end
            
            function result = combine(varargin)
                result = varargin;
            end
            
            function result = arguments(x)
                result = x{end};
                
                if startsWith(result, '(')
                    result = result(2:end-1);
                    
                    args = split(result, ',');
                    
                    for k=1:numel(args)
                        args{k} = strip(args{k});
                    end
                    
                    result = { args };
                else
                    result = { {} };
                end
            end
            
            function result = returns(x)
                result = strip(x{1});
                
                if endsWith(result, '=' )
                    result = strip(result, '=');
                    result = strip(result);
                    
                    if startsWith(result, '[' )
                        result = result(2:end - 1);
                        returns = split(result, ',');
                    else
                        returns = { result };
                    end
                    
                    for k=1:numel(returns)
                        returns{k} = strip(returns{k});
                    end
                    
                    result = { returns };
                else
                    result = { {} };
                end
            end

            linebreaks = ~cellfun(@isempty, combine(token_matrix.linebreak));
            line_offsets = [0, ends(linebreaks)];

            matched_functions = ~cellfun(@isempty, combine(token_matrix.function));
            indices = find(matched_functions);
            matched_function_extents = [starts(matched_functions); ends(matched_functions)];
            matched_function_arguments = cellfun(@arguments, tokens(matched_functions));
            matched_function_return_values = cellfun(@returns, tokens(matched_functions));
            matched_functions = combine(token_matrix(matched_functions).function);
            matched_function_lines = zeros(1, numel(indices), 'int64');

            for i=1:numel(indices)
                index = indices(i);
                matched_function_lines(i) = sum(linebreaks(1:index)) + 1;
            end

            matched_function_offsets = ...
                matched_function_extents(1, :) ...
                - line_offsets(matched_function_lines);
            
            comments = ~cellfun(@isempty, combine(token_matrix.comment));
            indices = find(comments);
            comment_extents = [starts(comments); ends(comments)];
            comments = combine(token_matrix(comments).comment);
            comment_lines = zeros(1, numel(indices), 'int64');

            for i=1:numel(indices)
                index = indices(i);
                comment_lines(i) = sum(linebreaks(1:index)) + 1;
            end

            comment_depth = int64(0);

            comment_start_offset = 0;

            for i=1:numel(comments)
                c = comments{i};

                if strcmp(c, '%{')
                    comment_depth = comment_depth + 1;

                    if comment_depth == int64(1)
                        comment_start_offset = comment_extents(1, i);
                    end

                elseif strcmp(c, '%}') && comment_depth > int64(0)
                    comment_depth = comment_depth - 1;

                    if comment_depth == int64(0)
                        comment_end_offset = comment_extents(2, i);

                        selector = matched_function_extents(1, :) < comment_start_offset ...
                                   | matched_function_extents(2, :) > comment_end_offset;

                        matched_functions = matched_functions(selector);
                        matched_function_lines = matched_function_lines(selector);
                        matched_function_extents = matched_function_extents(:, selector);
                        matched_function_offsets = matched_function_offsets(selector);
                    end
                end
            end

            matched_function_ranges = ...
                [matched_function_extents(1, :); ...
                [matched_function_extents(1, 2:end) - 1 numel(string)]];
            
            matched_function_bodies = ...
                [matched_function_extents(2, :) + 1; ...
                [matched_function_extents(1, 2:end) - 1 numel(string)]];
            
            obj.fragments_ = {};
            obj.functions_ = struct();
            obj.function_indices_ = [];
            
            previous_range = [];
            
            for i=1:numel(matched_functions)
                
                f = hdng.patch.Function(matched_function_ranges(:, i)', ...
                                        matched_functions{i});
                f.arguments = matched_function_arguments{i};
                f.return_values = matched_function_return_values{i};
                
                if isempty(previous_range)
                    if f.range_in_file(1) >= 2
                        r = hdng.patch.Fragment([1, f.range_in_file(1) - 1]);
                        r.text = text_in_range(string, r.range_in_file);
                        
                        obj.fragments_ = [obj.fragments_; {r}];
                    end
                elseif previous_range(2) + 1 < f.range_in_file(1)
                    r = hdng.patch.Fragment([previous_range(2) + 1, f.range_in_file(1) - 1]);
                    r.text = text_in_range(string, r.range_in_file);

                    obj.fragments_ = [obj.fragments_; {r}];
                end
                
                f.text = string(f.range_in_file(1):f.range_in_file(2));
                
                f.body_range = matched_function_bodies(:, i)' + 1 - f.range_in_file(1);
                f.header_range =[1, f.body_range(1) - 1];
                
                obj.functions_.(f.name) = f;
                
                obj.fragments_ = [obj.fragments_; {f}];
                obj.function_indices_ = [obj.function_indices_; numel(obj.fragments_)];
                
                previous_range = f.range_in_file;
            end
        end
        
        function result = match_function(obj, function_name, ...
                                arguments, ...
                                return_values)
            result = [];
                            
            if ~exist('return_values', 'var')
                return_values = {};
            end
               
            if ~exist('arguments', 'var')
                arguments = {};
            end
                            
            f = obj.function_for_name(function_name);
            
            if isempty(f)
                return;
            end
            
            if isnumeric(arguments)
                
                if arguments ~= numel(f.arguments)
                    return;
                end
                
            else
                [~, unmatched] = f.match_arguments(arguments);

                if ~isempty(unmatched)
                    return;
                end
            end
            
            if isnumeric(return_values)
                
                if return_values ~= numel(f.return_values)
                    return;
                end
                
            else
                [~, unmatched] = f.match_return_values(return_values);

                if ~isempty(unmatched)
                    return;
                end
            end
            
            result = f;
        end
        
        function write(obj, directory, name, ext)
            
            if ~exist('ext', 'var')
                ext = obj.ext;
            end
            
            if ~exist('name', 'var')
                name = obj.name;
            end
            
            path = fullfile(directory, [name ext]);
            
            string = '';
            
            for i=1:numel(obj.fragments_)
                r = obj.fragments_{i};
                string = [string, r.text]; %#ok<AGROW>
            end
            
            hdng.utilities.save_text(string, path);
        end
    end
    
end
