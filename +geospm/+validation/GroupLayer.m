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

classdef GroupLayer < geospm.validation.PresentationLayer
    %GroupLayer Summary.
    %   Detailed description 
    
    properties
        sublayers
    end
    
    methods
        
        function obj = GroupLayer()
            
            obj = obj@geospm.validation.PresentationLayer();
            obj.sublayers = [];
        end
        
        function [serialised_value, type_identifier] = as_serialised_value_and_type(obj)
            
            [serialised_value, ~] = as_serialised_value_and_type@geospm.validation.PresentationLayer(obj);
            
            if ~isempty(obj.sublayers)
                
                [serialised_sublayers, value_type] = hdng.experiment.Value.from(obj.sublayers).as_serialised_value_and_type();
                
                content = containers.Map('KeyType', 'char', 'ValueType', 'any');
                content('content') = serialised_sublayers;
                content('content_type') = value_type;
                
                serialised_value('sublayers') = content;
            end

            type_identifier = 'builtin.group_layer';
        end
        
        function result = label_for_content(obj)
        	result = 'Group Layer';
        end
    end
   
    methods (Static)
        
        function result = from_serialised_value_and_type(serialised_value, type_identifier, result)
            
            if ~exist('result', 'var') || isempty(result)
                result = geospm.validation.ImageLayer();
            end
            
            geospm.validation.PresentationLayer.from_serialised_value_and_type(serialised_value, type_identifier, result);

            
            if isKey(serialised_value, 'sublayers')
                
                sublayers = serialised_value('sublayers');
                result.sublayers = hdng.experiments.Value.load_from_proxy(sublayers).content;
            end
        end
        
    end
end
