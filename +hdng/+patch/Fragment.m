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

classdef Fragment < handle
    %Fragment Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess=public, SetAccess=protected)
        range_in_file
    end
    
    properties
        text
    end
    
    properties (Dependent, Transient)
        type
    end
        
    
    
    methods
        
        function obj = Fragment(range_in_file)
            
            obj.range_in_file = range_in_file;
            obj.text = '';
        end
        
        function result = get.type(obj)
            result = obj.access_type();
        end
        
    end
    
    methods (Access=protected)
        
        function result = access_type(~)
            result = 'fragment';
        end
        
    end
    
end
