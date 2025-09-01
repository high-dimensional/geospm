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

classdef Definition < handle
    %Definition Summary.
    %   Detailed description 
    
    properties (GetAccess=public, SetAccess=private)
        category
        uuid
    end

    properties
    end

    properties (Dependent, Transient)
        uuid_as_identifier
        nested_definitions
    end
    
    methods
        
        
        function result = get.uuid_as_identifier(obj)
            result = replace(obj.uuid, '-', '');
        end
        function result = get.nested_definitions(obj)
            result = obj.access_nested_definitions();
        end

        function obj = Definition(category)
            
            obj.category = category;
            obj.uuid = char(java.util.UUID.randomUUID);
        end

    end

    methods (Access=protected)
    
        function result = access_nested_definitions(obj)
            result = {};
        end
    end
end
