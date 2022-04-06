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

classdef Text < hdng.documents.Node
    
    %Text [Description]
    %
    
    properties
        content
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = Text(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'content')
                options.content = '';
            end
            
            if ~ischar(options.content)
                error('hdng.documents.nodes.Text(): Expected char value for ''content'' argument.');
            end
            
            if ~isfield(options, 'render_type')
                options.render_type = 'text';
            end
            
            super_options = options;
            arguments = hdng.utilities.struct_to_name_value_sequence(super_options);
            
            obj = obj@hdng.documents.Node(arguments{:});
            
            obj.content = options.content;
        end
        
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
