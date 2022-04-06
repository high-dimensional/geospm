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

classdef WKTAuditScope < matlab.mixin.Copyable
    %WKTAuditScope Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        
    anonymous_attributes
    named_attributes
        
    end
    
    methods
        
        function obj = WKTAuditScope()
            obj.anonymous_attributes = cell(0,1);
            obj.named_attributes = struct();
        end
        
        function add_anonymous_attribute(obj, value)
            obj.anonymous_attributes{end + 1, 1} = value;
        end
        
        function add_named_attribute(obj, name, value)
            
            if ~isfield(obj.named_attributes, name)
                named_attribute = struct();
                named_attribute.instances = cell(0,1); 
            else
                named_attribute = obj.named_attributes.(name);
            end 
                
            instance = struct();
            instance.value = value;
            instance.index = size(fieldnames(obj.named_attributes), 1) + 1;
            instance.position = obj.count_named_attributes() + 1;
            
            named_attribute.instances{end + 1, 1} = instance;
            obj.named_attributes.(name) = named_attribute;
        end
        
        function result = count_named_attributes(obj)
            
            result = 0;
            primitives = fieldnames(obj.named_attributes);
            
            for i=1:numel(primitives)
                instances = obj.named_attributes.(primitives{i}).instances;
                result = result + numel(instances);
            end
        end
        
        function value = size_of_named_attribute(obj, name)
            
            if ~isfield(obj.named_attributes, name)
                value = 0;
                return;
            end
            
            named_attribute = obj.named_attributes.(name);
            value = size(named_attribute.instances, 1);
        end
            
        function value = get_nth_named_attribute(obj, name, index, default_value)
            
            if ~isfield(obj.named_attributes, name)
                value = default_value;
                return;
            end
            
            named_attribute = obj.named_attributes.(name);
            
            if index > size(named_attribute.instances, 1)
                value = default_value;
                return;
            end
            
            value = named_attribute.instances{index, 1}.value;
        end
    end
end
