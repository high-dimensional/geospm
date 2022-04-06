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

classdef TableView < hdng.documents.Container
    
    %TableView [Description]
    %
    
    properties
    end
    
    properties (Dependent, Transient)
        layout_size
        window
        cell_containers
        table
    end
    
    properties (GetAccess=private, SetAccess=private)
        layout_size_
        window_
        cell_containers_
        table_link_
    end
    
    methods
        
        function result = size(obj)
            result = size(obj.cell_containers);
        end
        
        function result = get.layout_size(obj)
            
            if ~isempty(obj.layout_size_)
                result = obj.layout_size_;
            else
                result = size(obj);
            end
        end
        
        function set.layout_size(obj, value)
            obj.layout_size_ = value;
        end
        
        function result = get.window(obj)
            result = obj.window_;
        end
        
        function set.window(obj, value)
            obj.window_ = value;
            obj.did_change();
        end
        
        function result = get.cell_containers(obj)
            result = obj.cell_containers_;
        end
        
        function result = get.table(obj)
            result = obj.table_link_.node;
        end
        
        function set.table(obj, node)
            obj.table_link_.node = node;
            obj.did_change();
        end
        
        function obj = TableView(varargin)
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'window')
                options.window = [1, 1, 0, 0];
            end
            
            if ~isnumeric(options.window)
                error('hdng.documents.nodes.TableView(): Expected numeric value for ''window'' argument.');
            end
            
            if ~isfield(options, 'layout_size')
                options.layout_size = [];
            end
            
            if ~isnumeric(options.layout_size)
                error('hdng.documents.nodes.TableView(): Expected numeric value for ''layout_size'' argument.');
            end
            
            
            if ~isfield(options, 'render_type')
                options.render_type = 'table_view';
            end
            
            super_options = options;
            super_options = rmfield(super_options, 'window');
            arguments = hdng.utilities.struct_to_name_value_sequence(super_options);
            
            obj = obj@hdng.documents.Container(arguments{:});
            
            obj.layout_size_ = options.layout_size;
            obj.window_ = options.window;
            
            obj.cell_containers_ = {};
            
            obj.table_link_ = hdng.documents.Link();
            
            obj.did_change();
        end
        
        function result = cell_attachments(obj, attachment)
            
            result = {};
            current_table = obj.table;
            current_window = obj.window;
            
            if isempty(current_table)
                return
            end
            
            row_range = current_window(1):current_window(3);
            col_range = current_window(2):current_window(4);
            
            result = current_table(row_range, col_range, attachment);
        end
    end
    
    methods (Access=protected)
        
        function did_change(obj)
            
            current_table = obj.table;
            current_window = obj.window;
            
            if isempty(current_table)
                obj.cell_containers_ = {};
                return
            end
            
            row_range = current_window(1):current_window(3);
            col_range = current_window(2):current_window(4);
            
            obj.cell_containers_ = current_table(row_range, col_range);
                            
        end
    end
    
    methods (Static, Access=public)
    end
    
end
