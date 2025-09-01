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

function lines = layout_text(fragments, styles, max_width, alignment, units)
    
    if ~exist('styles', 'var') || isempty(styles)
        style = hdng.typesetting.Style();
        style.font_family = 'Barlow';
        style.font_size = 10;

        styles = cell(numel(fragments), 1);

        for index=1:numel(styles)
            styles{index} = style;
        end
    end

    if ~exist('max_width', 'var') || isempty(max_width)
        max_width = Inf;
    end

    if ~exist('alignment', 'var') || isempty(alignment)
        alignment = 'start';
    end

    if ~exist('units', 'var') || isempty(units)
        units = 'pixels';
    end
    
    t = hdng.typesetting.Typesetter();
    t.units = units;
    
    tokens = struct('text', fragments, 'style', styles);
    lines = t.layout(tokens, max_width, alignment);
end
