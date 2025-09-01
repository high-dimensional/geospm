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

classdef LineDeclarator < hdng.diagrams.features.GeometryDeclarator
    %LineDeclarator Summary.  
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = LineDeclarator(varargin)
             obj@hdng.diagrams.features.GeometryDeclarator(varargin{:});

            if ~isfield(obj.values_by_identifier, 'x1')
                obj.values_by_identifier.x1 = 0;
            end

            if ~isfield(obj.values_by_identifier, 'x2')
                obj.values_by_identifier.x2 = 0;
            end

            if ~isfield(obj.values_by_identifier, 'y1')
                obj.values_by_identifier.y1 = 0;
            end

            if ~isfield(obj.values_by_identifier, 'y2')
                obj.values_by_identifier.y2 = 0;
            end
        end
    end

    methods (Access=protected)
    
        function result = create_feature(~, varargin)
            result = hdng.diagrams.features.Line(varargin{:});
        end

    end
end
