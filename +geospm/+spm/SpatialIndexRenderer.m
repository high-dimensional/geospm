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

classdef SpatialIndexRenderer < geospm.spm.BaseGenerator
    %SpatialIndexRenderer Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    properties (GetAccess=public, SetAccess=private)
        spatial_indices
    end
        
    properties (Transient, Dependent)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = SpatialIndexRenderer(...
                          session_volume_directory, ...
                          varargin)


            obj = obj@geospm.spm.BaseGenerator(...
                      session_volume_directory, ...
                      varargin{:});
            
            obj.spatial_indices = {};
        end

        function index_number = register_spatial_index(obj, spatial_index)

            obj.spatial_indices = [obj.spatial_indices; {spatial_index}];
            index_number = numel(obj.spatial_indices);
        end

        function volume_paths = generate_volume_paths(obj, index_number)

            spatial_index = obj.spatial_indices{index_number};

            %One volume per segment
            N_volumes = spatial_index.S;
            
            volume_paths = cell(N_volumes, 1);
            
            for i=1:N_volumes
                
                %fprintf('Rendering volume %d\n', i);
                
                synthetic_path = obj.format_synthetic_volume_path(index_number, i);
                volume_paths{i} = synthetic_path;
            end
        end

        function [density, global_mask_path] = compute_volume_density(obj, index_number)

            spatial_index = obj.spatial_indices{index_number};

            %One volume per segment
            N_volumes = spatial_index.S;
            
            density = zeros(obj.volume_size);
            global_mask_path = obj.format_global_mask_path();
            
            for i=1:N_volumes
                
                %fprintf('Rendering volume %d\n', i);
                
                synthetic_path = obj.format_synthetic_volume_path(index_number, i);
                [~, density] = obj.smooth_synthetic_path(synthetic_path, density);
            end
        end

        function result = parse_specifier(obj, specifier)
            
            result = struct();

            result.type = '';
            result.text = specifier;
            result.directive = '';
            result.spatial_index = [];
            result.segment_number = [];

            [~, id, ~] = fileparts(specifier);
            
            parts = split(id, ';');
            
            if numel(parts) == 1
                result.type = 'directive';
                result.directive = id;
            else
                
                index_number = str2double(parts{1});
                segment_number = str2double(parts{2});

                spatial_index = obj.spatial_indices{index_number};

                result.type = 'segment';
                result.spatial_index = spatial_index;
                result.segment_number = segment_number;
            end
        end
        

    end
    
    methods (Access=protected)

        function [file_path, density] = smooth_synthetic_path(obj, synthetic_path, density)

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
        end
        
        function result = format_synthetic_volume_id(~, index_number, segment_number)
            
            result = [num2str(index_number, '%08d') ...
                      ';' num2str(segment_number, '%08d')];
        end
        
        function result = format_synthetic_volume_path(obj, index_number, segment_number)
            
            id = obj.format_synthetic_volume_id(index_number, segment_number);
            result = fullfile(obj.session_volume_directory, [id '.synth']);
        end
        
        function result = format_global_mask_path(obj)
            result = fullfile(obj.session_volume_directory, 'global_mask.synth');
        end
    end
end
