% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2019,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef ImageReference < hdng.experiments.FileReference
    %ImageReference Summary.
    %   Detailed description 
    
    properties
    end
    
    methods
        
        function obj = ImageReference(path, source_ref)
            
            if ~exist('path', 'var')
                path = '';
            end
            
            if ~exist('source_ref', 'var')
                source_ref = '';
            end
            
            obj = obj@hdng.experiments.FileReference(path, source_ref);
        end
        
        function [serialised_value, type_identifier] = as_serialised_value_and_type(obj)
            serialised_value = as_serialised_value_and_type@hdng.experiments.FileReference(obj);
            type_identifier = 'builtin.image_file';
        end
        
        function result = label_for_content(obj)
        	result = obj.path;
        end
        
        function result = load(obj, base_path)
            
            path = obj.resolve_path_relative_to(base_path);
            
            [~, ~, ext] = fileparts(path);
            
            if strcmpi(ext, '.nii')
                V = spm_vol(path);
                data = spm_read_vols(V);
                result = data;
            else
                error(['hdng.experiments.ImageReference.load(): Unsupported file type ''' ext '''']);
            end
        end
    end
    
    methods (Static)
        
        function result = from_serialised_value_and_type(serialised_value, type_identifier)
            result = from_serialised_value_and_type@hdng.experiments.FileReference(serialised_value, type_identifier);
            result = hdng.experiments.ImageReference(result.path, result.source_ref);
        end
    end
end
