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

classdef Control < geospm.models.Parameter
    %Control A control provides a value in a specified range.
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        lower_bound
        upper_bound
        value
        nth_control
    end
    
    methods
        
        function obj = Control(generator, name, lower_bound, upper_bound, value, varargin)
            obj = obj@geospm.models.Parameter(generator, name, 'control', varargin{:});
            
            obj.lower_bound = lower_bound;
            obj.upper_bound = upper_bound;
            obj.value = value;
            
            obj.nth_control = obj.generator.add_control(obj);
        end
        
        function set(obj, value)
            %error('Control.set() must be implemented by a subclass.');
            obj.value = value;
        end
        
        function compute(obj, model, metadata) %#ok<INUSD>
        end
    end
    
    methods (Static, Access=private)
    end
    
end
