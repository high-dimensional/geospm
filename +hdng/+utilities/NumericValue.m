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

classdef NumericValue < handle
    %NumericValue Summary goes here.
    %
    
    properties (GetAccess = public, SetAccess = private)
        content
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess = private, SetAccess = private)
    end
    
    methods
        
        function obj = NumericValue(value)
            
            obj.content = value;
        end
        
        function result = pre_increment(obj, value)
            
            if ~exist('value', 'var')
                value = 1;
            end
            
            result = obj.content;
            obj.content = obj.content + value;
        end
        
        function result = post_increment(obj, value)
            
            if ~exist('value', 'var')
                value = 1;
            end
            
            obj.content = obj.content + value;
            result = obj.content;
        end
    end
    
    methods (Static)
    end
    
    methods (Access = protected)
        
    end
    
end
