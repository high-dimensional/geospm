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

classdef RecordAttribute < handle
    %RecordAttribute 
    %   .
    
    properties
        description
        attachments
    end
    
    properties (Dependent, Transient)
        identifier
        is_persistent
    end
    
    properties (GetAccess=private, SetAccess=private)
        identifier_
        is_persistent_
    end
    
    methods
        
        function obj = RecordAttribute(identifier, is_persistent)
            obj.identifier_ = identifier;
            obj.is_persistent_ = is_persistent;
            obj.description = '';
            obj.attachments = struct();
        end
        
        function result = get.identifier(obj)
            result = obj.identifier_;
        end
        
        function result = get.is_persistent(obj)
            result = obj.is_persistent_;
        end
        
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
