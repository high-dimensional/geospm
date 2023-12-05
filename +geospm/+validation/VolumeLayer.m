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

classdef VolumeLayer < geospm.validation.ImageLayer
    %VolumeLayer Summary.
    %   Detailed description 
    
    properties
        scalars
        slice_map
    end

    properties (Dependent, Transient)
        slice_names
    end
    
    methods
        
        function obj = VolumeLayer()
            
            obj = obj@geospm.validation.ImageLayer();
            obj.scalars = [];
            obj.slice_map = hdng.experiments.SliceMap(0);
        end

        function result = get.slice_names(obj)
            result = obj.slice_maps.slice_names;
        end
        
        function set.slice_names(obj, values)
            obj.slice_map = hdng.experiments.SliceMap(values);
        end

        function [serialised_value, type_identifier] = as_serialised_value_and_type(obj)
            
            [serialised_value, ~] = as_serialised_value_and_type@geospm.validation.ImageLayer(obj);
            
            if ~isempty(obj.scalars)
                
                [serialised_scalars, scalars_type] = obj.scalars.as_serialised_value_and_type();
                
                content = containers.Map('KeyType', 'char', 'ValueType', 'any');
                content('content') = serialised_scalars;
                content('content_type') = scalars_type;
                
                serialised_value('scalars') = content;
            end

            type_identifier = 'builtin.volume_layer';
        end
        
        function result = label_for_content(obj)
        	result = 'Volume Layer';
            
            if ~isempty(obj.image)
                result = [result ' at ' obj.image.path];
            end
        end
    end

    methods (Access=protected)
        
        function [x, y, width, height] = determine_extent(obj)
            x = [];
            y = [];
            width = [];
            height = [];

            if isempty(obj.image)
                return;
            end
            
            [~, name, ~] = fileparts(obj.image.path);

            match = regexp(name, '\((?<z>\d+)@(?<width>\d+),(?<height>\d+)\)', 'names');

            if isempty(match)
                return;
            end
            
            x = 0;
            y = 0;
            width = str2double(match.width);
            height = str2double(match.height);
        end

        function result = access_x(obj)
            [result, ~, ~, ~] = obj.determine_extent();
        end
        
        function result = access_y(obj)
            [~, result, ~, ~] = obj.determine_extent();
        end
        
        function result = access_width(obj)
            [~, ~, result, ~] = obj.determine_extent();
        end
        
        function result = access_height(obj)
            [~, ~, ~, result] = obj.determine_extent();
        end
    end

    methods (Static)
        
        function result = from_serialised_value_and_type(serialised_value, type_identifier, result)
            
            if ~exist('result', 'var') || isempty(result)
                result = geospm.validation.VolumeLayer();
            end
            
            geospm.validation.PresentationLayer.from_serialised_value_and_type(serialised_value, type_identifier, result);
            
            if isKey(serialised_value, 'scalars')
                
                scalars = serialised_value('scalars');
                result.scalars = hdng.experiments.Value.load_from_proxy(scalars).content;
            end
        end
        
    end
end
