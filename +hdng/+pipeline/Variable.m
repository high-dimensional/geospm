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

classdef Variable < handle
    
    properties (Constant)
        PRODUCER_ROLE = 'producer'
        CONSUMER_ROLE = 'consumer'
        
        INPUT_ROLE = 'input'
        OUTPUT_ROLE = 'output'
    end
    
    properties (GetAccess=public, SetAccess=immutable)
        name
        nth_variable
    end
    
    properties (GetAccess=public, SetAccess=protected)
        objects_by_role
    end
    
    methods
        
        function obj = Variable(name, nth_variable)
            obj.name = name;
            obj.nth_variable = nth_variable;
            obj.objects_by_role = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end
        
        function register_object(obj, object, role)
            
            if ~isKey(obj.objects_by_role, role)
                entry = cell(0, 1);
            else
                entry = obj.objects_by_role(role);
            end
            
            entry{end + 1} = object;
            obj.objects_by_role(role) = entry;
        end
        
        function result = objects_for_role(obj, role)
            
            result = {};
            
            if ~isKey(obj.objects_by_role, role)
                return
            end
            
            result = obj.objects_by_role(role);
        end
    end
    
end
