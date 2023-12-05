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

function result = render_markup_attributes(attributes)
    
    result = '';
    keys = attributes.keys();
    
    for index=1:numel(keys)
        key = keys{index};
        value = attributes(key);
        delimiter = ' ';

        if isempty(result)
            delimiter = '';
        end
        
        result = [result sprintf('%s%s="%s"', delimiter, key, value)]; %#ok<AGROW>
    end
end
