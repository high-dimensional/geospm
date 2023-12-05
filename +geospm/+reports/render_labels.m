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

function result = render_labels(labels, step_sizes, coord_key, coords, spacing, attributes)
    
    result = '';
    origin = coords.(coord_key);

    attributes = geospm.reports.render_markup_attributes(attributes);

    for index=1:numel(labels)
        label = geospm.reports.html_escape(labels{index});
        
        coords.(coord_key) = origin + step_sizes(index) / 2;
        
        result = [result sprintf('<text text-anchor="middle" x="%d" y="%d" %s>%s</text>', coords.x, coords.y, attributes, label) newline]; %#ok<AGROW>
    
        origin = origin + step_sizes(index) + spacing;
    end
end