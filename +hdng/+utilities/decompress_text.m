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

function [text] = decompress_text(bytes)


    f = java.io.ByteArrayInputStream(bytes);
    g = java.util.zip.GZIPInputStream(f);
    i = java.io.BufferedInputStream(g);

    decompressed_bytes = [];
    
    buffer = zeros(1, 1024, 'uint8');
    buffer_index = 0;
    
    while true
        x = i.read();
        
        if x < 0
            break
        end
        
        if buffer_index >= numel(buffer)
            decompressed_bytes = [decompressed_bytes buffer]; %#ok<AGROW>
            buffer_index = 0;
        end
        
        buffer(buffer_index + 1) = cast(x, 'uint8');
        buffer_index = buffer_index + 1;
    end
    
    decompressed_bytes = [decompressed_bytes buffer(1:buffer_index)];
    text = native2unicode(decompressed_bytes, 'UTF-8');
end
