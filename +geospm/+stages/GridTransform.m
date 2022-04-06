% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2019,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

classdef GridTransform < geospm.SpatialAnalysisStage
    
    properties
        data_requirement
        data_product
        data_selection
        
        assigned_grid
    end
    
    properties (SetAccess=private)
        mode
        grid
    end
    
    methods
        
        function obj = GridTransform(analysis, varargin)
            obj = obj@geospm.SpatialAnalysisStage(analysis);
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'data_requirement')
                options.data_requirement = 'spatial_data';
            end
            
            if ~isfield(options, 'data_product')
                options.data_product = 'grid_data';
            end
            
            if ~isfield(options, 'data_selection')
                options.data_selection = 'selection';
            end
            
            if ~isfield(options, 'grid')
                options.grid = geospm.Grid();
            end
            
            if ~isfield(options, 'assigned_grid')
                options.assigned_grid = options.grid;
            end
            
            obj.mode = '';
            obj.grid = options.grid;
            obj.assigned_grid = options.assigned_grid;
            
            obj.data_requirement = options.data_requirement;
            obj.data_product = options.data_product;
            obj.data_selection = options.data_selection;
            
            obj.define_requirement(obj.data_requirement);
            obj.define_product(obj.data_product);
            obj.define_product(obj.data_selection);
        end
        
        function result = run(obj, arguments)
            
            [grid_data, selection] = obj.grid.grid_data(arguments.(obj.data_requirement), obj.assigned_grid);
            
            result = struct();
            result.(obj.data_product) = grid_data;
            result.(obj.data_selection) = selection;
        end
    end
    
end
