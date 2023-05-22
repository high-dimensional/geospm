% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2020,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef ValueModifier < handle
    
    %ValueDirective Encapsulates a value or a processing directive.
    %
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=public, SetAccess=public)
    end
    
    properties (GetAccess=public, SetAccess=private)
        handlers
    end
    
    methods
        
        function obj = ValueModifier()
            obj.handlers = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end

        function set_handler(obj, type_identifier, handler)
            obj.handlers(type_identifier) = handler;
        end
        
        function result = apply(obj, value)

            if ~isKey(obj.handlers, value.type_identifier)
                result = value;
                return;
            end

            handler = obj.handlers(value.type_identifier);
            result = handler(obj, value);
        end
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
end
