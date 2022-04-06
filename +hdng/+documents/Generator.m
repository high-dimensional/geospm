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

classdef Generator < handle
    
    %Generator [Description]
    %
    
    properties
        canonical_base_path
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = Generator(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'canonical_base_path')
                options.canonical_base_path = '';
            end
            
            if ~ischar(options.canonical_base_path)
                error('hdng.documents.Node(): Expected char value for ''canonical_base_path'' argument.');
            end
            
            obj.canonical_base_path = options.canonical_base_path;
        end
        
        
        function gather(obj, object, varargin) %#ok<INUSD>
        end
        
        function document = layout(obj) %#ok<STOUT,MANU>
            error('Generator.layout() must be implemented by subclasses.');
        end
        
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
