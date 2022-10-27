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


classdef FileAggregatorEntry < handle
    
    properties
        category
        name
        from_files
        key
        
        options
    end
    
    methods
        
        function obj = FileAggregatorEntry(name, category, options)
            
            obj.name = name;
            obj.category = category;
            
            obj.from_files = {};
            obj.key = [obj.category '/' obj.name];
            
            obj.options = options;
        end
        
        
        function prepare(obj) %#ok<MANU>
        end
        
        function gather_sample(obj, sample_file) %#ok<INUSD>
        end

        function finalise(obj) %#ok<MANU>
        end
        
        function process(obj, output_directory) %#ok<INUSD>
        end
        
        function output_path = make_output_path(obj, output_directory)

            if obj.options.flat_output
                output_path = fullfile(output_directory, [obj.category '_' obj.name]);
            else
                category_output_directory = fullfile(output_directory, obj.category);

                [dirstatus, dirmsg] = mkdir(category_output_directory);
                if dirstatus ~= 1; error(dirmsg); end

                output_path = fullfile(category_output_directory, obj.name);
            end
        end
    end
    
    methods (Static)
        
        
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
    end
end

