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
        image_volume_set
        alpha_volume_set
        render_settings
        output_directory
    end
    
    properties (Dependent, Transient)
        image_volume_paths
        alpha_volume_paths
    end
    
    
    properties (GetAccess=private, SetAccess=private)
        
    end
    
    methods
        
        function obj = RenderContext(image_volume_set, alpha_volume_set, render_settings)
            
            obj.image_volume_set = image_volume_set;
            obj.alpha_volume_set = alpha_volume_set;
            
            obj.render_settings = render_settings;
            obj.output_directory = '';
        end
        
        function result = get.image_volume_paths(~)
            result = obj.image_volume_set.volume_selector(obj);
        end
        
        function result = get.alpha_volume_paths(~)
            result = obj.alpha_volume_set.volume_selector(obj);
        end
        
        function result = load_image_volumes(obj)
            result = obj.load_volumes(obj.image_volume_paths);
        end
        
        function result = load_alpha_volumes(obj)
            result = obj.load_volumes(obj.alpha_volume_paths);
        end
        
        function result = load_volumes(obj, paths)
            
            result = cell(numel(paths), 1);
            
            for i=1:numel(paths)

                file_path = paths{i};
                
                V = spm_vol(file_path);
                data_volume = spm_read_vols(V);

                [~, file_name, ~] = fileparts(file_path);
                
                image_path = fullfile(obj.output_directory, file_name);
                result{i} = hdng.images.ImageVolume(data_volume, '', image_path);
            end
        end
    end
end
