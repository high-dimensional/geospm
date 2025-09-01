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

classdef Order < hdng.diagrams.Definition
    %Order Summary.
    %   Detailed description 
    
    properties
        identifier
        reverse
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Order(varargin)
            obj = obj@hdng.diagrams.Definition('order');

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'reverse')
                options.reverse = false;
            end

            obj.identifier = '';
            obj.reverse = false;
        end
        
        function [sorted_indices, missing_indices] = apply(obj, values) %#ok<INUSD>
            sorted_indices = 1:numel(values);
            missing_indices = [];
        end

    end
end
