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


classdef ImageGroup < hdng.aggregate.FileAggregatorGroup
    
    properties
        divider_size
        image
        alpha
    end
    
    methods
        
        function obj = ImageGroup(name, mode, options)
            
            obj = obj@hdng.aggregate.FileAggregatorGroup(name, mode, options);
            
            obj.divider_size = 2;
            
            switch obj.mode
                case 'horizontal'
                    obj.divider_size = options.horizontal_gap;
                    
                case 'vertical'
                    obj.divider_size = options.vertical_gap;
            end
            
            
            obj.image = [];
            obj.alpha = [];
        end
        
        function prepare(obj)
            obj.image = [];
            obj.alpha = [];
        end
        
        function gather_entry(obj, entry)
            
            obj.entries{end + 1} = entry;
            
            switch obj.mode
                case 'horizontal'
                    obj.append_image_x(entry.final_data)
                    
                case 'vertical'
                    obj.append.image_y(entry.final_data)
            end
        end
        
        function gather_group(obj, group)
            
            obj.entries{end + 1} = group;
            
            switch obj.mode
                case 'horizontal'
                    obj.append_image_x(group.image)
                    
                case 'vertical'
                    obj.append_image_y(group.image)
            end
        end
        
        function finalise(obj) %#ok<MANU>
        end
        
        function process(obj, output_directory)

            if isempty(obj.image) || isempty(obj.alpha)
                return
            end
            
            output_path = fullfile(output_directory, [obj.name '.png']);
            imwrite(obj.image, output_path, 'Alpha', obj.alpha);
        end
        
        function append_image_x(obj, image_data)
            
            if ~isempty(obj.image)
                divider = cast(ones(size(image_data, 1), obj.divider_size, size(image_data, 3)) * 255.0, 'uint8');
            else
                divider = [];
            end

            tmp_alpha = cast(ones(size(image_data, 1), size(image_data, 2)) * 255.0, 'uint8');
            alpha_divider = cast(255 - divider(:, :, 1), 'uint8');

            obj.image = cat(2, obj.image, divider, image_data);
            obj.alpha = cat(2, obj.alpha, alpha_divider, tmp_alpha);
        end

        function append_image_y(obj, image_data)

            if ~isempty(obj.image)
                divider = cast(ones(obj.divider_size, size(image_data, 2), size(image_data, 3)) * 255.0, 'uint8');
            else
                divider = [];
            end

            tmp_alpha = cast(ones(size(image_data, 1), size(image_data, 2)) * 255.0, 'uint8');
            alpha_divider = cast(255 - divider(:, :, 1), 'uint8');

            obj.image = cat(1, obj.image, divider, image_data);
            obj.alpha = cat(1, obj.alpha, alpha_divider, tmp_alpha);
        end
    end
end

