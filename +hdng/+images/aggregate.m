% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2021,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function aggregate(scan_directory, varargin)
     
    options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    [parent_directory, scan_name, ~] = fileparts(scan_directory);
    
    output_name = scan_name;
    
    if ~isfield(options, 'output_directory')
        options.output_directory = parent_directory;
        output_name = [scan_name '_aggregate'];
    end
    
    if ~isfield(options, 'apply_colormap')
        options.apply_colormap = [];
    end
    
    if ~isfield(options, 'overlay_target')
        options.overlay_target = true;
    end
    
    if ~isfield(options, 'image_order')
        options.image_order = [];
    end
    
    if ~isfield(options, 'write_nii')
        options.write_nii = true;
    end
    
    if ~isfield(options, 'flat_output')
        options.flat_output = true;
    end
    
    image_order = hdng.utilities.OrderedMap('KeyType', 'char', 'ValueType', 'any');
    
    for index=1:numel(options.image_order)
        image_key = options.image_order{index};
        image_order(image_key) = index;
    end
    
    output_directory = fullfile(options.output_directory, output_name);
    
    [dirstatus, dirmsg] = mkdir(output_directory);
    if dirstatus ~= 1; error(dirmsg); end

    [~, category_directories] = hdng.utilities.list_files(scan_directory);
    
    category_names = cell(numel(category_directories), 1);
    category_numbers = nan(numel(category_directories), 1);
    
    for index=1:numel(category_directories)
        category_directory = category_directories{index};

        [~, category_name, category_ext] = fileparts(category_directory);
        category_name = [category_name category_ext]; %#ok<AGROW>
        category_number = str2double(category_name);
        
        category_names{index} = category_name;
        category_numbers(index) = category_number;
    end
    
    if all(~isnan(category_numbers))
        [~, order] = sort(category_numbers, 'ascend');
        category_directories = category_directories(order);
    end
    
    image_dict = hdng.utilities.OrderedMap('KeyType', 'char', 'ValueType', 'any');
    group_dict = hdng.utilities.OrderedMap('KeyType', 'char', 'ValueType', 'any');
    sample_counts = hdng.utilities.OrderedMap('KeyType', 'double', 'ValueType', 'logical');
    
    for index=1:numel(category_directories)
        category_directory = category_directories{index};

        [~, category_name, category_ext] = fileparts(category_directory);
        category_name = [category_name category_ext]; %#ok<AGROW>
        
        [~, image_directories] = hdng.utilities.list_files(category_directory);
        
        image_directories = order_directories(image_directories, image_order);
        
        for image_index=1:numel(image_directories)
            
            image_directory = image_directories{image_index};
            [~, image_name, image_ext] = fileparts(image_directory);
            image_name = [image_name image_ext]; %#ok<AGROW>
            
            image_data = [];
            target_data = [];
            used_target_file = [];
            
            sample_files = hdng.utilities.list_files(image_directory);
            used_sample_files = {};
            
            for sample_index=1:numel(sample_files)
                sample_file = sample_files{sample_index};
                [~, sample_name, sample_ext] = fileparts(sample_file);
                
                is_image = false;
                is_volume = false;
                
                if strcmp(sample_ext, '.png')
                    is_image = true;
                elseif strcmp(sample_ext, '.nii')
                    is_volume = true;
                else
                    continue;
                end
                
                if strcmp(sample_name, 'target')
                    used_target_file = sample_file;
                    target_data = imread(sample_file);
                    
                    if islogical(target_data)
                        target_data = cast(target_data, 'double');
                    else
                        target_data = cast(target_data, 'double') ./ 255.0;
                    end
                    
                    target_data = target_data .* 0.5 + 0.5;
                else
                    
                    used_sample_files{end + 1} = sample_file; %#ok<AGROW>
                    
                    if is_image
                        sample_data = imread(sample_file);
                        sample_data = cast(sample_data, 'double') ./ 255.0;
                    elseif is_volume
                        sample_data = geospm.utilities.read_nifti(sample_file);
                    else
                        sample_data = [];
                    end
                    
                    if isempty(image_data)
                        image_data = sample_data;
                    else
                        image_data = image_data + sample_data;
                    end
                end
            end
            
            N_samples = numel(used_sample_files);
            
            image_data = image_data ./ N_samples;
            
            entry = struct();
            entry.image_data = image_data;
            entry.category = category_name;
            entry.name = image_name;
            entry.from_files = used_sample_files;
            entry.key = [entry.category '/' entry.name];
            entry.target_data = target_data;
            entry.target_file = used_target_file;
            entry.final_data = [];
            entry.final_file = [];
            
            image_dict(entry.key) = entry;
            
            if ~isKey(group_dict, entry.name)
                group_dict(entry.name) = {entry.key};
            else
                group_dict(entry.name) = [group_dict(entry.name); {entry.key}];
            end
            
            sample_counts(numel(used_sample_files)) = true;
            
            fprintf('%d samples for entry %s\n', numel(used_sample_files), entry.key);
        end
    end
    
    if sample_counts.length > 1
        warning('hdng.images.aggregate(): Unequal sample counts in aggregate.');
    end
    
    image_keys = image_dict.keys();
    
    for index=1:numel(image_keys)
        image_key = image_keys{index};
        entry = image_dict(image_key);
        
        if options.flat_output
            image_path = fullfile(output_directory, [entry.category '_' entry.name '.png']);
        else
            category_output_directory = fullfile(output_directory, entry.category);

            [dirstatus, dirmsg] = mkdir(category_output_directory);
            if dirstatus ~= 1; error(dirmsg); end
            
            image_path = fullfile(category_output_directory, [entry.name '.png']);
        end
        
        image_data = entry.image_data;
        
        if ~isempty(options.apply_colormap)
            cm = str2func(options.apply_colormap);
            cm = cm(1024);
            cm(1, :) = [1, 1, 1];
            image_data = cast(image_data .* 1023.0, 'uint32');
            image_data = ind2rgb(image_data(:, :, 1), cm);
        end
        
        if options.overlay_target
            image_data = image_data .* 0.35 + image_data .* entry.target_data .* 0.3 + entry.target_data .* 0.35;
            %image_data = image_data .* entry.target_data;
        end
        
        image_data = cast(image_data * 255.0, 'uint8');
        
        image_volume_write(image_data, image_path);
        
        entry.final_data = image_data;
        entry.final_file = image_path;
        
        if options.write_nii
            
            if options.flat_output
                category_output_directory = output_directory;
                file_name = [entry.category '_' entry.name];
            else
                category_output_directory = fullfile(output_directory, entry.category);

                [dirstatus, dirmsg] = mkdir(category_output_directory);
                if dirstatus ~= 1; error(dirmsg); end
                file_name = entry.name;
            end
            

            image_path = fullfile(category_output_directory, [file_name '.nii']);
            geospm.utilities.write_nifti(entry.image_data, image_path);

            image_path = fullfile(category_output_directory, [file_name '_mask' '.nii']);
            geospm.utilities.write_nifti(cast(entry.image_data >= 0.5, 'double'), image_path);
            
            image_path = fullfile(category_output_directory, [file_name '_mask' '.png']);
            image_data = cast((entry.image_data >= 0.5) * 255.0, 'uint8');
            image_volume_write(image_data, image_path);
        end
        
        image_dict(image_key) = entry;
    end
    
    group_keys = group_dict.keys();
    
    for index=1:numel(group_keys)
        group_key = group_keys{index};
        image_keys = group_dict(group_key);
        entries = cell(numel(image_keys), 1);
        
        group_image = [];
        group_alpha = [];
        
        for k=1:numel(image_keys)
            entry = image_dict(image_keys{k});
            entries{k} = entry;
            
            [group_image, group_alpha] = append_image_x(group_image, group_alpha, entry.final_data);
        end
        
        group_image_path = fullfile(output_directory, [entry.name '.png']);
        imwrite(group_image, group_image_path, 'Alpha', group_alpha);
        
        entry = struct();
        entry.image_data = group_image;
        entry.image_keys = image_keys;
        
        group_dict(group_key) = entry;
    end
    
    full_image = [];
    full_alpha = [];
    
    for index=1:numel(group_keys)
        group_key = group_keys{index};
        entry = group_dict(group_key);
        
        [full_image, full_alpha] = append_image_y(full_image, full_alpha, entry.image_data);
    end
    
    full_image_path = fullfile(options.output_directory, [scan_name '.png']);
    imwrite(full_image, full_image_path, 'Alpha', full_alpha);
    
end

function directories = order_directories(directories, name_order)
    
    directories = sort(directories);
    names = cell(numel(directories), 1);
    indices = zeros(numel(directories), 1);
    
    for index=1:numel(directories)
        directory = directories{index};
        [~, name, ext] = fileparts(directory);
        name = [name ext]; %#ok<AGROW>
        names{index} = name;
        
        if isKey(name_order, name)
            indices(index) = name_order(name);
        end
    end
    
    [~, tmp_order] = sort(indices(indices ~= 0));
    
    tmp_directories = directories(indices ~= 0);
    directories = [tmp_directories(tmp_order), directories(indices == 0)];
end

function [group_image, group_alpha] = append_image_x(group_image, group_alpha, image)

    if ~isempty(group_image)
        divider = cast(ones(size(image, 1), 2, size(image, 3)) * 255.0, 'uint8');
    else
        divider = [];
    end

    alpha = cast(ones(size(image, 1), size(image, 2)) * 255.0, 'uint8');
    alpha_divider = cast(255 - divider(:, :, 1), 'uint8');

    group_image = cat(2, group_image, divider, image);
    group_alpha = cat(2, group_alpha, alpha_divider, alpha);
end

function [group_image, group_alpha] = append_image_y(group_image, group_alpha, image)

    if ~isempty(group_image)
        divider = cast(ones(2, size(image, 2), size(image, 3)) * 255.0, 'uint8');
    else
        divider = [];
    end
    
    alpha = cast(ones(size(image, 1), size(image, 2)) * 255.0, 'uint8');
    alpha_divider = cast(255 - divider(:, :, 1), 'uint8');

    group_image = cat(1, group_image, divider, image);
    group_alpha = cat(1, group_alpha, alpha_divider, alpha);
end

function image_volume_write(image_data, image_path)
    
    if size(image_data, 3) == 1
        imwrite(image_data, image_path);
    else
        
        slice_size = size(image_data);
        slice_size = slice_size(1:2);
        
        image_volume_data = [];
        
        for index=1:size(image_data, 3)
            image_slice_data = reshape(image_data(:, :, index), slice_size);
            image_slice_data = rot90(image_slice_data);
            image_volume_data = cat(1, image_volume_data, image_slice_data);
        end
        
        [parent, name, ~] = fileparts(image_path);
        
        image_path = [parent filesep name '(' num2str(size(image_data, 3)) '@' num2str(size(image_data, 1)) ',' num2str(size(image_data, 2)) ').png'];
        imwrite(image_volume_data, image_path);
    end
end
