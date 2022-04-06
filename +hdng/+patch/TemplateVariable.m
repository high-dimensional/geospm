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

classdef TemplateVariable < hdng.patch.Fragment
    %TemplateVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess=public, SetAccess=private)
        name
    end
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = TemplateVariable(range_in_file, name)
            
            obj = obj@hdng.patch.Fragment(range_in_file);
            
            obj.name = name;
        end
    end
    
    methods (Access=protected)
        
        function result = access_type(~)
            result = 'template-variable';
        end
        
    end
end
