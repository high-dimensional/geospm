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

classdef RegexpTokenizer < handle
    %REGEXPTOKENIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        token_expr
        value_converters
        linebreak_token
        whitespace_token
        
    end
    
    methods
        
        function obj = RegexpTokenizer()
            
            obj.token_expr = '';
            obj.value_converters = struct();
            obj.linebreak_token = zeros(1,1,'int64');
            obj.whitespace_token = zeros(1,1,'int64');
            
        end
        
        function tokenstream = tokenize(obj, string)
            
            [extents, token_matrix, unmatched_token_prefix]=regexp(string, obj.token_expr, 'tokenExtents', 'names', 'split');


            n_extents=size(extents, 2);

            line_number=cast(1, 'int64');
            line_offset=cast(1, 'int64');

            type_names=fieldnames(token_matrix);
            n_type_names=size(type_names,1);

            tokenstream = hdng.parsing.Tokenstream;
            tokenstream.type_names = type_names;
            tokenstream.recompute_type_numbers();
            
            previous_extents=zeros(1, 2, 'int64');

            for i=1:n_extents

                current_extents=cast(extents{1,i}, 'int64');

                if current_extents(1) ~= previous_extents(2) + 1

                    error_line_prefix=string(line_offset:previous_extents(2));
                    string_suffix=string(current_extents(1):end);
                    error_line_suffix=regexp(string_suffix, '(\r\n|\r|\n)|($)', 'split');
                    error_line_suffix=error_line_suffix{1,1};

                    if size(error_line_prefix, 2) > 20
                        error_line_prefix=['...' error_line_prefix(end-17:end) '.'];
                        error_line_prefix=error_line_prefix(1:end-1);
                    end

                    if size(error_line_suffix, 2) > 20
                        error_line_suffix=['.' error_line_suffix(1:17) '...'];
                        error_line_suffix=error_line_suffix(2:end);
                    end

                    unexpected_token=unmatched_token_prefix{1,i};

                    error_line=strcat(error_line_prefix,unexpected_token,error_line_suffix);

                    prefix=repmat(' ',1,size(error_line_prefix, 2));
                    suffix=' here';
                    underline=repmat('^',1,size(unexpected_token,2));

                    error_underline=['.' prefix underline suffix];
                    error_underline(1) = ' ';

                    token = hdng.parsing.Token;
                    
                    token.string=sprintf('Unexpected token in line %d:\n  %s\n %s', line_number, error_line, error_underline);
                    token.extent=cast([previous_extents(2) + 1 - line_offset, current_extents(1) - line_offset], 'int32');
                
                    tokenstream.tokens{tokenstream.position, 1}=token;
                    tokenstream.position = tokenstream.position + 1;
                    tokenstream.errors{end + 1} = token;
                end

                token = hdng.parsing.Token;
                token.extent=cast([current_extents(1) - line_offset current_extents(2) - line_offset], 'int32');

                is_linebreak = false;
                is_whitespace = false;

                token_name_entry=token_matrix(i);

                for j=1:n_type_names

                    if ~isempty(token_name_entry.(type_names{j}))
                        token.string=string(current_extents(1):current_extents(2));
                        token.value=token.string;
                        token.type_number=cast(j, 'int64');

                        if isfield(obj.value_converters, type_names{j})
                            token.value=obj.value_converters.(type_names{j})(token.string);
                        end

                        is_linebreak = strcmp(type_names{j}, obj.linebreak_token);
                        is_whitespace = strcmp(type_names{j}, obj.whitespace_token);

                        break;
                    end
                end

                if is_linebreak
                    line_number = line_number + 1;
                    line_offset=current_extents(2) + 1;
                end


                if ~is_whitespace && ~is_linebreak
                    tokenstream.tokens{tokenstream.position, 1}=token;
                    tokenstream.position = tokenstream.position + 1;
                end

                previous_extents=current_extents;
            end

            tokenstream.tokens=tokenstream.tokens(1:tokenstream.position - 1);
            tokenstream.position = cast(1, 'int64');
        end
        
    end
    
end
