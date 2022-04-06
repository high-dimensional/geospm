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

classdef Grid < handle
    
    %Grid [Description]
    %
    
    properties
        page_size
        page_margin
        cell_margin
        
        columns_per_page
        rows_per_page
    end
    
    properties (Dependent, Transient)
        cell_coords
        
        cells_per_page
        cell_size
    end
    
    properties (GetAccess=private, SetAccess=private)
        page
        cell_index
    end
    
    methods
        
        function result = get.cell_coords(obj)
            result = obj.coordinates_from_cell_index(obj.cell_index);
        end
        
        function result = get.cells_per_page(obj)
            result = obj.columns_per_page + obj.rows_per_page;
        end
        
        function result = get.cell_size(obj)
            available_size = obj.page_size - obj.page_margin;
            result = available_size ./ [obj.columns_per_page, obj.rows_per_page];
            result = result - obj.cell_margin;
        end
        
        function obj = Grid()
            
            obj.page_size = [sqrt(2), 1];
            obj.page_margin = [0, 0];
            obj.cell_margin = [0, 0];
            
            obj.columns_per_page = 6;
            obj.rows_per_page = 4;
            
            obj.page = [];
            obj.cell_index = 0;
        end
        
        
    end
    
    methods (Access=protected)
        
        function coords = coordinates_from_cell_index(obj, cell_index)
            
            y = idivide(cell_index, obj.rows_per_page) + 1;
            x = mod(cell_index, obj.rows_per_page) + 1;
            
            coords = [x, y];
        end
        
        function cell_index = cell_index_from_coordinates(obj, coords)
            cell_index = (coords(1) - 1) * obj.rows_per_page + coords(2);
        end
        
        function bounds = compute_bounds(obj, cell_index)
            
            coords = obj.coordinates_from_cell_index(cell_index);
            location = (coords - 1) .* (obj.cell_size + obj.cell_margin);
            bounds = [location, location + obj.cell_size];
        end
        
    end
    
    methods (Static, Access=public)
    end
    
end
