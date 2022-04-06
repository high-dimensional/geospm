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

function result = hash_strings(strings, result_type)

    hash_engine = java.security.MessageDigest.getInstance('SHA-256');
    
    if ~exist('result_type', 'var')
        result_type = 'uint64';
    end

    switch result_type

        case 'uint8'
            W = 1;
        case 'uint16'
            W = 2;
        case 'uint32'
            W = 4;
        case 'uint64'
            W = 8;

        otherwise
            error('Unsupported result type: %s', result_type);
    end

    K = numel(strings);

    hash_engine.reset();

    for i=1:K
        part = strings{i};
        hash_engine.update(unicode2native(part, 'UTF-8'));
    end

    result = typecast(hash_engine.digest(), 'uint8');

    B = numel(result);

    seed_bytes = repmat(cast(255, 'uint8'), W, 1);

    for i=1:B
        p = mod(i - 1, W) + 1;
        seed_bytes(p) = bitxor(seed_bytes(p), result(i));
    end

    result = zeros(1, 1, result_type);

    for i=1:W
        s = W * (i - 1);
        result = bitor(result, bitshift(cast(seed_bytes(i), result_type), s));
    end

    result = mod(result, intmax(result_type));
end
