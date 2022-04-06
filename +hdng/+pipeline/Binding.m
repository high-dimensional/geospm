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

classdef Binding < handle
    
    properties (GetAccess=public, SetAccess=immutable)
        identifier
        is_optional
    end
    
    properties (GetAccess=public, SetAccess=protected)
        variable_name
        default_value
    end
    
    methods
        
        function obj = Binding(identifier, is_optional)
            
            if ~isvarname(identifier)
                error(['hdng.pipeline.Binding() ''' identifier ''' is not a valid MATLAB identifier.']);
            end
            
            obj.identifier = identifier;
            obj.is_optional = is_optional;
            obj.variable_name = identifier;
            obj.default_value = [];
        end
        
        function set_variable_name(obj, value)
            obj.variable_name = value;
        end
        
        function set_default_value(obj, value)
            obj.default_value = value;
        end
    end
    
end
