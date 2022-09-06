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


classdef ImageEntry < hdng.aggregate.FileAggregatorEntry
    
    properties
        final_data
        final_file
        
        target_file
        target_data
        
        image_data
    end
    
    methods
        
        function obj = ImageEntry(name, category, options)
            
            if ~isfield(options, 'write_nii')
                options.write_nii = false;
            end
            
            obj = obj@hdng.aggregate.FileAggregatorEntry(name, category, options);
            
            obj.final_data = [];
            obj.final_file = [];
            
            obj.target_file = '';
            obj.target_data = [];

            obj.image_data = [];
        end

        function prepare(obj)
            
            obj.final_data = [];
            obj.final_file = [];
            
            obj.target_file = '';
            obj.target_data = [];
            
            obj.image_data = [];
        end
        
        function gather_sample(obj, sample_file)
            
            [~, sample_name, sample_ext] = fileparts(sample_file);
            
            is_image = false;
            is_volume = false;

            if strcmp(sample_ext, '.png')
                is_image = true;
            elseif strcmp(sample_ext, '.nii')
                is_volume = true;
            else
                return
            end

            if strcmp(sample_name, 'target')

                raw_target_data = imread(sample_file);

                if islogical(raw_target_data)
                    raw_target_data = cast(raw_target_data, 'double');
                else
                    raw_target_data = cast(raw_target_data, 'double') ./ 255.0;
                end

                obj.target_file = sample_file;
                obj.target_data = raw_target_data .* 0.5 + 0.5;
            else

                if is_image
                    sample_data = imread(sample_file);
                    sample_data = cast(sample_data, 'double') ./ 255.0;
                elseif is_volume
                    sample_data = geospm.utilities.read_nifti(sample_file);
                else
                    sample_data = [];
                end

                obj.from_files{end + 1} = sample_file;

                if isempty(obj.image_data)
                    obj.image_data = sample_data;
                else
                    obj.image_data = obj.image_data + sample_data;
                end
            end
        end

        function finalise(obj)
            N_samples = numel(obj.from_files);
            obj.image_data = obj.image_data ./ N_samples;
        end
        
        function process(obj, output_directory)

            output_directory = obj.make_output_path(output_directory);
            
            final_image_data = obj.image_data;

            if ~isempty(obj.options.apply_colormap)
                cm = str2func(obj.options.apply_colormap);
                cm = cm(1024);
                cm(1, :) = [1, 1, 1];
                final_image_data = cast(final_image_data .* 1023.0, 'uint32');
                final_image_data = ind2rgb(final_image_data(:, :, 1), cm);
            end

            if obj.options.overlay_target
                final_image_data = final_image_data .* 0.35 + final_image_data .* obj.target_data .* 0.3 + obj.target_data .* 0.35;
                %final_image_data = final_image_data .* obj.target_data;
            end

            final_image_data = cast(final_image_data * 255.0, 'uint8');

            output_path = [output_directory '.png'];
            obj.image_volume_write(final_image_data, output_path);

            obj.final_data = final_image_data;
            obj.final_file = output_path;

            if obj.options.write_nii
                
                [category_output_directory, file_name, ~] = fileparts(output_directory);
                
                output_path = fullfile(category_output_directory, [file_name '.nii']);
                geospm.utilities.write_nifti(obj.image_data, output_path);

                output_path = fullfile(category_output_directory, [file_name '_mask' '.nii']);
                geospm.utilities.write_nifti(cast(obj.image_data >= 0.5, 'double'), output_path);

                output_path = fullfile(category_output_directory, [file_name '_mask' '.png']);
                final_image_data = cast((obj.image_data >= 0.5) * 255.0, 'uint8');
                obj.image_volume_write(final_image_data, output_path);
            end

        end
    end
end

