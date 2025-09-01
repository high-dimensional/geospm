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

classdef AxisDeclarator < hdng.diagrams.features.GeometryDeclarator
    %AxisDeclarator Summary.  
    %   Detailed description 
    
    properties
        scale_identifier
        configuration
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = AxisDeclarator(varargin)
             obj@hdng.diagrams.features.GeometryDeclarator(varargin{:});

             options = hdng.utilities.parse_struct_from_varargin(varargin{:});

             if ~isfield(options, 'scale_identifier')
                 options.scale_identifier = '';
             end

             if ~isfield(options, 'configuration')
                 options.configuration = hdng.diagrams.configurations.AxisConfiguration();
             end

            obj.scale_identifier = options.scale_identifier;
            obj.configuration = options.configuration;
        end
    end
    
    methods (Access=protected)
    
        function result = create_feature(~, varargin)
            result = hdng.diagrams.features.Axis(varargin{:});
        end

    end
end
