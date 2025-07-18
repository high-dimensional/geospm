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

classdef PolygonQuery < geospm.reports.ReportQuery
    
    %PolygonQuery 
    %

    properties (GetAccess=public, SetAccess=public)
        
        polygon         % the polygon defining this query
        polygon_index   % the index of the polygon in its slice
        
        mask            % a binary mask for this polygon query
    end
    
    methods
        
        function obj = PolygonQuery(slice_index, polygon_index, polygon)

            obj@geospm.reports.ReportQuery();

            obj.slice_index = slice_index;

            obj.polygon_index = polygon_index;
            obj.polygon = polygon;

        end
        

        function mask = compute_mask(obj, ctx)
        
            ctx.set_fill(0);
            ctx.fill_rect(0, 0, ctx.width, ctx.height);
            
            if ~isempty(obj.polygon)
    
                coordinates = [obj.polygon.vertices.x';
                               obj.polygon.vertices.y'];
    
                coordinates = (coordinates - obj.min_location(1:2)) ./ obj.cell_size + 1;
                
                vertices = hdng.geometry.Vertices.define(coordinates');
                mask_polygon = obj.polygon.substitute_vertices(vertices);
        
                selector = zeros([1, numel(mask_polygon.N_points)], 'logical');
                
                for r=1:mask_polygon.N_rings
                    ring = mask_polygon.nth_ring(r, true);
                    selector(r) = ring.vertices.is_clockwise_xy(1, ring.N_points);
                end
        
                rings = find(selector);
                ctx.set_fill(1);
                
                for r=1:numel(rings)
                    ring = mask_polygon.nth_ring(rings(r), true);
                    coords = cast(ring.vertices.coordinates, 'double') - 1;
                    ctx.fill_polygon(coords(:, 1), coords(:, 2));
                end
        
                holes = find(~selector);
                ctx.set_fill(0);
        
                for h=1:numel(holes)
                    ring = mask_polygon.nth_ring(holes(h), true);
                    coords = cast(ring.vertices.coordinates, 'double') - 1;
                    ctx.fill_polygon(coords(:, 1), coords(:, 2));
                end
            end

            mask = cast(ctx.canvas, 'logical');
        end
        
    end
end
