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

classdef Scale < hdng.diagrams.Definition
    %Scale Summary.
    %   Detailed description 
    
    properties
        identifier
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = Scale(varargin)
            obj = obj@hdng.diagrams.Definition('scale');

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'identifier')
                options.identifier = '';
            end

            obj.identifier = options.identifier;
        end

        function calibrate(obj, values) %#ok<INUSD>
        end

        function [result, indices, clipped] = apply(obj, values) %#ok<INUSD>
            result = values;
            indices = 1:numel(values);
            clipped = [];
        end
    end
end
