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

classdef SingleKernelGenerator < geospm.spm.BaseGenerator
    %SingleKernelGenerator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    properties (GetAccess=public, SetAccess=private)
    end
        
    properties (Transient, Dependent)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = SingleKernelGenerator(...
                          session_volume_directory, ...
                          window_resolution, ...
                          precision, ...
                          smoothing_method, ...
                          smoothing_levels, ...
                          smoothing_levels_p_value, ...
                          smoothing_levels_as_z_dimension, ...
                          do_write_volumes, ...
                          overwrite_existing_volumes)
            
            obj = obj@geospm.spm.BaseGenerator(...
                      session_volume_directory, ...
                      window_resolution, ...
                      precision, ...
                      smoothing_method, ...
                      smoothing_levels, ...
                      smoothing_levels_p_value, ...
                      smoothing_levels_as_z_dimension, ...
                      do_write_volumes, ...
                      overwrite_existing_volumes);
        end


        function [volume_paths, density, global_mask_path] = synthesize_all(obj, specifiers)
            
            N_volumes = numel(specifiers);
            
            volume_paths = cell(N_volumes, 1);
            density = zeros(obj.volume_size);
            global_mask_path = obj.format_global_mask_path();
            
            for i=1:N_volumes
                
                %fprintf('Rendering volume %d\n', i);
                
                specifier = specifiers{i};
                synthetic_path = fullfile(specifier, [id '.synth']);
                
                synthetic_sample = obj.synthesize(synthetic_path);   
                density = density + synthetic_sample;
                
                if obj.do_write_volumes
                    
                    [session_path, id, ~] = fileparts(synthetic_path);
                    file_path = fullfile(session_path, [id '.nii']);
                    
                    V = obj.blank_spm_volume();
                    V.fname = file_path;

                    if obj.overwrite_existing_volumes || exist(file_path, 'file') == 0
                        dim = ones(1, 3);
                        unsafe_size = size(synthetic_sample);
                        dim(1:numel(unsafe_size)) = unsafe_size;
                        V.dim = dim;
                        spm_write_vol(V, synthetic_sample);
                    end
                else
                    file_path = synthetic_path;
                end

                volume_paths{i} = file_path;
            end
        end

        function [volume_paths, density, global_mask_path] = smooth_samples(obj, identifiers, x, y, z)
            
            N_volumes = numel(identifiers);
            
            volume_paths = cell(N_volumes, 1);
            density = zeros(obj.volume_size);
            global_mask_path = obj.format_global_mask_path();
            
            for i=1:N_volumes
                
                %fprintf('Rendering volume %d\n', i);

                identifier = identifiers{i};
                synthetic_path = obj.format_synthetic_volume_path(identifier, x(i), y(i), z(i));
                
                synthetic_sample = obj.synthesize(synthetic_path);   
                density = density + synthetic_sample;
                
                if obj.do_write_volumes
                    
                    [session_path, id, ~] = fileparts(synthetic_path);
                    file_path = fullfile(session_path, [id '.nii']);
                    
                    V = obj.blank_spm_volume();
                    V.fname = file_path;

                    if obj.overwrite_existing_volumes || exist(file_path, 'file') == 0
                        dim = ones(1, 3);
                        unsafe_size = size(synthetic_sample);
                        dim(1:numel(unsafe_size)) = unsafe_size;
                        V.dim = dim;
                        spm_write_vol(V, synthetic_sample);
                    end
                else
                    file_path = synthetic_path;
                end

                volume_paths{i} = file_path;
            end
        end
        
    end
    
    methods (Access=protected)
        
        function [locations, identifiers] = parse_specifier(~, specifier)
            
            [~, id, ~] = fileparts(specifier);
            
            index_xyz = split(id, ';');
            
            if numel(index_xyz) == 1
                identifiers = {id};
                locations = [];
            else
                identifiers = index_xyz(1);
                locations = [str2double(index_xyz{2}), ...
                             str2double(index_xyz{3}), ...
                             str2double(index_xyz{4})];
            end
        end
        

        function result = format_synthetic_volume_id(~, identifier, x, y, z)
            
            result = [identifier ... % num2str(index, '%08d') ...
                      ';' num2str(x, '%06d') ...
                      ';' num2str(y, '%06d') ...
                      ';' num2str(z, '%06d')];
        end
        
        function result = format_synthetic_volume_path(obj, identifier, x, y, z)
            
            id = obj.format_synthetic_volume_id(identifier, x, y, z);
            result = fullfile(obj.session_volume_directory, [id '.synth']);
        end
        
        function result = format_global_mask_path(obj)
            result = fullfile(obj.session_volume_directory, 'global_mask.synth');
        end
    end
end
