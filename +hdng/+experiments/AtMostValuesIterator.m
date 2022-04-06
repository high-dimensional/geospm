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

classdef AtMostValuesIterator < hdng.experiments.ValueIterator
    
    %ValueListIterator Iterates over a list of values.
    %
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
        N
        index
        iterator
    end
    
    methods
        
        function obj = AtMostValuesIterator(N, iterator)
            obj = obj@hdng.experiments.ValueIterator();
            obj.N = N;
            obj.index = 1;
            obj.iterator = iterator;
        end
        
        
        function [is_valid, value] = next(obj)
            
            if obj.index > obj.N
                is_valid = false;
                value = hdng.experiments.Value.empty;
                return
            end
            
            [is_valid, value] = obj.iterator.next();
            
            if ~is_valid
                return
            end
            
            obj.index = obj.index + 1;
        end
    end
end
