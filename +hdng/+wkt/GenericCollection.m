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

classdef GenericCollection < hdng.wkt.WKTGeometryCollection
    %WKTGeometryCollection Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess=private, SetAccess=private)
        element_type_
        elements_
        N_points_
    end
    
    methods
        
        function obj = GenericCollection(elements, element_type)
            
            if ~exist('elements', 'var')
                elements = hdng.wkt.Primitive.empty;
            end
                
            if isa(elements, 'hdng.wkt.Primitive')
                if ~exist('element_type', 'var')
                    element_type = class(elements);
                end
                
                tmp = cell(numel(elements), 1);
                
                for i=1:numel(elements)
                    tmp{i} = elements(i);
                end
                
                elements = tmp;
            end
            
            
            if iscell(elements)
                
                if numel(elements) > 0
                    element_type = class(elements{1});
                end
                
                for i=2:numel(elements)
                    
                    tmp_element_type = class(elements{i});
                    
                    if ~strcmp(element_type, tmp_element_type)
                        element_type = '';
                        break;
                    end
                end
            else
                error('GenericCollection(): elements argument must be a cell array or an array derived from hdng.wkt.Primitive.');
            end
            
            obj = obj@hdng.wkt.WKTGeometryCollection();
            obj.element_type_ = element_type;
            obj.elements_ = elements;
            obj.N_points_ = [];
        end
        
        function result = nth_element(obj, index)
            
            if index > numel(obj.elements_) || index == 0
                error('nth_element(): index argument is out of bounds.');
            end
            
            result = obj.elements_{index};
        end
    end
    
    methods (Access = protected)
        
        function result = access_is_mixed(obj)
            result = numel(obj.element_type) == 0;
        end
        
        function result = access_element_type(obj)
            result = obj.element_type_;
        end
        
        function result = access_N_elements(obj)
            result = numel(obj.elements_);
        end
        
        function result = access_N_points(obj)
            
            if isempty(obj.N_points_)
                obj.N_points_ = 0;
                
                for i=1:obj.N_elements
                    element = obj.nth_element(i);
                    obj.N_points_ = obj.N_points_ + element.N_points;
                end
            end
            
            result = obj.N_points_;
        end
    end
    
end
