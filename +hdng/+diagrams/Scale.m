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
        defined_domain
        calibrated_domain
        domain
    end
    
    methods

        function result = get.defined_domain(obj)
            result = obj.access_defined_domain();
        end

        function set.defined_domain(obj, value)
            obj.update_defined_domain(value);
        end

        function result = get.calibrated_domain(obj)
            result = obj.access_calibrated_domain();
        end

        function result = get.domain(obj)
            result = obj.access_domain();
        end

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

    methods (Access=protected)
    
        function result = access_defined_domain(~)
            result = [];
        end

        function result = access_calibrated_domain(~)
            result = [];
        end
    
        function update_defined_domain(~, ~)
            error('update_defined_domain() must be implemented by a subclass.');
        end

        function result = access_domain(obj)
            result = obj.calibrated_domain;

            if isempty(result)
                result = obj.defined_domain;
            end
        end

    end
end
