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

classdef CustomDeclarator < hdng.diagrams.features.GeometryDeclarator
    %CustomDeclarator Summary.  
    %   Detailed description 
    
    properties
        delegate
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = CustomDeclarator(varargin)
            obj = obj@hdng.diagrams.features.GeometryDeclarator(varargin{:});
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});

            if ~isfield(options, 'delegate')
                options.delegate = [];
            end

            if ~isfield(obj.values_by_identifier, 'cx')
                obj.values_by_identifier.cx = 0;
            end

            if ~isfield(obj.values_by_identifier, 'cy')
                obj.values_by_identifier.cy = 0;
            end

            obj.delegate = options.delegate;
        end
    end

    methods (Access=protected)
    
        function result = create_feature(~, varargin)
            result = hdng.diagrams.features.Custom(varargin{:});
        end

    end
end
