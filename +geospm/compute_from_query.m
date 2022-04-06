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

function compute_from_query(directory, spatial_data_path, ...
                            query_geometry_path, varargin)
    
    %{
        A convenience method for geospm.compute().
        
        Loads a spatial data instance from the specified file path, queries
        geographic regions in the data and computes a separate analysis for
        each region. All results will be stored in the given directory, or
        if empty, a new directory with a timestamp will be created in the
        current working directory.
        
        Please note that the current implementation of the
        query mechanism is not very efficient, which will be noticeable 
        for larger data sets.
        
        All name-value options understood by geospm.compute() can also
        be passed to this function. 
        
        In addition, the following name-value options can be used:
                            
        sample_granularity – the effective resolution scale of the input
        data. For example, when specifying coordinates in the British 
        Ordnance Survey grid, the effective resolution of the locations 
        might not be metres, but kilometres, so a suitable value for
        sample_granularity would be 1000.
        
        grid_granularity
        
    %}
    
                            
    [load_options, analysis_options] = geospm.auxiliary.parse_load_options(varargin{:});
    
    options = struct();
    
    if ~isfield(analysis_options, 'sample_granularity')
        options.sample_granularity = 1.0;
    else
        options.sample_granularity = analysis_options.sample_granularity;
        analysis_options = rmfield(analysis_options, 'sample_granularity');
    end
    
    if ~isfield(analysis_options, 'grid_granularity')
        options.grid_granularity = options.sample_granularity;
    else
        options.grid_granularity = analysis_options.grid_granularity;
        analysis_options = rmfield(analysis_options, 'grid_granularity');
    end
    
    if ~isfield(analysis_options, 'smoothing_levels')
        analysis_options.smoothing_levels = [10 20 30];
    end
    
    load_arguments = hdng.utilities.struct_to_name_value_sequence(load_options);
    
    fprintf('Loading spatial data from file: %s\n', spatial_data_path);
    spatial_data = geospm.load_data(spatial_data_path, load_arguments{:});
    
    have_query = numel(query_geometry_path) ~= 0;
        
    if have_query
        
        fprintf('Loading query geometry from file: %s\n', query_geometry_path);
        [geometry, attributes] = hdng.geometry.FeatureGeometry.load(query_geometry_path);
        
        query_region_names = strings_from_attributes(...
            geometry.collection.N_elements, attributes, {'identifier', 'name'});
        
        query_region_identifiers = strings_from_attributes(...
            geometry.collection.N_elements, attributes, {'name', 'identifier'});
        
        for index=1:numel(query_region_names)
            name = query_region_identifiers{index};
            identifier = make_identifier(name);
            query_region_identifiers{index} = identifier;
        end
        
        crs = geometry.crs;

        if isempty(spatial_data.crs) ~= isempty(crs)
            if isempty(spatial_data.crs)
                error('Spatial data is missing CRS, but query geometry has CRS assigned.');
            else
                error('Spatial data has CRS, but query geometry is missing CRS.');
            end
        end

        if ~isempty(spatial_data.crs) && ~isempty(crs) && ~strcmp(spatial_data.crs.identifier, crs.identifier)
            error(['Spatial data CRS (=' spatial_data.crs.identifier ') does not match query geometry CRS (=' crs.identifier ').']);
        end

        if ~crs.is_projected
            error('Query geometry must be in projected coordinates.');
        end
    else
        
        collection = hdng.geometry.Polygon.span_frame(...
            spatial_data.min_xyz(1:2) - eps, ...
            spatial_data.max_xyz(1:2) + eps);
        
        geometry = hdng.geometry.FeatureGeometry.define(collection, spatial_data.crs);
        query_region_names = { 'Region 1' };
        query_region_identifiers = { 'region_1' };
    end
    
    identifier_map = hdng.utilities.Dictionary();
    
    for index=1:numel(query_region_identifiers)
        identifier = query_region_identifiers{index};
        
        if identifier_map.holds_key(identifier)
            indices = identifier_map(identifier);
        else
            indices = [];
        end
        
        indices = [indices; index]; %#ok<AGROW>
        identifier_map(identifier) = indices;
    end
    
    have_colliding_identifiers = false;
    
    for index=1:numel(query_region_identifiers)
        identifier = query_region_identifiers{index};
        indices = identifier_map(identifier);
        
        have_colliding_identifiers = ...
            have_colliding_identifiers || numel(indices) > 1;
        
        if numel(indices) > 1
            
            msg = '';
            
            for j=1:numel(indices)
                c = indices(j);
                msg = sprintf('%s[%d] %s\n', msg, c, query_region_names{c});
                warning('geospm.compute_from_query(): The identifiers for the following query regions are identical:\n%s', msg);
            end
        end
    end
    
    if have_colliding_identifiers
        error('geospm.compute_from_query(): Can''t continue because one or more query region identifiers are the same');
    end
    
    collection = geometry.collection;
    
    if ~strcmp(collection.element_type, 'hdng.geometry.Polygon')
        error('Query geometry must be composed of polygons.');
    end
    
    fprintf('Building query regions...\n');
    
    surfaces = cell(collection.N_elements, 1);
    
    for i=1:collection.N_elements
        surfaces{i} = collection.nth_element(i);
    end
    
    
    selectors = zeros(collection.N_elements, spatial_data.N, 'logical');
    
    X = spatial_data.x;
    Y = spatial_data.y;
    N = spatial_data.N;
    
    if have_query
        parfor j=1:numel(surfaces)
            surface = surfaces{j};

            for i=1:N

                x = X(i); %#ok<PFBNS>
                y = Y(i); %#ok<PFBNS>

                p = hdng.geometry.Point.define(x, y);
                selectors(j, i) = surface.contains(p);
            end
        end
    else
        selectors = ones(collection.N_elements, spatial_data.N, 'logical');
    end
    
    row_selector = sum(selectors, 1);
    unselected_rows = find(~row_selector);
    unselected_rows_string = '';
    
    for i=1:numel(unselected_rows)
        r = unselected_rows(i);
        unselected_rows_string = [unselected_rows_string '    ' num2str(r, '%d') newline]; %#ok<AGROW>
    end
    
    if numel(unselected_rows) ~= 0
        fprintf('The following %d rows weren''t associated with a location contained in any of the query regions:\n%s', numel(unselected_rows), unselected_rows_string);
    end
    
    if numel(directory) == 0
        directory = hdng.utilities.make_timestamped_directory(pwd);
    else
        [dirstatus, dirmsg] = mkdir(directory);
        if dirstatus ~= 1; error(dirmsg); end
    end
    
    analysis_arguments = hdng.utilities.struct_to_name_value_sequence(analysis_options);
    
    fprintf('Analysing query regions...\n');
    
    for i=1:numel(surfaces)
        
        region_name = query_region_names{i};
        
        N_observations = sum(selectors(i, :));
        
        if N_observations ~= 0
            fprintf('There are %d observations in region "%s"\n', N_observations, region_name);
        end
        
        if N_observations == 0
            fprintf('There are no observations in region "%s", skipping...\n', region_name);
            continue;
        end
        
        region = surfaces{i};
        
        [min_coords, max_coords] = region.vertices.extent();
        
        if isempty(min_coords) || isempty(max_coords)
            continue;
        end
        
        g = cast(options.sample_granularity, 'double');
        
        %min_point = min_coords;
        %max_point = max_coords ...
        %            + cast(options.sample_granularity, 'double') - eps;
        
        min_point = floor(min_coords ./ g) .* g;
        max_point = ceil(max_coords ./ g) .* g;
        
        region_data = spatial_data.select(find(selectors(i, :))); %#ok<FNDSB>
        region_data = region_data.filter_constant_variables(1e-1, false);
        region_data.description = region_name;
        
        %region_data_rank = rank(region_data.observations, 1e-10);
        %fprintf('The observation matrix has rank %d\n', region_data_rank);
        
        if (region_data.P == 0 && region_data.N < 1000) || (region_data.N < region_data.P)
            fprintf('There are too few observations in region "%s", skipping...\n', region_name);
            continue;
        end
        
        region_identifier = query_region_identifiers{i};
        region_directory = fullfile(directory, region_identifier);
        
        [dirstatus, dirmsg] = mkdir(region_directory);
        if dirstatus ~= 1; error(dirmsg); end
        
        g = cast(options.grid_granularity, 'double');
        spatial_resolution = ceil((max_point - min_point) ./ g);
        
        [~, record] = geospm.compute(...
            region_directory, ...
            region_data, ...
            false, ...
            'spatial_resolution', spatial_resolution, ...
            'min_location', min_point, ...
            'max_location', max_point, ...
            analysis_arguments{:});
        
        record('task.spatial_data_path') = spatial_data_path;
        record = geospm.auxiliary.metadata_from_options('task.', options, record);
        record = geospm.auxiliary.metadata_from_options('load.', load_options, record);
        
        record_path = fullfile(region_directory, 'metadata.json');
        record_text = hdng.utilities.encode_json(record);
        hdng.utilities.save_text(record_text, record_path);
    end
    
    fprintf('Done.\n');
end

function result = strings_from_attributes(N, attributes, names)
    
    attribute_matches = cell(numel(names), 1);
    available = {};

    for index=1:numel(attributes)
        attribute = attributes{index};
        
        for j=1:numel(names)
            name = names{j};
            
            if strcmp(attribute.label, name)
                attribute_matches{j} = attribute;
                available{end + 1} = attribute; %#ok<AGROW>
                break;
            end
        end
    end
    
    result = cell(N, 1);
    
    for index=1:N
        
        value = [];
        
        for j=1:numel(available)
            attribute = available{j};
            
            if attribute.is_missing(index)
                continue
            end
            
            value = attribute.data{index};
            break;
        end
        
        if isempty(value)
            value = ['Region ' sprintf('%d', index)];
        end
        
        result{index} = value;
    end
end

function result = make_identifier(value)

    value = lower(value);
    value = regexprep(value, '\s|\t|\n|\r', '_');
    value = regexprep(value, '-', '_');
    value = regexprep(value, '[^A-Za-z0-9_]', '');
    value = regexprep(value, '_+', '_');
    result = value;
end
