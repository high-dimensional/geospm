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

function result = snakecase_from_class_type(class_type)
%snakecase_from_class_type Converts each identifier in a dotted class type
%from camel case to snake case.
    parts = split(class_type, '.');
    
    for i=1:numel(parts)
        identifier = parts{i};
        identifier = join(lower(hdng.utilities.split_camelcase(identifier)), '_');
        parts{i} = identifier{1};
    end
    
    result = join(parts, '.');
end
