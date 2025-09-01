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

classdef ShapeDeclarator < hdng.diagrams.features.GeometryDeclarator
    %ShapeDeclarator Summary.  
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = ShapeDeclarator(varargin)
            obj@hdng.diagrams.features.GeometryDeclarator(varargin{:});

            if ~isfield(obj.values_by_identifier, 'shape')
                obj.values_by_identifier.shape = 'box';
            end

            names = obj.value_names_for_shape(obj.values_by_identifier.shape);

            for index=1:numel(names)
                name = names{index};

                if ~isfield(obj.values_by_identifier, name)
                    obj.values_by_identifier.(name) = 0;
                end
            end
        end
        
        function result = value_names_for_shape(~, shape)
            switch shape
                case 'box'
                    result = {'x1', 'x2', 'y1', 'y2'};
                case 'circle'
                    result = {'cx', 'cy', 'r'};
                case 'ellipse'
                    result = {'cx', 'cy', 'rx', 'ry'};
                otherwise
                    result = {};
            end
        end
    end

    methods (Access=protected)
        
        function result = create_feature(~, varargin)
            result = hdng.diagrams.features.Shape(varargin{:});
        end

    end
end
