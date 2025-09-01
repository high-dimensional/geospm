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

classdef TextDeclarator < hdng.diagrams.features.GeometryDeclarator
    %TextDeclarator Summary.  
    %   Detailed description 
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = TextDeclarator(varargin)
            obj@hdng.diagrams.features.GeometryDeclarator(varargin{:});

            if ~isfield(obj.values_by_identifier, 'text_x_is_increment')
                obj.values_by_identifier.text_x_is_increment = false;
            end

            if ~isfield(obj.values_by_identifier, 'text_y_is_increment')
                obj.values_by_identifier.text_y_is_increment = false;
            end
            
            if ~isfield(obj.values_by_identifier, 'text_x')
                obj.values_by_identifier.text_x = 0;
            end

            if ~isfield(obj.values_by_identifier, 'text_y')
                obj.values_by_identifier.text_y = 0;
            end
            
            if ~isfield(obj.values_by_identifier, 'text')
                obj.values_by_identifier.text = '';
            end
        end
    end

    methods (Access=protected)
    
        function result = create_feature(~, varargin)
            result = hdng.diagrams.features.Text(varargin{:});
        end

    end
end
