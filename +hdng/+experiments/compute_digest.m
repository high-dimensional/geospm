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

function [digest, serialised, content_type] = compute_digest(content, serialised, content_type)
    %compute_digest Derives a label from a value
    
    if ~exist('serialised', 'var')
        [serialised, content_type] = hdng.experiments.as_serialised_value_and_type(content);
    end
    
    digestible = struct();
    digestible.content_type = content_type;
    digestible.content = serialised;
    
    digestible = hdng.utilities.encode_json(digestible);
    digest = compute_md5(digestible);
end

function hash = compute_md5(string)
    

    persistent md
    
    if isempty(md)
        md = java.security.MessageDigest.getInstance('MD5');
    end
    
    %bytes = uint8(string);
    bytes = unicode2native(string, 'UTF-8');
    digest_bytes = typecast(md.digest(bytes), 'uint8');
    
    hash = sprintf('%2.2x', digest_bytes');
end
