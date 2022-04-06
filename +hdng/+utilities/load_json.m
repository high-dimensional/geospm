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

function result = load_json(file_path)
    
    bytes = hdng.utilities.load_bytes(file_path);
    
    options = options_from_file_path(file_path);
    result = decode(bytes, options);
end

function options = options_from_file_path(file_path)
    [~, file_name, ext1] = fileparts(file_path);
    [~, ~, ext2] = fileparts(file_name);
    
    options = struct();
    options.compressed = false;
    options.base64 = false;
    
    if strcmpi(ext1, '.gz') || strcmpi(ext2, '.gz')
        options.compressed = true;
        options.base64 = true;
    end
end

function result = decode(bytes, options)
    
    if ~isfield(options, 'compression')
        options.compression = false;
    end
    if ~isfield(options, 'base64')
        options.base64 = false;
    end

    if options.compression

        if options.base64
            text = native2unicode(bytes, 'UTF-8');
            bytes = matlab.net.base64decode(text);
        end

        text = hdng.utilities.decompress_text(bytes);
    else
        text = native2unicode(bytes, 'UTF-8');
    end

    result = hdng.utilities.decode_json(text);
end
