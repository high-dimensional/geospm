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

classdef SliceReference < hdng.experiments.ImageReference
    %SliceReference Summary.
    %   Detailed description 
    
    properties
        slice
    end
    
    methods
        
        function obj = SliceReference(path, slice)
            
            if ~exist('path', 'var')
                path = '';
            end
            
            if ~exist('slice', 'var')
                slice = 0;
            end
            
            obj = obj@hdng.experiments.ImageReference(path);
            obj.slice = slice;
        end
        
        function [serialised_value, type_identifier] = as_serialised_value_and_type(obj)
            serialised_value = containers.Map('KeyType', 'char', 'ValueType', 'any');
            serialised_value('path') = obj.path;
            serialised_value('slice') = obj.slice;
            type_identifier = 'builtin.image_slice';
        end
        
        function result = label_for_content(obj)
        	result = [obj.path ':' num2str(obj.slice)];
        end
        
        function result = load(obj, base_path)
            
            data = load@hdng.experiments.ImageReference(obj, base_path);
            
            if obj.slice == 0
                result = data;
            else
                result = data(:,:, obj.slice);
            end
        end
    end
    
end
