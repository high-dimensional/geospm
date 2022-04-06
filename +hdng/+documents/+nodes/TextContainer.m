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

classdef TextContainer < hdng.documents.Container
    
    %TextContainer [Description]
    %
    
    properties
    end
    
    properties (Dependent, Transient)
        text
    end
    
    properties (GetAccess=private, SetAccess=private)
        text_link_
    end
    
    methods
        
        function result = get.text(obj)
            result = obj.text_link_.node;
        end
        
        function set.text(obj, node)
            obj.text_link_.node = node;
        end
        
        function obj = TextContainer(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'render_type')
                options.render_type = 'text_container';
            end
            
            super_options = options;
            arguments = hdng.utilities.struct_to_name_value_sequence(super_options);
            
            obj = obj@hdng.documents.Container(arguments{:});
            
            obj.text_link_ = hdng.documents.Link();
        end
        
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
