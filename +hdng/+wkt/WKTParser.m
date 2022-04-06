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

classdef WKTParser
    %WKTPARSER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        tokenizer
        
        allow_value_sequences
        allow_anonymous_values
        allow_additional_keywords
        allow_parenthesis_delimiters
        allow_bracket_delimiters
    end
    
    methods
        
        function obj = WKTParser()
            
            obj.tokenizer = hdng.wkt.WKTTokenizer;
            
            obj.allow_value_sequences = false;
            obj.allow_anonymous_values = false;
            obj.allow_additional_keywords = false;
            
            
            obj.allow_parenthesis_delimiters = true;
            obj.allow_bracket_delimiters = true;
        end
        
        function [result] = parse_file(obj, file_path)

            string = hdng.utilities.load_text(file_path);
            result = obj.parse_chars(string);
        end
        
        function [result] = parse_chars(obj, string)

            tokenstream = obj.tokenizer.tokenize(string);
            result = obj.parse_impl(tokenstream);
        end
        
        function [result] = parse_impl(obj, tokenstream)
            
            result = struct();
            result.location = current_line_number_and_position(tokenstream);
            
            if tokenstream.has_errors
                result.errors = tokenstream.errors;
                return
            end
            
            delimiters = {};
            
            if obj.allow_parenthesis_delimiters
                delimiters = [delimiters; {tokenstream.type_numbers.lp}];
            end
            
            if obj.allow_bracket_delimiters
                delimiters = [delimiters; {tokenstream.type_numbers.lb}];
            end
            
            if obj.allow_anonymous_values
                additional_start_tokens = delimiters;
            else
                additional_start_tokens = {};
            end
            
            numeric_types = {tokenstream.type_numbers.integer; ...
                             tokenstream.type_numbers.real};
            
            [have_token, token] = tokenstream.next_token_with_types(...
                [{tokenstream.type_numbers.keyword;
                  tokenstream.type_numbers.string}; ...
                  numeric_types; ...
                  additional_start_tokens
                 ]);

            if ~have_token
                result.errors = tokenstream.errors;
                return
            end

            is_keyword = token.type_number == tokenstream.type_numbers.keyword;

            is_delimiter = false;
            
            if obj.allow_anonymous_values
                for i=1:numel(delimiters)
                    is_delimiter = token.type_number == delimiters{i};
                    if is_delimiter
                        break
                    end
                end
            end
            
            if ~is_keyword && ~is_delimiter
                
                values = token.value;
                    
                is_numeric = token.type_number == tokenstream.type_numbers.integer ...
                             || token.type_number == tokenstream.type_numbers.real;
                
                if obj.allow_value_sequences && is_numeric
                    
                    while has_next_token(tokenstream)
                        [have_token, token] = tokenstream.next_token_with_types(numeric_types);

                        if ~have_token
                            tokenstream.remove_last_error();
                            break
                        end
                        
                        if ~strcmp(class(values), class(token.value))
                            values = double(values);
                            token.value = double(token.value);
                        end
                        
                        values = [values token.value]; %#ok<AGROW>
                    end
                end
                
                result.value = values;
                return;
            end

            nested = struct();
            nested.keyword = '';
            nested.keyword_as_specified = '';
            nested.additional_keywords = cell(0, 1);
            nested.additional_keywords_as_specified = cell(0, 1);
            nested.attributes = cell(0,1);
            nested.locations = cell(0,1);

            if ~is_delimiter
                keyword_token = token;

                nested.keyword = upper(keyword_token.value);
                nested.keyword_as_specified = keyword_token.value;

                if ~has_next_token(tokenstream)
                    result.value = nested;
                    return;
                end

                if obj.allow_additional_keywords

                    while true
                        [have_token, token] = tokenstream.next_token_with_types({tokenstream.type_numbers.keyword});

                        if ~have_token
                            tokenstream.remove_last_error();
                            break
                        end

                        nested.additional_keywords = [nested.additional_keywords {upper(token.value)}];
                        nested.additional_keywords_as_specified = [nested.additional_keywords_as_specified {token.value}];
                    end
                end

                [have_token, token] = tokenstream.next_token_with_types(delimiters);

                if ~have_token
                    tokenstream.remove_last_error();
                    result.value = nested;
                    return
                end
            end
            
            if token.type_number == tokenstream.type_numbers.lp
                closing_delimiter = tokenstream.type_numbers.rp;
            else
                closing_delimiter = tokenstream.type_numbers.rb;
            end

            while token.type_number ~= closing_delimiter

                nested_result = obj.parse_impl(tokenstream);

                if ~isfield(nested_result, 'value')
                    result.errors = nested_result.errors;
                    return
                end
                
                nested.attributes{end + 1, 1} = nested_result.value;
                nested.locations{end + 1, 1} = nested_result.location;

                [have_token, token] = tokenstream.next_token_with_types({tokenstream.type_numbers.comma; closing_delimiter});

                if ~have_token
                    result.errors = tokenstream.errors;
                    return
                end
            end
            
            result.value = nested;
        end
        
    end
    
end
