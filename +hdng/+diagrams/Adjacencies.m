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

classdef Adjacencies < handle
    %Adjacencies Summary.
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Adjacencies()
        end
        
        function result = inward(obj, node, base) %#ok<INUSD>
            result = {};
        end

        function result = outward(obj, node, base) %#ok<INUSD>
            result = {};
        end
        
        function result = inward_indices(obj, node_number, base) %#ok<INUSD>
            result = {};
        end

        function result = outward_indices(obj, node_number, base) %#ok<INUSD>
            result = {};
        end

        function define(obj, from, to, base)
        end

    end
end
