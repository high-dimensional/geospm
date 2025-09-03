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

function result = format_css_attributes(dictionary, is_inline)

    if ~exist('is_inline', 'var')
        is_inline = true;
    end

    if is_inline
        rule_sep = ' ';
    else
        rule_sep = [newline '  '];
    end

    result = '';
    keys = dictionary.keys();

    for index=1:numel(keys)
        key = keys{index};
        value = dictionary(key);

        result = sprintf('%s%s: %s;%s', result, key, value, rule_sep);
    end
end
