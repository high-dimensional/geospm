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

classdef SwitchDeclarator < hdng.diagrams.features.GeometryDeclarator
    %SwitchDeclarator Summary.  
    %   Detailed description 
    
    properties
        n_choices
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = SwitchDeclarator(varargin)
            obj@hdng.diagrams.features.GeometryDeclarator(varargin{:});

            %options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(obj.values_by_identifier, 'choice')
                obj.values_by_identifier.choice = 'choice';
            end

            obj.n_choices = numel(obj.children);
        end
    end

    methods (Access=protected)
        
        function result = create_feature(~, varargin)
            result = hdng.diagrams.features.Switch(varargin{:});
        end

    end
end
