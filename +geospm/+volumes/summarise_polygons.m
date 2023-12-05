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

function [result, summary] = summarise_polygons(cell_sample_counts, ...
    cell_labels, cell_label_list, sample_values, resolution, polygons)

    %{
    components = bwconncomp(slice, 4);

    areas = struct.empty;

    for index=1:components.NumObjects
        indices = components.PixelIdxList{index};
        coords = ind2sub(size(slice), indices);
        areas = [areas hdng.one_struct('coords', coords)]; %#ok<AGROW>
    end
    %}
    
    summary = '';
    result = struct();
    
    result.polygon = zeros([polygons.N_elements, 1]);
    result.N_samples = zeros([polygons.N_elements, 1]);
    result.N_cells = zeros([polygons.N_elements, 1]);
    result.mean_value = nan([polygons.N_elements, 1]);
    result.max_value = nan([polygons.N_elements, 1]);
    result.min_value = nan([polygons.N_elements, 1]);
    result.label_indices = cell([polygons.N_elements, 1]);
    
    ctx = hdng.rasters.RasterContext([resolution 1]);
    
    for index=1:polygons.N_elements
        polygon = polygons.nth_element(index);

        ctx.set_fill(0);
        ctx.fill_rect(0, 0, ctx.width, ctx.height);
        
        selector = zeros([1, numel(polygon.N_points)], 'logical');
        
        for r=1:polygon.N_rings
            ring = polygon.nth_ring(r, true);
            selector(r) = ring.vertices.is_clockwise_xy(1, ring.N_points);
        end

        rings = find(selector);
        ctx.set_fill(1);
        
        for r=1:numel(rings)
            ring = polygon.nth_ring(rings(r), true);
            coords = cast(ring.vertices.coordinates, 'double') - 1;
            ctx.fill_polygon(coords(:, 1), coords(:, 2));
        end

        holes = find(~selector);
        ctx.set_fill(0);

        for h=1:numel(holes)
            ring = polygon.nth_ring(holes(h), true);
            coords = cast(ring.vertices.coordinates, 'double') - 1;
            ctx.fill_polygon(coords(:, 1), coords(:, 2));
        end
        
        mask = cast(ctx.canvas, 'logical');
        
        result.N_cells(index) = sum(mask(:));
        result.N_samples(index) = sum(cell_sample_counts(mask(:)));
        result.polygon(index) = index;
        
        if ~isempty(sample_values)
            polygon_values = sample_values(mask(:));
        else
            polygon_values = [];
        end

        if ~isempty(polygon_values)
            result.mean_value(index) = mean(polygon_values);
            result.min_value(index) = min(polygon_values);
            result.max_value(index) = max(polygon_values);
        end

        if ~isempty(cell_labels)
            tmp = cell_labels(mask(:));
            sel = cellfun(@(x) ~isempty(x), tmp);
            tmp = tmp(sel);
            tmp = cell2mat(tmp);
            
            label_indices = sort(unique(tmp));
        else
            label_indices = [];
        end
        
        if numel(label_indices) > 5
            label_indices = label_indices(1:5);
        end

        result.label_indices{index} = label_indices;
    end
    
    [~, order] = sortrows(result.N_samples, 'descend');
    
    result.polygon = result.polygon(order);
    result.N_samples = result.N_samples(order);
    result.N_cells = result.N_cells(order);
    result.mean_value = result.mean_value(order);
    result.max_value = result.max_value(order);
    result.min_value = result.min_value(order);
    result.label_indices = result.label_indices(order);

    positive_indices = find(result.min_value > 0 & result.N_samples > 0);
    summary = [summary summarise(positive_indices, result, 'positive ', cell_label_list) newline];
    
    negative_indices = find(result.min_value < 0 & result.N_samples > 0);
    summary = [summary summarise(negative_indices, result, 'negative ', cell_label_list) newline];
end

function summary = summarise(indices, result, label, cell_label_list)
    
    summary = '';

    if ~isempty(indices)
        plural = 's';
        
        if numel(indices) == 1
            plural = '';
        end

        summary = [summary sprintf('%d %sregion%s:', numel(indices), label, plural)];
    else
        summary = [summary sprintf('No %sregions.', label)];
    end

    for index=1:numel(indices)
        i = indices(index);
        
        N_cells = result.N_cells(i);
        N_samples = result.N_samples(i);

        label_indices = result.label_indices{i};
        labels = join(cell_label_list(label_indices), ', ');

        if ~isempty(labels) && ~isempty(labels{1})
            labels = [': ' labels{1}];
        else
            labels = '';
        end

        summary = [summary newline '  ' sprintf('N=%d, C=%d%s', N_samples, N_cells, labels)]; %#ok<AGROW>
    end

    summary = [summary newline];
end