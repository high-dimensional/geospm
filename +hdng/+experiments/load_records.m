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

function records = load_records(varargin)

    records = hdng.experiments.RecordArray();
    format = hdng.experiments.JSONFormat();
    
    for i=1:numel(varargin)
        
        argument = varargin{i};
        
        if isstruct(argument)
            path = argument.path;
        else
            path = argument;
        end
        
        bytes = hdng.utilities.load_bytes(path);
        options = options_from_file_path(path);
        
        if isstruct(argument)
            
            if isfield(argument, 'rebase_paths')
                
                options.value_modifier = hdng.experiments.PathRebaser();
                options.value_modifier.dir_regexp = argument.rebase_paths.dir_regexp;
                options.value_modifier.dir_replacement = argument.rebase_paths.dir_replacement;
                options.value_modifier.dir_mode = argument.rebase_paths.dir_mode;
            end
        end
        
        format.decode(bytes, options, records);
    end
end

function options = options_from_file_path(file_path)
    [~, file_name, ext1] = fileparts(file_path);
    [~, ~, ext2] = fileparts(file_name);
    
    options = struct();
    options.compression = false;
    options.base64 = false;
    
    if strcmpi(ext1, '.gz') || strcmpi(ext2, '.gz')
        options.compression = true;
        options.base64 = true;
    end
end
