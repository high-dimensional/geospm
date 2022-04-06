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

function [X, Y, parts] = disassemble_shape(shape, offset_type)
    
    if ~exist('offset_type', 'var')
        offset_type = 'int64';
    end

    selector = isnan(shape.X);
    parts = find(selector);

    for j=1:numel(parts)
        parts(j) = parts(j) + 1 - j;
    end

    parts = cast([1 parts], offset_type);
    parts = parts(:);

    selector = ~selector;

    X = shape.X(selector);
    Y = shape.Y(selector);
    
    X = X(:);
    Y = Y(:);
    
    if parts(end) == numel(X) + 1
        parts = parts(1:end - 1);
    end
end
