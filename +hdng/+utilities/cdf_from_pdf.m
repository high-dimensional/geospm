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

function [result] = cdf_from_pdf(pdf)
    
    dimensions = size(pdf);
    
    if numel(dimensions) ~= 2
        error('probabilities+_from_cdf(): Argument must be 2-dimensional.');
    end

    result = zeros(dimensions);
    
    d1 = dimensions(1);
    d2 = dimensions(2);
    
    for i=2:d1
        for j=2:d2
            
            result(i, j) = - result(i - 1, j - 1) ...
                           + result(i - 1, j) ...
                           + result(i, j - 1) ...
                           + pdf(i, j);
            
        end
    end
    
    result = result ./ result(d1, d2);
    result = result(2:end, 2:end);
end
