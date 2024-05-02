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

classdef GridTransform < geospm.stages.SpatialAnalysisStage
    
    properties
        data_requirement
        spatial_index_requirement

        data_product
        spatial_index_product
        grid_product

        data_selection
        
        assigned_grid
    end
    
    properties (SetAccess=private)
        mode
        grid
    end
    
    methods
        
        function obj = GridTransform(analysis, varargin)
            obj = obj@geospm.stages.SpatialAnalysisStage(analysis);
            
            options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            
            if ~isfield(options, 'data_requirement')
                options.data_requirement = 'spatial_data';
            end
            
            if ~isfield(options, 'spatial_index_requirement')
                options.spatial_index_requirement = 'spatial_index';
            end
            
            if ~isfield(options, 'data_product')
                options.data_product = 'grid_data';
            end
            
            if ~isfield(options, 'spatial_index_product')
                options.spatial_index_product = 'grid_spatial_index';
            end
            
            if ~isfield(options, 'grid_product')
                options.grid_product = 'grid';
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
            obj.spatial_index_requirement = options.spatial_index_requirement;

            obj.data_product = options.data_product;
            obj.spatial_index_product = options.spatial_index_product;
            obj.grid_product = options.grid_product;

            obj.data_selection = options.data_selection;
            
            obj.define_requirement(obj.data_requirement);
            obj.define_requirement(obj.spatial_index_requirement);
            obj.define_product(obj.data_product);
            obj.define_product(obj.spatial_index_product);
            obj.define_product(obj.grid_product);
            obj.define_product(obj.data_selection);
        end
        
        function result = run(obj, arguments)
            
            spatial_data = arguments.(obj.data_requirement);
            spatial_index = arguments.(obj.spatial_index_requirement);

            [grid_spatial_index, ~, selection] = obj.grid.transform_spatial_index(spatial_index, obj.assigned_grid);
            
            grid_data = spatial_data.select(selection, []);

            result = struct();
            result.(obj.data_product) = grid_data;
            result.(obj.spatial_index_product) = grid_spatial_index;
            result.(obj.grid_product) = obj.assigned_grid;
            result.(obj.data_selection) = selection;
        end
    end
    
end
