% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2020,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef Style < handle
    
    %Style 
    %
    
    properties (GetAccess=public, SetAccess=private)
    end
    
    properties (GetAccess=public, SetAccess=public)
    end
    
    properties (Dependent, Transient)
        font_family
        font_weight
        font_style
        font_size
    end
    
    properties (GetAccess=private, SetAccess=private)
        font_family_
        font_weight_
        font_style_
        font_size_
    end
    
    methods
        
        function obj = Style()
            
            obj.font_family_ = 'Helvetica';
            obj.font_weight_ = 'normal';
            obj.font_style_ = 'normal';
            obj.font_size_  = 16;
        end

        function result = get.font_family(obj)
            result = obj.font_family_;
        end
        
        function set.font_family(obj, value)
            obj.font_family_ = value;
        end

        function result = get.font_weight(obj)
            result = obj.font_weight_;
        end

        function set.font_weight(obj, value)
            obj.font_weight_ = value;
        end

        function result = get.font_style(obj)
            result = obj.font_style_;
        end
        
        function set.font_style(obj, value)
            obj.font_style_ = value;
        end

        function result = get.font_size(obj)
            result = obj.font_size_;
        end
        
        function set.font_size(obj, value)
            obj.font_size_ = value;
        end
    end

    methods (Access=protected)
    end
    
    methods (Access=public, Static)
    end
end
