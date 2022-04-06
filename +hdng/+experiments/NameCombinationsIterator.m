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

classdef NameCombinationsIterator < hdng.experiments.NOverKIterator
    
    %NameCombinationsIterator Iterates over all combinations N over K.
    %
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
        names
    end
    
    methods
        
        function obj = NameCombinationsIterator(names, K)
            obj = obj@hdng.experiments.NOverKIterator(numel(names), K);
            obj.names = names;
        end
        
        function [is_valid, value] = next(obj)
            
            [is_valid, value] = obj.next@hdng.experiments.NOverKIterator();
            
            if ~is_valid
                return
            end
            
            combination = cell(numel(value.content), 1);
            
            for index=1:numel(value.content)
                combination{index} = obj.names{value.content(index)};
            end
            
            value = hdng.experiments.Value.from(combination);
        end
    end
end
