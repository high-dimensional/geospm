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

function [result, record] = compute(directory, spatial_data, ...
                                            save_record, varargin)
    
    %{
        directory – a directory path where all output is stored;
        If empty, a timestamped directory is created in the current working
        directory.

        The following name-value arguments are supported:
        
        -------------------------------------------------------------------
        Either,
                                            
        grid – a geospm.Grid that defines a transformation from point
               locations to raster locations
                                            
        Or:
                                            
        min_location - min geographic coordinates of rectangle 
        max_location - max geographic coordinates of rectangle
        spatial_resolution_x - number of raster cells in the x direction
        spatial_resolution_y - number of raster cells in the y direction
        spatial_resolution
                                            
        spatial_resolution_min
        spatial_resolution_max
        -------------------------------------------------------------------
        
        Miscellaneous options:
                                            
        trace_thresholds - create shape files delineating significant areas
        Default value is 'true'.
        
        apply_density_mask - limit analysis to raster cells above a certain
                             sample density
        Default value is 'true'.
        
        density_mask_factor - threshold to use for the density mask
        Default value is '[]' (empty), will be set by the smoothing
        mechanism.
                                            
        thresholds - A cell array of threshold strings.
        Default value is { 'T[1, 2]: p<0.05 (FWE)' }, which specifies a 
        single two-sided per-voxel family-wise error of 5%. Cf.
        SignificanceTest for more information.
                                            
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

    options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    smoothing_levels_as_z_dimension = all(spatial_data.z == spatial_data.z(1));
    
    if ~isfield(options, 'run_mode')
        options.run_mode = 'regular';
    end
    
    if ~isfield(options, 'grid')
        options = geospm.auxiliary.parse_spatial_resolution(spatial_data, options);
        
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
        options.density_mask_factor = [];
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
    	spatial_data = spatial_data.concat_variables(ones(spatial_data.N, 1), {'intercept'}, spatial_data.P + 1);
    end
    
    record = geospm.auxiliary.metadata_from_options('geospm.', options);
    
    record('geospm.description') = spatial_data.description;
    
    source_version = hdng.utilities.SourceVersion(fileparts(mfilename('fullpath')));
    record('geospm.source_version') = source_version.string;
    
    spm_version = geospm.spm.SPMJobList.access_spm_interface().version_string;
    record('geospm.spm_version') = spm_version;
    
    started = datetime('now', 'TimeZone', 'local', 'Format', 'yyyy/MM/dd HH:mm:ss');
    record('geospm.started') = char(started);
    
    %Create contrasts

    [contrasts, contrasts_per_threshold] = ...
        geospm.utilities.define_domain_contrasts(...
            options.thresholds, spatial_data.variable_names);
    
    [contrasts, contrast_groups] = ...
        geospm.utilities.order_domain_contrasts(...
        spatial_data.variable_names, ...
        contrasts, ...
        {'T', 'F'}); %#ok<ASGLU>
    
    analysis = geospm.SpatialAnalysis();

    analysis.define_requirement('directory');
    analysis.define_requirement('spatial_data');

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
    regression_stage.apply_volume_mask = options.apply_density_mask;
    regression_stage.write_volume_mask = options.apply_density_mask;
    
    if ~isempty(options.density_mask_factor)
        regression_stage.volume_mask_factor = options.density_mask_factor;
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
    arguments.spatial_data = spatial_data;
    
    arguments.smoothing_levels = options.smoothing_levels;
    arguments.smoothing_levels_p_value = options.smoothing_levels_p_value;
    arguments.smoothing_levels_as_z_dimension = smoothing_levels_as_z_dimension;

    arguments.smoothing_method = options.smoothing_method;

    arguments.regression_probes = [];

    %{
    if obj.add_probes
        [grid_probe_data, ~] = grid_stage.grid.grid_data(obj.probe_data);
        arguments.regression_probes = grid_probe_data;
    end
    %}
    
    arguments.regression_add_intercept = false;
    
    arguments.contrasts = geospm.utilities.spm_jobs_from_domain_contrast_groups(contrast_groups);

    %Specify thresholds to be used by SPMApplyThresholds

    contrasts_per_threshold_arg = contrasts_per_threshold;

    for index=1:numel(contrasts_per_threshold_arg)
        threshold_contrasts = contrasts_per_threshold_arg{index};

        for c=1:numel(threshold_contrasts)
            contrast = threshold_contrasts{c};
            threshold_contrasts{c} = contrast.order;
        end

        contrasts_per_threshold_arg{index} = threshold_contrasts;
    end
    
    arguments.thresholds = options.thresholds;
    arguments.threshold_contrasts = contrasts_per_threshold_arg;

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
