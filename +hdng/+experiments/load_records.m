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

function records = load_records(file_path)
    
    bytes = hdng.utilities.load_bytes(file_path);
    
    options = options_from_file_path(file_path);
    records = hdng.experiments.RecordArray();
    
    format = hdng.experiments.JSONFormat();
    format.decode(bytes, options, records);
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
