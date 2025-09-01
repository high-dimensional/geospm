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

classdef GeometryDeclarator < hdng.diagrams.FeatureDeclarator
    %GeometryDeclarator Summary.  
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = GeometryDeclarator(varargin)
             obj@hdng.diagrams.FeatureDeclarator(varargin{:});
        end
    end

    methods (Access=protected)
    
        function result = create_feature(~, varargin)
            result = hdng.diagrams.features.Geometry(varargin{:});
        end

    end
end
