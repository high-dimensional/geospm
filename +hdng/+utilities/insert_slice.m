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

function array = insert_slice(array, dimension, at, slice, slice_count) %#ok<INUSD>


    array_size = size(array);
    D = numel(array_size);
    
    if ~exist('slice_count', 'var')
        slice_count = 1;
    end
    
    slice_size = array_size;
    slice_size(dimension) = slice_count;

    if ~exist('slice', 'var') || isempty(slice)
           
        type = class(array);

        if islogical(array) || isinteger(array) || isfloat(array)
            slice = zeros(slice_size, type); %#ok<PREALL>
        elseif iscell(array)
            slice = cell(slice_size); %#ok<PREALL>
        else
            error('Cannot deduce type for generating slice.');
        end
    else

        if numel(size(slice)) < numel(array_size)
            if numel(slice) == 1
                slice = repmat(slice, slice_size); %#ok<NASGU>
            else
                slice = reshape(slice, slice_size); %#ok<NASGU>
            end
        end
    end
    
    arguments = cell(D, 1);

    for index=1:D
        arguments{index} = ':';
    end

    arguments{dimension} = '1:at - 1';

    prologue = join(arguments, ', ');
    prologue = prologue{1};

    arguments{dimension} = 'at:end';

    epilogue = join(arguments, ', ');
    epilogue = epilogue{1};
    
    expr = ['cat(dimension, array(' prologue '), slice, array( ' epilogue '))'];

    array = eval(expr);
end
