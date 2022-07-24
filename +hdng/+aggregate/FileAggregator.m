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


classdef FileAggregator < handle
    
    properties
        options
    end
    
    properties (GetAccess=private, SetAccess=private)
        entry_class
        group_class
    end
    
    methods
        
        function obj = FileAggregator(varargin)
            obj.options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(obj.options, 'entry_class')
                obj.options.entry_class = 'geospm.aggregate.ImageEntry';
            end
            
            if ~isfield(obj.options, 'group_class')
                obj.options.group_class = 'geospm.aggregate.ImageGroup';
            end
            
            if ~isfield(obj.options, 'apply_colormap')
                obj.options.apply_colormap = [];
            end

            if ~isfield(obj.options, 'overlay_target')
                obj.options.overlay_target = true;
            end

            if ~isfield(obj.options, 'plot_resolution')
                obj.options.plot_resolution = 200;
            end

            if ~isfield(obj.options, 'output_formats')
                obj.options.output_formats = {'png', 'eps'};
            end
            
            if ~isfield(obj.options, 'file_order')
                obj.options.file_order = [];
            end

            if ~isfield(obj.options, 'flat_output')
                obj.options.flat_output = true;
            end

            if ~isfield(obj.options, 'file_names')
                obj.options.file_names = {};
            end

            if ~isfield(obj.options, 'file_name_map')
                obj.options.file_name_map = {};
            end
            
            file_name_map = containers.Map('KeyType', 'char', 'ValueType', 'char');
            
            for index=1:2:numel(obj.options.file_name_map)
                key = obj.options.file_name_map{index};
                value = obj.options.file_name_map{index + 1};
                %fprintf('file_name_map: %s = %s\n', key, value);
                file_name_map(key) = value;
            end
            
            obj.options.file_name_map = file_name_map;
            
            if ~isfield(obj.options, 'sample_names')
                obj.options.sample_names = {};
            end
            
            obj.entry_class = str2func(obj.options.entry_class);
            obj.group_class = str2func(obj.options.group_class);
        end

        function aggregate(obj, scan_directory, output_directory)

            % File system layout:
            % category > file > sample
            
            [parent_directory, scan_name, ~] = fileparts(scan_directory);

            output_name = scan_name;

            if ~exist('output_directory', 'var')
                output_directory = parent_directory;
                output_name = [scan_name '_aggregate'];
            end


            file_name_set = containers.Map('KeyType', 'char', 'ValueType', 'logical');

            for index=1:numel(obj.options.file_names)
                file_name = obj.options.file_names{index};
                file_name_set(file_name) = true;
            end

            sample_name_set = containers.Map('KeyType', 'char', 'ValueType', 'logical');

            for index=1:numel(obj.options.sample_names)
                sample_name = obj.options.sample_names{index};
                sample_name_set(sample_name) = true;
            end

            file_order = hdng.utilities.OrderedMap('KeyType', 'char', 'ValueType', 'any');

            for index=1:numel(obj.options.file_order)
                file_key = obj.options.file_order{index};
                file_order(file_key) = index;
            end

            output_directory = fullfile(output_directory, output_name);
            
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
            
            % gather file entries

            file_dict = hdng.utilities.OrderedMap('KeyType', 'char', 'ValueType', 'any');
            group_dict = hdng.utilities.OrderedMap('KeyType', 'char', 'ValueType', 'any');
            sample_counts = hdng.utilities.OrderedMap('KeyType', 'double', 'ValueType', 'logical');
            
            for index=1:numel(category_directories)
                category_directory = category_directories{index};

                [~, category_name, category_ext] = fileparts(category_directory);
                category_name = [category_name category_ext]; %#ok<AGROW>

                [~, file_directories] = hdng.utilities.list_files(category_directory);

                file_directories = obj.order_directories(file_directories, file_order);

                for file_index=1:numel(file_directories)

                    file_directory = file_directories{file_index};
                    [~, file_name, image_ext] = fileparts(file_directory);
                    file_name = [file_name image_ext]; %#ok<AGROW>

                    if ~isempty(file_name_set) && ~isKey(file_name_set, file_name)
                        continue
                    end

                    entry = obj.create_file_entry(category_name, file_name);
                    
                    entry.prepare();

                    sample_files = hdng.utilities.list_files(file_directory);

                    for sample_index=1:numel(sample_files)
                        sample_file = sample_files{sample_index};
                        [~, sample_name, ~] = fileparts(sample_file);

                        if ~isempty(sample_name_set) && ~isKey(sample_name_set, sample_name)
                            continue
                        end

                        entry.gather_sample(sample_file);
                    end

                    entry.finalise();

                    file_dict(entry.key) = entry;

                    if ~isKey(group_dict, entry.name)
                        group_dict(entry.name) = {entry.key};
                    else
                        group_dict(entry.name) = [group_dict(entry.name); {entry.key}];
                    end

                    sample_counts(numel(entry.from_files)) = true;

                    fprintf('%d samples for entry %s\n', numel(entry.from_files), entry.key);
                end
            end

            if sample_counts.length > 1
                warning('hdng.utilities.FileAggregator.aggregate(): Unequal sample counts in aggregate.');
            end

            % process file entries
            
            file_keys = file_dict.keys();

            for index=1:numel(file_keys)

                file_key = file_keys{index};
                entry = file_dict(file_key);
                
                entry.process(output_directory);
            end

            % aggregate entries per group
            
            group_keys = group_dict.keys();

            for index=1:numel(group_keys)
                
                group_key = group_keys{index};
                file_keys = group_dict(group_key);
                
                group = obj.create_group(group_key, 'horizontal');
                group.prepare();

                for k=1:numel(file_keys)
                    
                    entry = file_dict(file_keys{k});
                    
                    group.gather_entry(entry);
                end
                
                group.finalise();
                
                group_dict(group_key) = group;
            end

            % aggregate groups
            
            full_group = obj.create_group(scan_name, 'vertical');
            full_group.prepare();
            
            for index=1:numel(group_keys)
                
                group_key = group_keys{index};
                
                group = group_dict(group_key);
                full_group.gather_group(group);
            end
            
            [parent_directory, ~, ~] = fileparts(output_directory);
            
            full_group.finalise();
            full_group.process(parent_directory);
        end

        function directories = order_directories(~, directories, name_order)

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


        function entry = create_file_entry(obj, category_name, file_name)
            entry = obj.entry_class(file_name, category_name, obj.options);
        end

        function group = create_group(obj, name, mode)
            group = obj.group_class(name, mode, obj.options);
        end

    end
end

