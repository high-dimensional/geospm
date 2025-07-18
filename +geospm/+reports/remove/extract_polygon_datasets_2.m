% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2021,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function polygon_datasets = extract_polygon_datasets_2(polygon_mask, ...
    polygon_mask_traces, records, slice_name, context)
%extract_polygon_datasets_2
%
%   
%
%   polygon_mask – VolumeReference of mask
%   polygon_mask_traces – SliceShapes of mask
    
    [polygons, slice_index] = context.load_polygons_for_slice_name(...
        polygon_mask_traces, slice_name);
    
    % We need the mask to derive the size of the grid cells in 
    % geographic coordinates.

    mask_volume = context.render_mask_volume(polygon_mask);
    mask_slice = mask_volume.data(:, :, slice_index);
    
    raster_size = size(mask_slice);
    
    record = records.unsorted_records{1};
    
    [spm_input_path, ~] = context.spm_paths_from_record(record);
    context.update_volume_generators(spm_input_path, record);
    
    data_specifier = record('configuration.spatial_data_specifier').unpack();
    
    min_location = cell2mat(data_specifier.min_location);
    max_location = cell2mat(data_specifier.max_location);

    cell_size = (max_location(1:2) - min_location(1:2)) ./ size(mask_slice)';

    dataset_path = data_specifier.file_path;
    dataset = geospm.reports.ReportDataset.load(dataset_path, ...
        dataset_cache, dataset_aliases);
    
    polygon_datasets = dataset.select_polygons(polygons, slice_index, ...
        raster_size, cell_size, 'easting', 'northing');
end

