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

classdef ValueContent < handle
    
    %ValueContent Base class for complex value types.
    %
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=public, SetAccess=public)
    end
    
    properties (GetAccess=public, SetAccess=private)
    end
    
    methods
        
        function obj = ValueContent()
        end
        
        function [serialised_value, type_identifier] = as_serialised_value_and_type(obj) %#ok<MANU>
            serialised_value = experiments.Dictionary();
            type_identifier = 'builtin.undefined';
        end

        function result = label_for_content(obj) %#ok<MANU>
        	result = 'label';
        end
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
