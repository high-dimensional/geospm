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

classdef Node < handle
    
    %Node [Description]
    %
    
    properties
        description
        attachments
    end
    
    properties (Dependent, Transient)
        links
        render_type
    end
    
    properties (GetAccess=private, SetAccess=private)
        links_
        link_number_
        
        render_type_
    end
    
    methods
        
        function result = get.links(obj)
            result = obj.links_.values();
        end
        
        function result = get.render_type(obj)
            result = obj.render_type_;
        end
        
        function obj = Node(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'render_type')
                options.render_type = 'node';
            end
            
            if ~ischar(options.render_type)
                error('hdng.documents.Node(): Expected char value for ''render_type'' argument.');
            end
            
            obj.description = '';
            obj.attachments = struct();
            
            obj.links_ = containers.Map('KeyType', 'int64', 'ValueType', 'any');
            obj.link_number_ = 0;
            
            obj.render_type_ = options.render_type;
        end
        
        function result = link(obj)
            result = hdng.documents.Link();
            result.node = obj;
            
            link_number = obj.link_number_ + 1;
            obj.link_number_ = link_number;
            
            obj.links_(link_number) = result;
        end
        
        function unlink(obj, link)
            
            numbers = obj.links_.keys();
            all_links = obj.links_.values();
            
            for i=1:numel(all_links)
                
                if all_links{i} == link
                    remove(obj.links_, numbers{i});
                    break;
                end
            end
        end
        
        function substitute_for(obj, node)
            
            node_links = node.links;
            
            for i=1:numel(node_links)
                link = node_links{i};
                link.node = obj;
            end
        end
    end
    
    methods (Access=protected)
    end
    
    methods (Static, Access=public)
    end
    
end
