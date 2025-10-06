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

function rendering_task(base_directory, render_options, grid_options, varargin)
    
    options = hdng.utilities.parse_struct_from_varargin(varargin{:});

    if ~isfield(options, 'host_name')
        options.host_name = 'http://localhost:9999';
    end

    if ~isfield(options, 'clear_source_refs')
        options.clear_source_refs = false;
    end

    if ~isfield(options, 'dataset_aliases')
        options.dataset_aliases = hdng.utilities.Dictionary();
    end

    if ~isfield(options, 'force_preprocessing')
        options.force_preprocessing = false;
    end
    
    if ~isfield(options, 'render_fn')
        options.render_fn = [];
    end
    
    if ~isfield(options, 'cell_layer_fn')
        options.cell_layer_fn = @get_cell_values;
    end
    
    if ~isfield(options, 'layer_value_paths')
        options.layer_value_paths = {...
            'configuration.image_layers', ...
            'result.terms.contrast', ...
            'result.terms.mask_traces', ...
        };
    end

    if ~isfield(options, 'adjust_colour_mapping')
        options.adjust_colour_mapping = false;
    end

    if ~isfield(options, 'colour_mapping')
        options.colour_mapping = hdng.one_struct('batch', 'per_column', 'combine_studies', false);
        options.colour_mapping.selected_column_values = {...
        };
    end

    if ~isfield(options, 'resource_path_aliases')
        options.resource_path_aliases = containers.Map('KeyType', 'char', 'ValueType', 'char');
    end

    if ~isfield(options, 'resource_identifier_expr')

        options.resource_identifier_expr = ...
        replace('^(?<prefix>[^%sep]+).*(?<identifier>%seppresentation%sep(map_background.png|map_foreground.png))$', '%sep', filesep);
        
        
        %sprintf('.*(?<identifier>%spresentation%s(map_background.png|map_foreground.png))$', filesep, filesep);
    end

    if ~isfield(render_options, 'label_style')
        
        label_style = hdng.typesetting.Style();
        label_style.font_family = 'Barlow';
        label_style.font_size = 34;
        
        render_options.label_style = label_style;
    end
    
    studies = geospm.reports.scan_regional_directories(base_directory, options.suffix);
    %studies = studies(2);
    
    tmp_dir = hdng.utilities.make_timestamped_directory(base_directory);
    
    selected_layer_categories = {'underlay', 'content', 'overlay'};
    
    preprocessing_identifier = '_poly';

    geospm.reports.build_record_grids_for_studies(studies, ...
        preprocessing_identifier, ...
        grid_options.row_field, grid_options.column_field, grid_options, ...
        'do_debug', options.do_debug, ...
        'force_preprocessing', options.force_preprocessing, ...
        'output_dir', tmp_dir);

    shared_variables = geospm.reports.SharedVariables([], options.dataset_aliases);
    shared_variables.host_name = options.host_name;
    shared_variables.resource_manager = geospm.resources.ReportResourceManager();
    shared_variables.resource_manager.host_name = options.host_name;
    shared_variables.resource_manager.slice_name = options.slice_name;
    shared_variables.resource_manager.path_aliases = options.resource_path_aliases;
    shared_variables.resource_manager.resource_identifier_expr = options.resource_identifier_expr;

    render_attachment = 'render_contexts';
    dataset_attachment = 'polygon_datasets';
    file_paths_attachment = 'grid_volume_file_paths';
    preprocessed_attachment = 'preprocessed_values';
    preprocessing_identifier = '_poly';

    layer_unpack_options = struct();
    layer_unpack_options.layer_value_paths = options.layer_value_paths;
    layer_unpack_options.clear_source_refs = options.clear_source_refs;
    layer_unpack_options.path_prefix = '';

    [studies, group_widths, group_heights] = ...
        geospm.reports.build_render_cells(studies, preprocessing_identifier, ...
        preprocessed_attachment, render_attachment, file_paths_attachment, ...
        options.cell_layer_fn, selected_layer_categories, ...
        layer_unpack_options, render_options, shared_variables);
    
    [studies, ~, ~] = ...
        geospm.reports.build_polygon_datasets(studies, ...
        preprocessing_identifier, ...
        preprocessed_attachment, dataset_attachment, ...
        shared_variables, ...
        options.cell_mask_volume_fn, render_options.slice_name);
    
    studies = geospm.reports.order_record_grid(studies, grid_options.column_order);

    tmp_dirs = {};
    colour_map_legends = {};

    if options.adjust_colour_mapping || ~isempty(options.colour_mapping)
        
    
        [colour_map_legends, tmp_dirs] = geospm.reports.colour_map_study_grids(...
            studies, group_heights, group_widths, options.colour_mapping, ...
            render_attachment, file_paths_attachment, tmp_dir, ...
            shared_variables);
    end

    service = hdng.resources.ResourceService();
    requests = shared_variables.resource_manager.launch_resource_requests(service, shared_variables.resources); %#ok<NASGU>
    
    % Not running asynchronously, so all requests should have stopped
    no_outstanding_requests = service.total_requests == service.stopped_requests;

    if no_outstanding_requests && ~isempty(options.render_fn)
        
        attachments = struct();
        attachments.render = render_attachment;
        attachments.dataset = dataset_attachment;
        attachments.file_paths = file_paths_attachment;

        options.render_fn(studies, colour_map_legends, shared_variables, attachments, render_options, tmp_dir);
    end
    
    requests = []; %#ok<NASGU>
    
    for d=1:numel(tmp_dirs)

        [status, msg] = rmdir(tmp_dirs{d}, 's');
        
        if ~status
            error(msg);
        end
    end
end
