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

classdef ExternalImage < hdng.documents.nodes.Image
    
    %ExternalImage [Description]
    %
    
    properties
    end
    
    properties (Dependent, Transient)
        url
    end
    
    properties (GetAccess=private, SetAccess=private)
        url_
    end
    
    methods
        
        function result = get.url(obj)
            result = obj.url_;
        end
        
        function obj = ExternalImage(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'url')
                options.url = '';
            end
            
            if ~ischar(options.url)
                error('hdng.documents.nodes.ExternalImage(): Expected char value for ''url'' argument.');
            end
            
            super_options = options;
            super_options = rmfield(super_options, 'url');
            arguments = hdng.utilities.struct_to_name_value_sequence(super_options);
            
            obj = obj@hdng.documents.nodes.Image(arguments{:});
            
            obj.url_ = options.url;
        end
        
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
