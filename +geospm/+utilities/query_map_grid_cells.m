% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2023,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function [cells, entity] = query_map_grid_cells(crs, grid, entity, ...
                    optional_sort_order_fn, service_identifier)
    
    if ~exist('service_identifier', 'var')
        service_identifier = 'default';
    end

    if ~exist('optional_sort_order_fn', 'var')
        optional_sort_order_fn = [];
    end

    min_location = grid.origin;
    max_location = min_location + grid.span;
    
    mapping_service = hdng.maps.MappingService.lookup(service_identifier);
    
    entity = mapping_service.query( ...
        crs, ...
        min_location, ...
        max_location, ...
        entity);
    
    if ~isempty(optional_sort_order_fn)
        order = optional_sort_order_fn(entity);

        names = fieldnames(entity);

        for index=1:numel(names)
            name = names{index};
            values = entity.(name);
            entity.(name) = values(order);
        end
    end
    
    [u, v, ~] = grid.space_to_grid(entity.x, entity.y, zeros(numel(entity.x), 1));

    cell_indices = sub2ind(grid.resolution(1:2), u, v);
    
    cells = cell(grid.resolution(1:2));

    for index=1:numel(cell_indices)
        content = cells{cell_indices(index)};
        cells{cell_indices(index)} = [content; index];
    end
end
