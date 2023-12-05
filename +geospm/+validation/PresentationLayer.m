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

classdef PresentationLayer < hdng.experiments.ValueContent
    %PresentationLayer Summary.
    %   Detailed description 
    
    properties
        identifier
        category
        priority
        blend_mode
        opacity
    end

    properties (Dependent, Transient)
        x
        y
        width
        height
    end

    methods
        
        function obj = PresentationLayer()
            
            obj = obj@hdng.experiments.ValueContent();
            
            obj.identifier = '';
            obj.category = 'underlay';
            obj.priority = 0;
            obj.blend_mode = 'normal';
            obj.opacity = 1.0;
        end

        function result = get.x(obj)
            result = obj.access_x();
        end

        function result = get.y(obj)
            result = obj.access_y();
        end

        function result = get.width(obj)
            result = obj.access_width();
        end

        function result = get.height(obj)
            result = obj.access_height();
        end
        
        function [serialised_value, type_identifier] = as_serialised_value_and_type(obj)
            
            serialised_value = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            serialised_value('identifier') = obj.identifier;
            serialised_value('category') = obj.category;
            serialised_value('priority') = obj.priority;
            serialised_value('blend_mode') = obj.blend_mode;
            serialised_value('opacity') = obj.opacity;

            
            type_identifier = 'builtin.presentation_layer';
        end
        
        function result = label_for_content(~)
        	result = 'Presentation Layer';
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
        
        function result = from_serialised_value_and_type(serialised_value, type_identifier, result) %#ok<INUSL> 
            
            if ~isa(serialised_value, 'containers.Map')
                error('geospm.validation.PresentationLayer.from_serialised_value_and_type(): Expected serialised value to be a containers.Map instance.');
            end

            if ~exist('result', 'var') || isempty(result)
                result = geospm.validation.PresentationLayer();
            end
            
            if isKey(serialised_value, 'identifier')
                
                identifier = serialised_value('identifier');
                result.identifier = identifier;
            end
            
            if isKey(serialised_value, 'category')
                
                category = serialised_value('category');
                result.category = category;
            end
            
            if isKey(serialised_value, 'priority')
                
                priority = serialised_value('priority');
                result.priority = priority;
            end
            
            if isKey(serialised_value, 'blend_mode')
                
                blend_mode = serialised_value('blend_mode');
                result.blend_mode = blend_mode;
            end
            
            if isKey(serialised_value, 'opacity')
                
                opacity = serialised_value('opacity');
                result.opacity = opacity;
            end
        end
    end
end
