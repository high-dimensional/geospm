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

function result = issubclass(subtype, supertype)

    subtype = typeidentifierof(subtype);
    supertype = typeidentifierof(supertype);
    
    result = (any(strcmp(superclasses(subtype), supertype)) || strcmp(subtype, supertype));
end

function result = typeidentifierof(value)

    if ~ischar(value)
        
        if isa(value, 'meta.class')
            result = value.Name;
        else
            result = class(value);
        end
    else
        result = value;
    end
    
end
