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

classdef SliceShapesLayer < geospm.validation.PresentationLayer
    %VolumeLayer Summary.
    %   Detailed description 
    
    properties
        origin
        span
        resolution
        shape_paths
        slice_map
        source_ref
    end

    properties (Dependent, Transient)
        slice_names
    end
    
    methods
        
        function obj = SliceShapesLayer()
            
            obj = obj@geospm.validation.PresentationLayer();


            obj.origin = [];
            obj.span = [];
            obj.resolution = [];
            obj.shape_paths = [];
            obj.slice_map = hdng.experiments.SliceMap(0);
            obj.source_ref = '';
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

            type_identifier = 'builtin.slice_shapes_layer';
        end
        
        function result = label_for_content(obj)
        	result = 'Slice Shapes Layer';
            
            if ~isempty(obj.image)
                result = [result ' at ' obj.image.path];
            end
        end
    end

    methods (Access=protected)
        function result = access_x(~)
            result = [];
        end
        
        function result = access_y(~)
            result = [];
        end
        
        function result = access_width(~)
            result = [];
        end

        function result = access_height(~)
            result = [];
        end
    end
   
    methods (Static)
        
        function result = from_serialised_value_and_type(serialised_value, type_identifier, result)
            
            if ~exist('result', 'var') || isempty(result)
                result = geospm.validation.SliceShapesLayer();
            end
            
            geospm.validation.PresentationLayer.from_serialised_value_and_type(serialised_value, type_identifier, result);

            
            if isKey(serialised_value, 'scalars')
                
                scalars = serialised_value('scalars');
                result.scalars = hdng.experiments.Value.load_from_proxy(scalars).content;
            end
        end
        
    end
end
