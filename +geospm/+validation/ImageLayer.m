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

classdef ImageLayer < geospm.validation.PresentationLayer
    %ImageLayer Summary.
    %   Detailed description 
    
    properties
        image
    end
    
    methods
        
        function obj = ImageLayer()
            
            obj = obj@geospm.validation.PresentationLayer();
            obj.image = [];
        end
        
        function [serialised_value, type_identifier] = as_serialised_value_and_type(obj)
            
            [serialised_value, ~] = as_serialised_value_and_type@geospm.validation.PresentationLayer(obj);
            
            if ~isempty(obj.image)
                
                [serialised_image, image_type] = obj.image.as_serialised_value_and_type();
                
                content = containers.Map('KeyType', 'char', 'ValueType', 'any');
                content('content') = serialised_image;
                content('content_type') = image_type;
                
                serialised_value('image') = content;
            end

            type_identifier = 'builtin.image_layer';
        end
        
        function result = label_for_content(obj)
        	result = 'Image Layer';
            
            if ~isempty(obj.image)
                result = [result ' at ' obj.image.path];
            end
        end
    end
   
    methods (Static)
        
        function result = from_serialised_value_and_type(serialised_value, type_identifier, result)
            
            if ~exist('result', 'var') || isempty(result)
                result = geospm.validation.ImageLayer();
            end
            
            geospm.validation.PresentationLayer.from_serialised_value_and_type(serialised_value, type_identifier, result);

            
            if isKey(serialised_value, 'image')
                
                image = serialised_value('image');
                result.image = hdng.experiments.Value.load_from_proxy(image).content;
            end
        end
        
    end
end
