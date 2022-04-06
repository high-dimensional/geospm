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

classdef Tokenstream < handle
    %Tokenstram Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        position
        tokens
        errors
        type_names
        type_numbers
        
    end
    
    properties (Dependent)
        
        has_errors
    end
    
    methods
        
        function obj = Tokenstream()
            
            obj.position = cast(1, 'int64');
            obj.tokens = cell(0,1);
            obj.errors = cell(0,1);
            obj.type_names = cell(0,1);
            obj.type_numbers = struct();
            
        end
        
        function value = get.has_errors(obj)
            
            value = size(obj.errors, 1) > 0;
            
        end
        
        function set.position(obj, value)
            

            if ~isinteger(value)
                error('Value for ''position'' must be an integer.');
            end

            obj.position = value;            
        end
        
        
        function set.tokens(obj, value)

            if ~iscell(value) || size(value, 2) ~= 1 || ~check_cell_column_vector_contains_only_tokens(value)
                error('Value for ''tokens'' must be a N x 1 cell array of ''Token'' values.');
            end

            obj.tokens = value;            
        end
        
        function set.type_names(obj, value)
            
            if ~iscell(value) || size(value, 2) ~= 1 || ~check_cell_column_vector_contains_only_chars(value)
                error('Value for ''type_names'' must be a N x 1 cell array of ''char'' values.');
            end
            
            obj.type_names = value;
        end
        
        function recompute_type_numbers(obj)
            
            new_type_numbers = struct();
            
            for i=1:size(obj.type_names, 1)
                new_type_numbers.(obj.type_names{i}) = i;
            end
            
            obj.type_numbers = new_type_numbers;
            
        end
        
        function set.type_numbers(obj, value)

            if ~isstruct(value)
                error('Value for ''type_numbers'' must be a struct defining fields of integer values.');
            end
            
            obj.type_numbers = value;
        end
        
        function define_error(obj, message, line_number, extent)

            error=struct();
            error.string = message;
            error.extent = extent;
            error.line_number = line_number;

            obj.errors{end + 1} = error;
        end

        function remove_last_error(obj)

            if size(obj.errors, 1) == 0
                return
            end

            if size(obj.errors, 1) > 1
                obj.errors = obj.errors{1:end-1};
            else
                obj.errors = cell(0,1);
            end
        end

        function [result] = has_next_token(obj)

            result = obj.position <= size(obj.tokens, 1);
        end

        function [result] = has_next_token_with_types(obj, token_types)

            result = obj.position <= size(obj.tokens, 1);
            
            if ~result
                return
            end
            
            token=obj.tokens{obj.position};

            is_token_type_valid = false;

            for i=1:size(token_types, 1)
                if token.type_number == token_types{i}
                    is_token_type_valid = true;
                    break
                end
            end

            result = is_token_type_valid;
        end

        function location = current_line_number_and_position(obj)
            
            if obj.position <= size(obj.tokens, 1)
                line_number = obj.tokens{obj.position}.line_number;
                pos_in_line = obj.tokens{obj.position}.extent(1);
            else
                if obj.position > 1
                    line_number = obj.tokens{obj.position - 1}.line_number;
                    pos_in_line = obj.tokens{obj.position - 1}.extent(2);
                else
                    line_number = 1;
                    pos_in_line = 1;
                end
            end
            
            location = [line_number, pos_in_line];
        end

        function [successful, token] = next_token_with_types(obj, token_types)

            successful=false;

            if ~has_next_token(obj)
                token = {};
                location = current_line_number_and_position(obj);
                obj.define_error('Premature end of input.', ...
                                 location(1), 1);
                return;
            end

            token=obj.tokens{obj.position};

            is_token_type_valid = false;

            for i=1:size(token_types, 1)
                if token.type_number == token_types{i}
                    is_token_type_valid = true;
                    break
                end
            end

            if ~is_token_type_valid

                expected_token_types = obj.type_names{token_types{1}};

                for i=2:size(token_types, 1)
                    expected_token_types = strcat(expected_token_types, ', ', obj.type_names{token_types{i}});
                end

                obj.define_error( ...
                    sprintf('Expected one of {%s} but got %s (in line %d).', expected_token_types, obj.type_names{token.type_number}, token.line_number), ...
                    token.line_number, token.extent);
                return;
            end

            successful=true;
            obj.position = obj.position + 1;
        end
    end
end

 
function [bool_result] = check_cell_column_vector_contains_only_chars(argument)

    bool_result = true;

    for i=1:size(argument,1)

        if ~ischar(argument{i})
            bool_result = false;
            return
        end
    end
end


function [bool_result] = check_cell_column_vector_contains_only_tokens(argument)

    bool_result = true;

    for i=1:size(argument,1)

        if ~isa(argument{i}, 'hdng.parsing.Token')
            bool_result = false;
            return
        end
    end
end


function [bool_result] = check_cell_column_vector_contains_only_integers(argument)

    bool_result = true;

    for i=1:size(argument,1)

        if ~isinteger(argument{i})
            bool_result = false;
            return
        end
    end

end
