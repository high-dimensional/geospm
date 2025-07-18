function result = scan_regional_directories(base_directory, suffix)

    [~, directories] = hdng.utilities.list_files(base_directory);

    result = hdng.one_struct('identifier', '', 'directory', '');
    result_index = 1;

    for index=1:numel(directories)
        directory = directories{index};

        region_path = fullfile(directory, 'region.txt');
        
        if ~exist(region_path, 'file')
            continue
        end
        
        region = hdng.utilities.load_text(region_path);
        
        result(result_index).identifier = [region suffix];
        result(result_index).directory = directory;

        result_index = result_index + 1;
    end
end
