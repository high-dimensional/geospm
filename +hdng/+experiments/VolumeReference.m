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

classdef VolumeReference < hdng.experiments.ValueContent
    %VolumeReference Summary.
    %   Detailed description 
    
    properties
        image
        scalars
        slice_names
    end
    
    methods
        
        function obj = VolumeReference()
            
            obj = obj@hdng.experiments.ValueContent();
            
            obj.image = [];
            obj.scalars = [];
            obj.slice_names = [];
        end
        
        function [serialised_value, type_identifier] = as_serialised_value_and_type(obj)
            
            serialised_value = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            if ~isempty(obj.image)
                
                [serialised_image, image_type] = obj.image.as_serialised_value_and_type();
                
                content = containers.Map('KeyType', 'char', 'ValueType', 'any');
                content('content') = serialised_image;
                content('content_type') = image_type;
                
                serialised_value('image') = content;
            end
            
            if ~isempty(obj.scalars)
                
                [serialised_scalars, scalars_type] = obj.scalars.as_serialised_value_and_type();
                
                content = containers.Map('KeyType', 'char', 'ValueType', 'any');
                content('content') = serialised_scalars;
                content('content_type') = scalars_type;
                
                serialised_value('scalars') = content;
            end
            
            if ~isempty(obj.slice_names)
                
                value = hdng.experiments.Value.from(obj.slice_names);
                
                content = containers.Map('KeyType', 'char', 'ValueType', 'any');
                content('content') = value.serialised;
                content('content_type') = value.type_identifier;
                
                serialised_value('slice_names') = content;
            end
            
            type_identifier = 'builtin.volume';
        end
        
        function result = label_for_content(~)
        	result = 'Volume';
        end
    end
    
    methods (Static)
        
        function result = from_serialised_value_and_type(serialised_value, type_identifier)
            
            if ~isa(serialised_value, 'containers.Map')
                error('hdng.experiments.VolumeReference.from_serialised_value_and_type(): Expected serialised value to be a containers.Map instance.');
            end
            
            result = hdng.experiments.VolumeReference();
            
            if isKey(serialised_value, 'image')
                
                image = serialised_value('image');
                result.image = hdng.experiments.Value.load_from_proxy(image).content;
            end
            
            if isKey(serialised_value, 'scalars')
                
                scalars = serialised_value('scalars');
                result.scalars = hdng.experiments.Value.load_from_proxy(scalars).content;
            end
            
            if isKey(serialised_value, 'slice_names')
                
                slice_names = serialised_value('slice_names');
                result.slice_names = hdng.experiments.Value.load_from_proxy(slice_names).content;
            end
        end
    end
end
