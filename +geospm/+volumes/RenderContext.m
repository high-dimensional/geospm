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

classdef RenderContext < handle
    
    %RenderContext 
    %
    
    properties (GetAccess=public, SetAccess=private)
    end
    
    properties (GetAccess=public, SetAccess=public)
        image_volumes
        alpha_volumes
        render_settings
        output_directory
    end
    
    properties (Dependent, Transient)
        image_volume_paths
        alpha_volume_paths
        
        image_volume_output_names
        image_volume_descriptions
    end
    
    
    properties (GetAccess=private, SetAccess=private)
        
    end
    
    methods
        
        function obj = RenderContext()
            
            obj.image_volumes = geospm.volumes.VolumeSet.empty;
            obj.alpha_volumes = geospm.volumes.VolumeSet.empty;
            
            obj.render_settings = geospm.volumes.RenderSettings.empty;
            obj.output_directory = '';
        end
        
        
        function result = get.image_volume_paths(obj)
            result = {};
            
            if ~isempty(obj.image_volumes)
                result = obj.image_volumes.locate_file_paths(obj);
            end
        end
        
        function result = get.alpha_volume_paths(obj)
            
            result = {};
            
            if ~isempty(obj.alpha_volumes)
                result = obj.alpha_volumes.locate_file_paths(obj);
            end
        end
        
        function result = get.image_volume_descriptions(obj)
            result = {};
            
            if ~isempty(obj.image_volumes)
                result = obj.image_volumes.format_descriptions(obj);
            end
        end
        
        function result = get.image_volume_output_names(obj)
            result = {};
            
            if ~isempty(obj.image_volumes)
                result = obj.image_volumes.optional_output_names;
            end
        end
        
        function result = load_image_volumes(obj)
            result = obj.load_volumes(obj.image_volume_paths, obj.image_volume_output_names);
        end
        
        function result = load_alpha_volumes(obj)
            result = obj.load_volumes(obj.alpha_volume_paths, {});
        end
        
        function result = load_volumes(obj, paths, optional_output_names)
            
            if ~exist('optional_output_names', 'var')
                optional_output_names = {};
            end
            
            result = cell(numel(paths), 1);
            descriptions = obj.image_volume_descriptions;
            
            if numel(descriptions) ~= numel(paths)
                descriptions = cell(numel(paths), 1);
                
                for i=1:numel(descriptions)
                    descriptions{i} = '';
                end
            end
            
            
            for i=1:numel(paths)
                
                file_path = paths{i};
                
                V = spm_vol(file_path);
                data_volume = spm_read_vols(V);
                
                [~, file_name, ~] = fileparts(file_path);

                if numel(optional_output_names) >= i
                    file_name = optional_output_names{i};
                end
                
                image_path = fullfile(obj.output_directory, file_name);
                result{i} = hdng.images.ImageVolume(data_volume, descriptions{i}, image_path);
            end
        end
        
    end
end
