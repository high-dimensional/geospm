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

function result = html_escape(input)
    
    map = hdng.utilities.Dictionary();
    
    map('&') = '&amp;';
    map('"') = '&quot;';
    map('''') = '&apos;';
    map('<') = '&lt;';
    map('>') = '&gt;'; %#ok<NASGU>
    
    result = regexprep(input, '(&|"|''|<|>|)', '${map($1)}');
end
