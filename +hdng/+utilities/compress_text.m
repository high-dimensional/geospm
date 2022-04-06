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

function [bytes] = compress_text(text)

    unicode_bytes = unicode2native(text, 'UTF-8');

    f = java.io.ByteArrayOutputStream();
    g = java.util.zip.GZIPOutputStream(f);
    
    g.write(unicode_bytes);
    g.close;
    
    bytes = typecast(f.toByteArray,'uint8');
    f.close;
end
