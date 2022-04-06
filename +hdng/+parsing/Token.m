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

classdef Token < handle
    %Token Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        string
        value
        type_number
        line_number
        line_offset
        extent
    end
    
    methods
        
        function obj = Token()

            obj.string='';
            obj.value='';
            obj.type_number=cast(0, 'int64');
            obj.line_number=cast(0, 'int64');
            obj.line_offset=cast(0, 'int64');
            obj.extent=zeros(1,2,'int64');
        end
        
        function set.string(obj, value)
            
            if ~ischar(value)
                error('Expected char array value for ''string'' attribute.');
            end
            
            obj.string = value;
        end
        
        function set.value(obj, value)
            obj.value = value;
        end
        
        function set.type_number(obj, value)
            
            if ~isinteger(value)
                error('Expected integer value for ''type_number'' attribute.');
            end
            
            obj.type_number = value;
        end
        
        function set.line_number(obj, value)
            
            if ~isinteger(value)
                error('Expected integer value for ''line_number'' attribute.');
            end
            
            obj.line_number = value;
        end
        
        function set.line_offset(obj, value)
            
            if ~isinteger(value)
                error('Expected integer value for ''line_offset'' attribute.');
            end
            
            obj.line_offset = value;
        end
        
        function set.extent(obj, value)
            
            if ~isinteger(value) || size(value, 1) ~= 1 || size(value, 2) ~= 2
                error('Expected 1 x 2 integer value for ''extent'' attribute.');
            end
            
            obj.extent = value;
        end
    end
    
end
