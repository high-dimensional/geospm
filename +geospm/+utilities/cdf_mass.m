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

function result = cdf_mass(cdf_values)

    % Computes the local mass for each mesh cell from the cdf node values.
    
    dimensions = size(cdf_values) - 1;
    
    P = cdf_values;
    

    switch( numel(dimensions))
        case 2
        
            result =   P(1:dimensions(1),     1:dimensions(2)) ...
                     + P(2:dimensions(1) + 1, 2:dimensions(2) + 1) ...
                     - P(1:dimensions(1),     2:dimensions(2) + 1) ...
                     - P(2:dimensions(1) + 1, 1:dimensions(2));

        case 3

            result =   P(2:dimensions(1) + 1, 2:dimensions(2) + 1, 2:dimensions(3) + 1) ...
                     + P(1:dimensions(1),     1:dimensions(2),     2:dimensions(3) + 1) ...
                     - P(2:dimensions(1) + 1, 1:dimensions(2),     2:dimensions(3) + 1) ...
                     - P(1:dimensions(1),     2:dimensions(2) + 1, 2:dimensions(3) + 1) ...
                     ...
                     - P(2:dimensions(1) + 1, 2:dimensions(2) + 1, 1:dimensions(3)    ) ...
                     - P(1:dimensions(1),     1:dimensions(2),     1:dimensions(3)    ) ...
                     + P(2:dimensions(1) + 1, 1:dimensions(2),     1:dimensions(3)    ) ...
                     + P(1:dimensions(1),     2:dimensions(2) + 1, 1:dimensions(3)    );
                     

        otherwise
            error('cdf_differences(): Mesh values must have 2 or 3 dimensions.');
    end
end
