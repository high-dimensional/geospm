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

function result = load_json(file_path, varargin)
    
    options = hdng.utilities.parse_struct_from_varargin(varargin{:});

    bytes = hdng.utilities.load_bytes(file_path);
    
    file_options = options_from_file_path(file_path);

    option_names = fieldnames(file_options);

    for index=1:numel(option_names)
        option_name = option_names{index};

        if isfield(options, option_name)
            continue;
        end

        options.(option_name) = file_options.(option_name);
    end

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

    if ~isfield(options, 'as_struct')
        options.as_struct = false;
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

    if ~options.as_struct
        result = hdng.utilities.decode_json(text);
    else
        result = jsondecode(text);
    end
end
