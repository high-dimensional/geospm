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

classdef ValueLoader < handle
    
    %ValueLoader Base class for loading value types.
    %
    
    properties
    end
    
    properties (Dependent, Transient)
        supported_types
    end
    
    properties (GetAccess=public, SetAccess=public)
    end
    
    properties (GetAccess=public, SetAccess=private)
    end
    
    methods
        
        function obj = ValueLoader()
        end
        
        function result = get.supported_types(obj)
            result = obj.access_supported_types();
        end
        
        function [content, serialised_value] = from_serialised_value_and_type(obj, serialised_value, type_identifier) %#ok<STOUT,INUSD>
            error('ValueLoader.from_serialised_value_and_type() must be implemented by a subclass.');
        end
        
        function varargout = subsref(obj,s)
            
           switch s(1).type
               
              case '()'
                  [varargout{1:nargout}] = obj.from_serialised_value_and_type(s(1).subs{:});
                  
              otherwise
              	 [varargout{1:nargout}] = builtin('subsref',obj,s);
           end
        end
        
    end
    
    methods (Access=protected)
        
        function result = access_supported_types(obj) %#ok<STOUT,MANU>
            error('ValueLoader.access_supported_types() must be implemented by a subclass.');
        end
        
    end
    
    methods (Static, Access=public)
    end
    
end
