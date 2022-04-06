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

classdef Document < hdng.documents.Node
    
    %Document [Description]
    %
    
    properties
    end
    
    properties (Dependent, Transient)
        nodes
        pages
    end
    
    properties (GetAccess=private, SetAccess=private)
        nodes_
        pages_
    end
    
    methods
        
        function obj = Document()
            
            super_options = struct();
            super_options.render_type = 'document';
            
            arguments = hdng.utilities.struct_to_name_value_sequence(super_options);
            
            obj = obj@hdng.documents.Node(arguments{:});
            
            obj.nodes_ = {};
            obj.pages_ = {};
        end
        
        function result = get.nodes(obj)
            result = obj.nodes_;
        end
        
        function result = get.pages(obj)
            result = obj.pages_;
        end
        
        function add_page(obj, page)
            obj.pages_ = [obj.pages_; {page}];
        end
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
