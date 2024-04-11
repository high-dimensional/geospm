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

function [result, record] = compute(directory, data, spatial_index, ...
                                            save_record, varargin)
    
    %{
        directory – a directory path where all output is stored or empty;
        If empty, a timestamped directory is created in the current working
        directory.
        
        data - a geospm.NumericData object that holds the data to
        be analysed

        spatial_index - a geospm.SpatialIndex object that holds the point
        locations corresponding to data
        
        save_record - If true, the returned metadata record variable will
        be saved to a JSON file.
        
        varargin - Either a geospm.Parameters object or a list of
        name-value arguments.
                                            
        The following name-value arguments are supported:
        
        -------------------------------------------------------------------
        
        grid – a geospm.Grid that defines a transformation from point
               locations to raster locations

        If 'grid' is not specified, a new grid is computed based on
        the extent of the data and the desired spatial resolution
        as indicated by the following parameters:

            min_location - min geographic coordinates of rectangle
            default: floor(data.min_xyz)

            max_location - max geographic coordinates of rectangle
            default: ceil(data.max_xyz)

        spatial_resolution - number of raster cells in the x and y 
        directions for spatial data points inside the rectangle (or
        cube) defined by min_location and max_location.

        If 'spatial_resolution' is not specified it is computed
        by the following parameters:

        Either:
        spatial_resolution_x or spatial_resolution_y (or both)
        If the resolution of one direction is specified the other 
        resolution is derived proportional to the rectangle 
        spanned by min_location and max_location


        Or one of:
        spatial_resolution_min - number of raster cells along the 
        shorter side of the rectangle spanned by min_location and 
        max_location

        spatial_resolution_max - number of raster cells along the
        longer side of the rectangle spanned by min_location and 
        max_location

        If no resolution value is specified, a default value of 200
        for spatial_resolution_max is assumed.

        -------------------------------------------------------------------

        apply_density_mask - limit analysis to raster cells above a certain
                             sample density
        Default value is 'true'.
       
        density_mask_factor - The threshold for the sample density mask is
        derived from this value. It is roughly equivalent to the minimum 
        number of samples centred at a location (for a Gaussian smoothing 
        kernel). More accurately, the maximum value of the kernel for
        each smoothing level is multiplied by this number.
        Default value is 10.0.

        apply_geographic_mask - If a coordinate reference system was defined
        for the data limit analysis to raster cells that are on land.
                                            
        thresholds - A cell array of threshold strings.
        Default value is { 'T[1, 2]: p<0.05 (FWE)' }, which specifies a 
        single two-sided per-voxel family-wise error of 5%. Cf.
        SignificanceTest for more information.
                                            
        trace_thresholds - create shape files delineating significant areas
        Default value is 'true'.
                     
        smoothing_levels - a vector of smoothing diameters in the scale of
        the geographic coordinate system, otherwise in the scale raster
        cells (pixels).
                                      
        smoothing_levels_p_value - a probability value specifying the
        mass of the Gaussian smoothing kernel inside the diameters given
        by the smoothing_levels option.
                                            
        smoothing_method - the smoothing method to be used.
        Default value is 'default'.
                                            
        regression_add_intercept - indicates whether the regression should
        add an intercept term to the data. Default value is 'true'.
        
        add_georeference_to_images – indicates whether images are saved as
        georeferenced tiff files. Default value is 'true'.                                            
        
        Return values:
        result – a struct holding various output fields.
                 directory – the path to the output directory.
                 Useful if an empty directory argument was specified.
                 spm_output_directory – a path to the directory containing
                 all output files produced by SPM directly.
                 threshold_directories – a cell array of all threshold
                 directories.
        record – A record of metadata holding the parameters applied to the
        computation. If the save_record argument was true, this will be
        saved as a JSON-encoded file inside the output directory.
    %}
    
    REGULAR_RUN_MODE = 'regular';
    RESUME_RUN_MODE = 'resume';
    
    if numel(varargin) == 1 && isa(varargin{1}, 'geospm.Parameters')
        
        parameters = varargin{1};
        options = struct();
        
        options.grid = parameters.grid;
        options.apply_density_mask = parameters.apply_density_mask;
        options.density_mask_factor = parameters.density_mask_factor;
        options.apply_geographic_mask = parameters.apply_geographic_mask;
        options.write_applied_mask = parameters.write_applied_mask;
        
        options.thresholds = parameters.thresholds;
        options.trace_thresholds = parameters.trace_thresholds;
        
        options.smoothing_levels = parameters.smoothing_levels;
        options.smoothing_levels_p_value = parameters.smoothing_levels_p_value;
        options.smoothing_method = parameters.smoothing_method;
        
        options.regression_add_intercept = parameters.regression_add_intercept;
        options.add_georeference_to_images = parameters.add_georeference_to_images;
        
        options.report_generator = parameters.report_generator;
        
    else
        options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    end
    
    smoothing_levels_as_z_dimension = all(spatial_index.z == spatial_index.z(1));
    
    if ~isfield(options, 'run_mode')
        options.run_mode = 'regular';
    end
    
    if ~isfield(options, 'grid') || isempty(options.grid)
        options = geospm.auxiliary.parse_spatial_resolution( ...
            spatial_index, options);
        
        options.grid = geospm.Grid();
        
        options.grid.span_frame( ...
            options.min_location, ...
            options.max_location, ...
            options.spatial_resolution);
    end
    
    if ~isfield(options, 'trace_thresholds')
        options.trace_thresholds = true;
    end
    
    if ~isfield(options, 'apply_density_mask')
        options.apply_density_mask = true;
    end
    
    if ~isfield(options, 'density_mask_factor')
        options.density_mask_factor = 10.0;
    end
    
    if ~isfield(options, 'apply_geographic_mask')
        options.apply_geographic_mask = true;
    end
    
    if ~isfield(options, 'write_applied_mask')
        options.write_applied_mask = true;
    end
    
    if numel(directory) == 0
        directory = hdng.utilities.make_timestamped_directory();
    end
    
    if ~isfield(options, 'thresholds')
        options.thresholds = { 'T[1,2]: p<0.05 (FWE)' };
    end
    
    options.thresholds = geospm.SignificanceTest.from_char(options.thresholds);
    
    if ~isfield(options, 'smoothing_levels')
        options.smoothing_levels = [5, 10, 15];
    end
    
    if ~isfield(options, 'smoothing_levels_p_value')
        options.smoothing_levels_p_value = 0.95;
    end
    
    if ~isfield(options, 'smoothing_method')
        options.smoothing_method = 'default';
    end
    
    if ~isfield(options, 'regression_add_intercept')
        options.regression_add_intercept = true;
    end
    
    if ~isfield(options, 'add_georeference_to_images')
        options.add_georeference_to_images = true;
    end
    
    if ~isfield(options, 'report_generator')
        options.report_generator = [];
    end
    
    if ~smoothing_levels_as_z_dimension
        if numel(options.smoothing_levels) ~= 3
            error('geospm.compute(): If a z-coordinate is provided, the number of smoothing levels must equal 3, one level per dimension.');
        end
    end
    
    if options.regression_add_intercept
    	data = data.concat_variables(ones(data.N, 1), {'intercept'}, data.P + 1);
    end
    
    record = geospm.auxiliary.metadata_from_options('geospm.', options);
    
    record('geospm.description') = data.description;
    
    source_version = hdng.utilities.SourceVersion(fileparts(mfilename('fullpath')));
    record('geospm.source_version') = source_version.string;
    
    spm_version = geospm.spm.SPMJobList.access_spm_interface().version_string;
    record('geospm.spm_version') = spm_version;
    
    started = datetime('now', 'TimeZone', 'local', 'Format', 'yyyy/MM/dd HH:mm:ss');
    record('geospm.started') = char(started);
    
    %Create contrasts

    [contrasts, contrasts_per_threshold] = ...
        geospm.utilities.define_simple_contrasts(...
            options.thresholds, data.variable_names);
    
    [contrasts, contrast_groups] = ...
        geospm.utilities.order_domain_contrasts(...
        contrasts, {'T', 'F'}); %#ok<ASGLU>
    
    analysis = geospm.SpatialAnalysis();

    analysis.define_requirement('directory');
    analysis.define_requirement('spatial_data');
    analysis.define_requirement('spatial_index');

    analysis.define_requirement('smoothing_levels');
    analysis.define_requirement('smoothing_levels_p_value');
    analysis.define_requirement('smoothing_levels_as_z_dimension');

    analysis.define_requirement('smoothing_method');

    analysis.define_requirement('run_spm_distance_regression');
    analysis.define_requirement('regression_add_intercept');
    analysis.define_requirement('contrasts');
    analysis.define_requirement('thresholds');
    analysis.define_requirement('threshold_contrasts');

    analysis.define_requirement('regression_probes');

    analysis.define_product('sample_density');
    analysis.define_product('selection');

    if strcmp(options.run_mode, REGULAR_RUN_MODE) || ...
         strcmp(options.run_mode, RESUME_RUN_MODE)
        analysis.define_product('threshold_directories');
        analysis.define_product('image_records');
        analysis.define_product('beta_records');
        analysis.define_product('density_image');
    end

    analysis.define_product('spm_job_list');
    analysis.define_product('spm_output_directory');
    analysis.define_product('regression_probe_file');

    geospm.stages.GridTransform(analysis, 'grid', options.grid);
    
    geospm.stages.SPMSpatialSmoothing(analysis);

    regression_stage = geospm.stages.SPMDistanceRegression(analysis);
    regression_stage.apply_density_mask = options.apply_density_mask;
    regression_stage.write_applied_mask = options.write_applied_mask;
    
    if ~isempty(options.density_mask_factor)
        regression_stage.density_mask_factor = options.density_mask_factor;
    end

    if strcmp(options.run_mode, REGULAR_RUN_MODE) || ...
         strcmp(options.run_mode, RESUME_RUN_MODE)

        geospm.stages.SPMApplyThresholds(analysis, [], 'output_prefix', 'th_');
        render_images = geospm.stages.SPMRenderImages(analysis);
        render_images.ignore_crs = ~options.add_georeference_to_images;
        
        if options.trace_thresholds
            geospm.stages.SPMTraceThresholdRegions(analysis);
        end
    end

    arguments = struct();
    arguments.directory = directory;
    arguments.spatial_data = data;
    arguments.spatial_index = spatial_index;
    
    arguments.smoothing_levels = options.smoothing_levels;
    arguments.smoothing_levels_p_value = options.smoothing_levels_p_value;
    arguments.smoothing_levels_as_z_dimension = smoothing_levels_as_z_dimension;

    arguments.smoothing_method = options.smoothing_method;

    arguments.regression_probes = [];
    arguments.regression_add_intercept = false;
    
    arguments.contrasts = geospm.utilities.spm_jobs_from_domain_contrast_groups(contrast_groups);

    %Specify thresholds to be used by SPMApplyThresholds

    contrasts_per_threshold_tmp = contrasts_per_threshold;
    
    for index=1:numel(contrasts_per_threshold_tmp)
        threshold_contrasts = contrasts_per_threshold_tmp{index};
        threshold_contrast_indices = zeros(size(threshold_contrasts));
        
        for c=1:numel(threshold_contrasts)
            contrast = threshold_contrasts{c};
            threshold_contrast_indices(c) = contrast.order;
        end
        

        threshold_contrast_indices = sortrows(threshold_contrast_indices, 1);

        contrasts_per_threshold_tmp{index} = threshold_contrast_indices;
    end

    contrasts_per_threshold = contrasts_per_threshold_tmp;

    arguments.thresholds = options.thresholds;
    arguments.threshold_contrasts = contrasts_per_threshold;

    arguments.run_spm_distance_regression = ...
      strcmp(options.run_mode, REGULAR_RUN_MODE);

    cwd = cd;
  
    try
        result = analysis.run(arguments);
    catch ME
        cd(cwd);
        rethrow(ME);
    end
    
    result.directory = directory;
    stopped = datetime('now', 'TimeZone', 'local', 'Format', 'yyyy/MM/dd HH:mm:ss');
    record('geospm.stopped') = char(stopped);
    
    if save_record
        record_path = fullfile(directory, 'metadata.json');
        record_text = hdng.utilities.encode_json(record);
        hdng.utilities.save_text(record_text, record_path);
    end
end
