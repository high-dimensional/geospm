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

function result = concatenate_tabular_structs(s1, s2, n1, n2)

    result = struct();

    names1 = fieldnames(s1);
    
    if ~exist('n1', 'var') || isempty(n1)
        for index=1:numel(names1)
            name = names1{index};
            n1 = numel(s1.(name));
            break;
        end
    end

    names2 = fieldnames(s2);
    
    if ~exist('n2', 'var') || isempty(n2)
        for index=1:numel(names2)
            name = names2{index};
            n2 = numel(s2.(name));
            break;
        end
    end

    names = unique([names1(:); names2(:)]);

    for index=1:numel(names)
        name = names{index};
        
        result.(name) = concatenate_tabular_structs_field(name, s1, n1, s2, n2);
    end
end


function values = fill_values(type, n)

    if strcmp(type, 'cell')
        if n == 0
            values = cell.empty;
            return
        end

        values = cell(n, 1);
        return;
    end

    if strcmp(type, 'struct')
        
        if n == 0
            values = struct.empty;
            return
        end

        values = struct('unused', num2cell(zeros(n, 1)));
        values = rmfield(values, 'unused');
        return;
    end

    if strcmp(type, 'string')
        if n == 0
            values = string.empty;
            return
        end

        values = repmat("", n, 1);
        return;
    end

    dummy = zeros(1, 1, type);
    
    if isfloat(dummy)

        if n == 0
            values = cast([], type);
            return
        end

        values = nan(n, 1, type);
    elseif isinteger(dummy) || islogical(dummy)

        if n == 0
            values = cast([], type);
            return
        end

        values = zeros(n, 1, type);
    else
        error('Cannot fill values for type %s.', type);
    end
end

function values = concatenate_tabular_structs_field(name, s1, n1, s2, n2)

    if isfield(s1, name)
        f1 = s1.(name); f1 = f1(:);
        type1 = class(f1);

        if numel(f1) < n1
            f1 = [f1; fill_values(type1, n1 - numel(f1))];
        end
    end

    if isfield(s2, name)
        f2 = s2.(name); f2 = f2(:);
        type2 = class(f2);

        if numel(f2) < n2
            f2 = [f2; fill_values(type2, n2 - numel(f2))];
        end
    end



    if ~exist('f1', 'var')
        type1 = type2;
        f1 = fill_values(type1, n1);
    end

    if ~exist('f2', 'var')
        type2 = type1;
        f2 = fill_values(type2, n2);
    end
    
    if ~strcmp(type1, type2)
        error('Cannot concatenate struct field arrays for field ''%s'' because of type mismatch: %s ~= %s', name, type1, type2);
    end

    values = [f1; f2];
end
