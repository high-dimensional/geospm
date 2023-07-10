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

classdef SliceShapes < hdng.experiments.ValueContent
    %SliceShapes Summary.
    %   Detailed description 
    
    properties
        origin
        span
        resolution
        shape_paths
        slice_names
        source_ref
    end
    
    methods
        
        function obj = SliceShapes()
            
            obj = obj@hdng.experiments.ValueContent();
            
            obj.origin = [];
            obj.span = [];
            obj.resolution = [];
            obj.shape_paths = [];
            obj.slice_names = [];
            obj.source_ref = '';
        end
        
        function [serialised_value, type_identifier] = as_serialised_value_and_type(obj)
            
            serialised_value = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            if ~isempty(obj.origin)
                
                value = hdng.experiments.Value.from(obj.origin);
                
                content = containers.Map('KeyType', 'char', 'ValueType', 'any');
                content('content') = value.serialised;
                content('content_type') = value.type_identifier;

                serialised_value('origin') = content;
            end

            if ~isempty(obj.span)
                
                value = hdng.experiments.Value.from(obj.span);
                
                content = containers.Map('KeyType', 'char', 'ValueType', 'any');
                content('content') = value.serialised;
                content('content_type') = value.type_identifier;

                serialised_value('span') = content;
            end

            if ~isempty(obj.resolution)
                
                value = hdng.experiments.Value.from(obj.resolution);
                
                content = containers.Map('KeyType', 'char', 'ValueType', 'any');
                content('content') = value.serialised;
                content('content_type') = value.type_identifier;

                serialised_value('resolution') = content;
            end
            
            if ~isempty(obj.shape_paths)
                
                value = hdng.experiments.Value.from(obj.shape_paths);
                
                content = containers.Map('KeyType', 'char', 'ValueType', 'any');
                content('content') = value.serialised;
                content('content_type') = value.type_identifier;

                serialised_value('shape_paths') = content;
            end

            if ~isempty(obj.slice_names)
                
                value = hdng.experiments.Value.from(obj.slice_names);
                
                content = containers.Map('KeyType', 'char', 'ValueType', 'any');
                content('content') = value.serialised;
                content('content_type') = value.type_identifier;
                
                serialised_value('slice_names') = content;
            end

            serialised_value('source_ref') = obj.source_ref;
            
            type_identifier = 'builtin.slice_shapes';
        end
        
        function result = label_for_content(~)
        	result = 'Slice Shapes';
        end
    end
    
    methods (Static)
        
        function result = from_serialised_value_and_type(serialised_value, type_identifier) %#ok<INUSD>
            
            if ~isa(serialised_value, 'containers.Map')
                error('hdng.experiments.SliceShapes.from_serialised_value_and_type(): Expected serialised value to be a containers.Map instance.');
            end
            
            result = hdng.experiments.SliceShapes();
            
            if isKey(serialised_value, 'origin')
                
                origin = serialised_value('origin');
                result.origin = cell2mat(hdng.experiments.Value.load_from_proxy(origin).content);
            end
            
            if isKey(serialised_value, 'span')
                
                span = serialised_value('span');
                result.span = cell2mat(hdng.experiments.Value.load_from_proxy(span).content);
            end
            
            if isKey(serialised_value, 'resolution')
                
                resolution = serialised_value('resolution');
                result.resolution = cell2mat(hdng.experiments.Value.load_from_proxy(resolution).content);
            end

            if isKey(serialised_value, 'shape_paths')
                
                shape_paths = serialised_value('shape_paths');
                result.shape_paths = hdng.experiments.Value.load_from_proxy(shape_paths).content;
            end
            
            if isKey(serialised_value, 'slice_names')
                
                slice_names = serialised_value('slice_names');
                result.slice_names = hdng.experiments.Value.load_from_proxy(slice_names).content;
            end
            
            if isKey(serialised_value, 'source_ref')
                
                source_ref = serialised_value('source_ref');
                result.source_ref =source_ref;
            end
        end
    end
end
