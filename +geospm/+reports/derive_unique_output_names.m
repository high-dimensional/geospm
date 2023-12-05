% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2021,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function unique_names = derive_unique_output_names(file_paths)
    
    N = numel(file_paths);
    unique_names = cell(N, 1);

    prefixes = cell(N, 1);
    names = cell(N, 1);

    for index=1:N
        [path, name, ~] = fileparts(file_paths{index});
        path = regexprep(path, sprintf('%s%s+', filesep, filesep), filesep);
        parts = split(path, filesep);
        prefixes{index} = [parts; {name}];
        names{index} = name;
    end

    do_loop = true;
    found_unique_names = false;

    part_index = 2;
    suitable_part_indices = 1;

    while do_loop

        current_set = containers.Map('KeyType', 'char', 'ValueType', 'logical');

        for index=1:N

            parts = prefixes{index};
            
            if numel(parts) < part_index
                continue;
            end

            key = regexprep(lower(parts{end + 1 - part_index}), '\s+', '_');
            current_set(key) = true;
        end

        if current_set.length == 0
            break;
        end

        if current_set.length > 1
            suitable_part_indices = [suitable_part_indices; part_index]; %#ok<AGROW>
        end

        part_index = part_index + 1;
    end

    part_index = 1;
    
    while do_loop
        
        suitable_index = suitable_part_indices(part_index);

        current_set = containers.Map('KeyType', 'char', 'ValueType', 'logical');
        
        for index=1:N

            parts = prefixes{index};
            
            if numel(parts) < suitable_index
                do_loop = false;
                break;
            end
            
            if ~isempty(unique_names{index})
                unique_names{index} = ['_' unique_names{index}];
            end

            unique_names{index} = [regexprep(lower(parts{end + 1 - suitable_index}), '\s+', '_') ...
                                   unique_names{index}];
            
            if ~isKey(current_set, unique_names{index})
                current_set(unique_names{index}) = true;
            end
        end

        if length(current_set) == N
            found_unique_names = true;
            do_loop = false;
        end

        part_index = part_index + 1;
    end

    if ~found_unique_names
        error('Couldn''t determine unique names.');
    end
end