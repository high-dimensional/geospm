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

classdef ModelSamples < hdng.experiments.ValueContent
    %ModelSamples Summary.
    %   Detailed description 
    
    properties
        file
        image
    end
    
    methods
        
        function obj = ModelSamples()
            
            obj = obj@hdng.experiments.ValueContent();
            
            obj.file = [];
            obj.image = [];
        end
        
        function [serialised_value, type_identifier] = as_serialised_value_and_type(obj)
            
            serialised_value = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            if ~isempty(obj.file)
                
                [serialised_file, file_type] = obj.file.as_serialised_value_and_type();
                
                content = containers.Map('KeyType', 'char', 'ValueType', 'any');
                content('content') = serialised_file;
                content('content_type') = file_type;
                
                serialised_value('file') = content;
            end
            
            if ~isempty(obj.image)
                
                [serialised_image, image_type] = obj.image.as_serialised_value_and_type();
                
                content = containers.Map('KeyType', 'char', 'ValueType', 'any');
                content('content') = serialised_image;
                content('content_type') = image_type;
                
                serialised_value('image') = content;
            end
            
            type_identifier = 'builtin.model_samples';
        end
        
        function result = label_for_content(obj)
        	result = 'Model Samples';
            
            if ~isempty(obj.file)
                result = [result ' at ' obj.file.path];
            end
        end
    end
   
    methods (Static)
        
        function result = from_serialised_value_and_type(serialised_value, type_identifier) %#ok<INUSD>
            
            if ~isa(serialised_value, 'containers.Map')
                error('geospm.validation.ModelSamples.from_serialised_value_and_type(): Expected serialised value to be a containers.Map instance.');
            end
            
            result = geospm.validation.ModelSamples();
            
            if isKey(serialised_value, 'file')
                
                file = serialised_value('file');
                result.file = hdng.experiments.Value.load_from_proxy(file).content;
            end
            
            if isKey(serialised_value, 'image')
                
                image = serialised_value('image');
                result.image = hdng.experiments.Value.load_from_proxy(image).content;
            end
        end
        
    end
end
