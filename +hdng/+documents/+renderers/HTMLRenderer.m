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

classdef HTMLRenderer < hdng.documents.Renderer
    
    %HTMLRenderer [Description]
    %
    
    properties
    end
    
    properties (Dependent, Transient)
    end
    
    properties (GetAccess=private, SetAccess=private)
    end
    
    methods
        
        function obj = HTMLRenderer()
            obj = obj@hdng.documents.Renderer();
        end
    
        function render_unknown(obj, node, context) %#ok<INUSD>
        end
        
        function render_document(obj, node, context)
            
            pages = node.pages;
            
            for i=1:numel(pages)
                page = pages{i};
                obj.render(page, context);
            end
        end
        
        function render_page(obj, node, context)
            
            attributes = struct();
            attributes.class = 'page';
            
            context.open_tag('div', attributes);
            
            children = node.children;
            
            for i=1:numel(children)
                child = children{i};
                obj.render(child, context);
            end
            
            context.close_tag('div');
        end
        
        function render_image(~, node, context)
            
            attributes = struct();
            
            if isa(node, 'hdng.documents.nodes.ExternalImage')
                attributes.src = node.url;
                context.simple_tag('img', attributes);
            end
            
        end
        
        function render_text_container(~, node, context)
            
            text = node.text;
            
            attributes = struct();
            attributes.class = 'text-container';
            
            context.open_tag('p', attributes);
            context.text_fragment(text.content);
            context.close_tag('p');
        end
        
        function render_table_view(obj, node, context)
            
            table = node.table;
            
            if isempty(table)
                return;
            end
            
            cell_containers = node.cell_containers;
            cell_attachments = node.cell_attachments('html');
            view_size = size(node);
            layout_size = node.layout_size;
            
            window = node.window;
            row_range = window(1):window(3);
            col_range = window(2):window(4);
            
            context.open_tag('table');
            
            
            context.open_tag('tr');
            
            attributes = struct();
            attributes.class = 'column-header row-header';

            context.open_tag('th', attributes);
            context.close_tag('th');
            
            labels = table.column_header_labels(col_range);
            
            for i=1:numel(labels)
                label = labels{i};
                
                attributes = struct();
                attributes.class = 'column-header';
                
                context.open_tag('th', attributes);
                context.text_fragment(label);
                context.close_tag('th');
            end
            
            context.close_tag('tr');
            
            labels = table.row_header_labels(row_range);
            
            for i=1:layout_size(1)
                
                context.open_tag('tr');
                
                label = labels{i};
                
                attributes = struct();
                attributes.class = 'row-header';
                
                context.open_tag('th', attributes);
                context.text_fragment(label);
                context.close_tag('th');
                
                for j=1:layout_size(2)
                    
                    attributes = struct();
                    
                    if all([i, j] <= view_size)
                        cell_node = cell_containers{i, j};
                        cell_attributes = cell_attachments{i, j};
                        
                        if ~isempty(cell_attributes)
                            if isfield(cell_attributes, 'class')
                                attributes.class = obj.cell2char(cell_attributes.class);
                            end
                        end
                    else
                        cell_node = [];
                    end
                    
                    context.open_tag('td', attributes);
                    
                    if ~isempty(cell_node)
                        obj.render(cell_node, context);
                    end
                    
                    context.close_tag('td');
                end
                
                context.close_tag('tr');
            end
            
            context.close_tag('table');
        end
    end
    
    methods (Access=protected)
        
        function result = cell2char(~, array, sep)
            if ~exist('sep', 'var')
                sep = '';
            end
            
            result = '';
            
            for i=1:numel(array)
                result = [result sep array{i}]; %#ok<AGROW>
            end
            
            if ~isempty(result)
                result = result(numel(sep) + 1:end);
            end
        end
        
    end
    
    methods (Static, Access=public)
    end
    
end
