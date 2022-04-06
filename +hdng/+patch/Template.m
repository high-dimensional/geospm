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

classdef Template < handle
    %Template Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name
        ext
    end
    
    properties (Dependent, Transient)
        fragments
        variables
        variable_names
    end
    
    properties (Access=private)
        fragments_
        variables_
        variable_indices_
    end
    
    
    methods
        
        function obj = Template()
            
            obj.name = [];
            obj.ext = [];
            obj.fragments_ = {};
            obj.variables_ = struct();
            obj.variable_indices_ = [];
        end
        
        function result = get.fragments(obj)
            result = obj.fragments_;
        end
        
        function result = get.variables(obj)
            names = fieldnames(obj.variables_);
            result = cell(numel(names), 1);
            
            for i=1:numel(names)
                vname = names{i};
                v = obj.variables_.(vname);
                result{i} = v;
            end 
        end
        
        function result = get.variable_names(obj)
            result = fieldnames(obj.variables_);
        end
        
        function result = variables_for_name(obj, name)
            result = {};
            
            if ~isfield(obj.variables_, name)
                return;
            end
            
            result = obj.variables_.(name);
        end
        function parse(obj, path)
            
            [~, obj.name, obj.ext] = fileparts(path);
            
            string = hdng.utilities.load_text(path);

            match_expr = '(?<linebreak>(\r\n|\r|\n))|(?<comment>(^|(\r\n|\r|\n)\s*)\%(\{|\}|[^\{\}\r\n]*))|(?<variable>\$\{[A-Za-z][A-Za-z0-9_]*\})';
            
            [starts, ends, token_matrix] = ...
                regexp(string, match_expr, 'start', 'end', 'names');
            
            function result = text_in_range(string, range)
                result = string(range(1):range(2));
            end
            
            function result = combine(varargin)
                result = varargin;
            end
            
            matched_variables = ~cellfun(@isempty, combine(token_matrix.variable));
            matched_variable_extents = [starts(matched_variables); ends(matched_variables)];
            matched_variables = combine(token_matrix(matched_variables).variable);

            comments = ~cellfun(@isempty, combine(token_matrix.comment));
            comment_extents = [starts(comments); ends(comments)];
            comments = combine(token_matrix(comments).comment);
            
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

                        selector = matched_variable_extents(1, :) < comment_start_offset ...
                                   | matched_variable_extents(2, :) > comment_end_offset;

                        matched_variables = matched_variables(selector);
                        matched_variable_extents = matched_variable_extents(:, selector);
                    end
                end
            end
            
            matched_variable_ranges = matched_variable_extents;
            
            obj.fragments_ = {};
            obj.variables_ = struct();
            
            previous_range = [];
            
            for i=1:numel(matched_variables)
                
                v = hdng.patch.TemplateVariable(...
                        matched_variable_ranges(:, i)', ...
                        matched_variables{i}(3:end-1));
                
                if isempty(previous_range)
                    if v.range_in_file(1) >= 2
                        r = hdng.patch.Fragment([1, v.range_in_file(1) - 1]);
                        r.text = text_in_range(string, r.range_in_file);
                        
                        obj.fragments_ = [obj.fragments_; {r}];
                    end
                elseif previous_range(2) + 1 < v.range_in_file(1)
                    r = hdng.patch.Fragment([previous_range(2) + 1, v.range_in_file(1) - 1]);
                    r.text = text_in_range(string, r.range_in_file);

                    obj.fragments_ = [obj.fragments_; {r}];
                end
                
                v.text = string(v.range_in_file(1):v.range_in_file(2));
                
                obj.fragments_ = [obj.fragments_; {v}];
                obj.variable_indices_ = [obj.variable_indices_; numel(obj.fragments_)];
                
                if ~isfield(obj.variables_, v.name)
                    obj.variables_.(v.name) = {};
                end
                
                obj.variables_.(v.name) = [obj.variables_.(v.name), numel(obj.fragments_)]; 
                
                previous_range = v.range_in_file;
            end
            
            if isempty(previous_range)

                r = hdng.patch.Fragment([1, numel(string)]);
                r.text = text_in_range(string, r.range_in_file);

                obj.fragments_ = [obj.fragments_; {r}];
            elseif previous_range(2) + 1 < numel(string)
                r = hdng.patch.Fragment([previous_range(2) + 1, numel(string)]);
                r.text = text_in_range(string, r.range_in_file);

                obj.fragments_ = [obj.fragments_; {r}];
            end
        end
        
        function [result, unfilled] = fill(obj, variables)
            
            result = '';
            unfilled = struct();
            
            previous_index = 1;
            
            for i=1:numel(obj.variable_indices_)
                
                index = obj.variable_indices_(i);
                
                for j=previous_index:index - 1
                    r = obj.fragments_{j};
                    result = [result, r.text]; %#ok<AGROW>
                end
                
                v = obj.fragments_{index};
                
                if isfield(variables, v.name)
                    result = [result, variables.(v.name)]; %#ok<AGROW>
                else
                    unfilled.(v.name) = true;
                    result = [result, v.text]; %#ok<AGROW>
                end
                
                previous_index = index + 1;
            end
            
            for j=previous_index:numel(obj.fragments_)
                r = obj.fragments_{j};
                result = [result, r.text]; %#ok<AGROW>
            end
            
            unfilled = fieldnames(unfilled);
        end
        
        function unfilled = write(obj, variables, directory, name, ext)
            
            if ~exist('ext', 'var')
                ext = obj.ext;
            end
            
            if ~exist('name', 'var')
                name = obj.name;
            end
            
            path = fullfile(directory, [name ext]);
            [text, unfilled] = obj.fill(variables);
            hdng.utilities.save_text(text, path);
        end
    end
    
end
