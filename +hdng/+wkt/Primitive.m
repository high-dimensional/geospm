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

classdef Primitive < hdng.wkt.WKTGeometryCollection
    %Primitive Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Transient, Dependent)
    end
    
    methods
        
        function obj = Primitive()
            obj = obj@hdng.wkt.WKTGeometryCollection();
        end
        
        function result = nth_element(obj, index)
            if index ~= 1
                error('nth_element(): index argument is out of bounds.');
            end
            
            result = obj;
        end
        
        function handle_with(obj, handler)
            m = obj.select_handler_method(handler);
            m(obj);
        end
    end
    
    methods (Static)
        
        function result = select_handler_method(handler) %#ok<STOUT,INUSD>
            error('select_handler_method() must be implemented by a subclass.');
        end
        
    end
    
    methods (Access = protected)
        
        function result = access_is_mixed(~)
            result = false;
        end
        
        function result = access_element_type(obj)
            result = class(obj);
        end
        
        function result = access_N_elements(~)
            result = 1;
        end
        
        function result = access_N_points(~) %#ok<STOUT>
            error('access_N_points() must be implemented by a subclass.');
        end
        
    end
    
end
