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

classdef ValueListIterator < hdng.experiments.ValueIterator
    
    %ValueListIterator Iterates over a list of values.
    %
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
        values
        index
    end
    
    methods
        
        function obj = ValueListIterator(values)
            obj = obj@hdng.experiments.ValueIterator();
            obj.values = values;
            obj.index = 1;
        end
        
        
        function [is_valid, value] = next(obj)
            
            is_valid = obj.index <= numel(obj.values);
            value = hdng.experiments.Value.empty;
            
            if ~is_valid
                return
            end
            
            value = obj.values{obj.index};
            obj.index = obj.index + 1;
        end
    end
end
