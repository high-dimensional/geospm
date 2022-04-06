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

function [file_paths, directory_paths] = list_files(directory, varargin)

    options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    if ~isfield(options, 'exclude')
        options.exclude = {};
    end
    
    exclude = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    
    for i=1:numel(options.exclude)
        file_path = options.exclude{i};
        exclude(file_path) = 1;
    end
    
    listing = dir(directory);
    N_entries = numel(listing);
    file_paths = cell(N_entries, 1);
    directory_paths = cell(N_entries, 1);
    
    N_file_results = 0;
    N_directory_results = 0;

    for i=1:N_entries
        entry = listing(i);
        
        file_path = fullfile(entry.folder, entry.name);
        
        if isKey(exclude, file_path)
            continue
        end
    
        if entry.isdir
                
            if strcmp('.', entry.name) || strcmp('..', entry.name)
                continue
            end

            N_directory_results = N_directory_results + 1;
            directory_paths{N_directory_results, 1} = file_path;
        else
            N_file_results = N_file_results + 1;
            file_paths{N_file_results, 1} = file_path;
        end
    end

    file_paths = file_paths(1:N_file_results);
    directory_paths = directory_paths(1:N_directory_results);
end
