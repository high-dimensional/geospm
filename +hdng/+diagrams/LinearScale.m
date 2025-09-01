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

classdef LinearScale < hdng.diagrams.Scale
    %LinearScale Summary.
    %   Detailed description
    
    properties 
        calibrated_domain
    end
    
    properties (Dependent, Transient)
        defined_domain
        defined_range
        
        domain

        scale_coefficient
    end

    properties (Access=private)
        domain_
        range_
    end
    
    methods
       
        function result = get.defined_domain(obj)
            result = obj.domain_;
        end
        
        function set.defined_domain(obj, value)
            obj.domain_ = value;
        end
        
        function result = get.defined_range(obj)
            result = obj.range_;
        end
        
        function set.defined_range(obj, value)
            obj.range_ = value;
        end
        
        function result = get.scale_coefficient(obj)
            result = (obj.range_(2) - obj.range_(1)) / (obj.domain(2) - obj.domain(1));
        end

        function result = get.domain(obj)

            result = obj.defined_domain;

            if ~isempty(obj.calibrated_domain)
                result = obj.calibrated_domain;
            end
        end

        function obj = LinearScale(varargin)
            obj = obj@hdng.diagrams.Scale(varargin{:});

            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'domain')
                options.domain = [-100, 100];
            end

            if ~isfield(options, 'range')
                options.range = [-100, 100];
            end

            obj.defined_domain = options.domain;
            obj.calibrated_domain = [];
            obj.defined_range = options.range;
        end

        function calibrate(obj, values)
            values = cell2mat(values);
            domain_min = min(values);
            domain_max = max(values);
            limit = max([abs(domain_min), abs(domain_max)]) * 1.1;
            obj.calibrated_domain = [-limit, limit];
        end
        
        function [result, indices, clipped] = apply(obj, values)
            
            values = cell2mat(values);
            selector = values >= obj.domain(1) & values <= obj.domain(2);

            result = num2cell((values(selector) - obj.domain(1)) * obj.scale_coefficient + obj.defined_range(1));
            indices = find(selector);
            clipped = find(~selector);
        end
    end

    methods (Access=protected)
        

    end
end
