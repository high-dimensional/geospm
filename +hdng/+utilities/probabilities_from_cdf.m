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

function [result] = probabilities_from_cdf(P)
    
    dimensions = size(P);
    
    if numel(dimensions) ~= 2
        error('probabilities+_from_cdf(): Argument must be 2-dimensional.');
    end

    result =   P(1:dimensions(1) - 1, 1:dimensions(2) - 1) ...
             + P(2:dimensions(1),     2:dimensions(2)) ...
             - P(1:dimensions(1) - 1, 2:dimensions(2)) ...
             - P(2:dimensions(1),     1:dimensions(2) - 1);
end
