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

function result = randidentifier(min_length, max_length, N, varargin)

    options = hdng.utilities.parse_struct_from_varargin(varargin{:});

    if ~isfield(options, 'without_replacement')
        options.without_replacement = false;
    end
    
    result = randidentifier_impl(min_length, max_length, N);
    
    if options.without_replacement
        
        unique_value_map = containers.Map('KeyType', 'char', 'ValueType', 'logical');
            
        unique_values = cell(N, 1);
        N_unique_values = 0;

        while N_unique_values < N

            for i=1:numel(result)
                
                value = result{i};

                if isKey(unique_value_map, value)
                    continue
                end

                unique_value_map(value) = 1;
                N_unique_values = N_unique_values + 1;
                unique_values{N_unique_values} = value;
            end
            
            result = randidentifier_impl(min_length, max_length, N - N_unique_values);
        end
        
        result = unique_values;
    end
end

function result = randidentifier_impl(min_length, max_length, N)

    result = cell(N, 1);
    
    first_alphabet = 'abcdefghijklmnopqrstuvwxyz';
    first_alphabet = [first_alphabet upper(first_alphabet)];
    other_alphabet = [first_alphabet '0123456789_'];
    A = max([numel(first_alphabet) numel(other_alphabet)]);
    
    for i=1:N
        L = randi(max_length + 1 - min_length, 1) + min_length;
        indices = randi(A, [1 L]);
        indices(1) = mod(indices(1) - 1, numel(first_alphabet)) + 1;
        result{i} = [first_alphabet(indices(1)) other_alphabet(indices(2:end))];
    end
end
