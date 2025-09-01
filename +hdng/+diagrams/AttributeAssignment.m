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

classdef AttributeAssignment < handle
    %AttributeAssignment Summary.  
    %   Detailed description 
    
    properties
        identifiers
        transform_list
    end
    
    properties (Dependent, Transient)
    end
    
    properties (Access=private)
    end
    
    methods
        
        function obj = AttributeAssignment(identifiers, transform_list)

            if ~exist('transform_list', 'var')
                transform_list = {};
            end
            
            obj.identifiers = identifiers;
            obj.transform_list = transform_list;
        end
        
        function perform(obj, scope, base, parent, siblings)
            
            result = obj.transform_scope(scope, base, parent, siblings);
            
            obj.assign_result(scope, result);
            
        end
    end
    
    methods (Access=protected)

        function assign_result(obj, scope, result)

            for index=1:numel(obj.identifiers)
                identifier = obj.identifiers{index};
                value = hdng.utilities.struct_get_value_at_path(result.attributes, identifier, []);
                scope.attributes.(identifier) = value;
            end
        
        end
        
        function scope = transform_scope(obj, scope, base, parent, siblings)

            if isempty(obj.transform_list)
                return
            end
            
            for index=1:numel(obj.transform_list)
                transform = obj.transform_list{index};
                scope = transform.compute(scope, base, parent, siblings);
            end
        end
        
    end
end
