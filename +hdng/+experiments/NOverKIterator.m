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

classdef NOverKIterator < hdng.experiments.ValueIterator
    
    %NOverKIterator Iterates over all combinations N over K.
    %
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=public, SetAccess=private)
        N
        K
        indices
        has_next
    end
    
    methods
        
        function obj = NOverKIterator(N, K)
            obj = obj@hdng.experiments.ValueIterator();
            obj.N = N;
            obj.K = K;
            obj.indices = [1:obj.K obj.N];
            obj.has_next = true;
        end
        
        
        function [is_valid, value] = next(obj)
            
            is_valid = obj.has_next;
            value = hdng.experiments.Value.empty;
            
            if ~is_valid
                return
            end
            
            index = obj.K;
            
            value = hdng.experiments.Value.from(obj.indices(1:end - 1));

            while index >= 1

                if obj.indices(index) + 1 > obj.indices(index + 1)
                    index = index - 1;
                    continue
                end

                obj.indices(index) = obj.indices(index) + 1;
                index = index + 1;
                break
            end
            
            if index < 1
                obj.has_next = false;
                return
            end
            
            while index <= obj.K
                obj.indices(index) = obj.indices(index - 1) + 1;
                index = index + 1;
            end
        end
    end
end
