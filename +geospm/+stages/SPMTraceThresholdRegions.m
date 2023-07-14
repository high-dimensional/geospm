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

 classdef SPMTraceThresholdRegions < geospm.stages.SpatialAnalysisStage
    %SPMTraceThresholdRegions Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        shape_formats
        centre_pixels
        volume_renderer
        render_component_contrasts
    end
    
    methods
        
        function obj = SPMTraceThresholdRegions(analysis)
            
            obj = obj@geospm.stages.SpatialAnalysisStage(analysis);

            obj.volume_renderer = geospm.volumes.Tracing();
            obj.shape_formats = {'shp'};
            obj.centre_pixels = false;
            obj.render_component_contrasts = false;
            
            obj.define_requirement('directory');
            obj.define_requirement('spm_output_directory');
            
            obj.define_requirement('thresholds');
            obj.define_requirement('threshold_directories');
            
            obj.define_requirement('grid_data', ...
                struct(), 'is_optional', true, 'default_value', []);
            
            obj.define_requirement('volume_mask_file', ...
                struct(), 'is_optional', true, 'default_value', []);
            
            obj.define_requirement('image_records', ...
                struct(), 'is_optional', true, 'default_value', []);
        end
        
        function result = run(obj, arguments)
            
            result = [];
            
            session = geospm.spm.SPMSession(fullfile(arguments.spm_output_directory, 'SPM.mat'));
            
            grid = geospm.Grid();
            crs = hdng.SpatialCRS.empty;
            
            if ~isempty(arguments.grid_data)
                grid = arguments.grid_data.grid;
                crs = arguments.grid_data.crs;
            end
            
            settings = geospm.volumes.RenderSettings();
            
            settings.formats = obj.shape_formats;
            settings.grid = grid;
            settings.crs = crs;
            settings.centre_pixels = obj.centre_pixels;

            context = geospm.volumes.RenderContext();
            context.render_settings = settings;

            if ~isempty(arguments.volume_mask_file)
                mask_set = geospm.volumes.VolumeSet();
                mask_set.file_paths = { arguments.volume_mask_file };

                context.image_volumes = mask_set;
                context.output_directory = fullfile(arguments.directory, 'images');

                obj.volume_renderer.render(context);
            end
            
            threshold_directories = arguments.threshold_directories;
            
            for i=1:numel(threshold_directories)
                
                threshold_directory = threshold_directories{i};
                
                [~, directory_name, ext] = fileparts(threshold_directory);
                directory_name = [directory_name ext]; %#ok<AGROW>
                
                threshold_output_directory = fullfile(arguments.directory, 'images', directory_name);
                paired_trace_paths = {};
                trace_paths = {};
                
                [matched_files, ~, matched_statistics] = session.match_statistic_paired_threshold_files('', threshold_directory);
                
                if ~isempty(matched_files)

                    if numel(matched_statistics) ~= 1
                        error('SPMTraceThresholdRegions.run(): Cannot handle a threshold with more than one statistic.');
                    end
                    
                    mask_set = geospm.volumes.VolumeSet();
                    mask_set.file_paths = matched_files;

                    context.image_volumes = mask_set;
                    context.output_directory = threshold_output_directory;

                    paired_trace_paths = obj.volume_renderer.render(context);
                end
                
                [match_result, matched_statistics] = session.match_statistic_threshold_files('', threshold_directory);
                

                if isempty(matched_files) || obj.render_component_contrasts
                    
                    if ~match_result.did_match_all_files
                        error(['SPMTraceThresholdRegions.run(): Couldn''t locate all threshold files in ''' threshold_directory '''.']);
                    end
                    
                    if numel(matched_statistics) ~= 1
                        error('SPMTraceThresholdRegions.run(): Cannot handle a threshold with more than one statistic.');
                    end
                    
                    mask_set = geospm.volumes.VolumeSet();
                    mask_set.file_paths = match_result.matched_files;
                    
                    context.image_volumes = mask_set;
                    context.output_directory = threshold_output_directory;
                    
                    trace_paths = obj.volume_renderer.render(context);
                end
                
                image_record = obj.image_record_for_threshold(arguments, i);

                if isempty(image_record)
                    continue
                end
                
                mask_traces = hdng.utilities.Dictionary();
                mask_traces('volumes') = hdng.experiments.Value.from({});
                mask_traces('images') = hdng.experiments.Value.from([paired_trace_paths; trace_paths]);
                mask_traces('descriptions') = hdng.experiments.Value.from({});

                image_record('mask_traces') = hdng.experiments.Value.from(mask_traces); %#ok<NASGU> 
            end

            image_record = obj.image_record_for_threshold(arguments, []);

            if ~isempty(image_record)
                image_record('mask_traces') = hdng.experiments.Value.empty_with_label('No mask traces.'); %#ok<NASGU> 
            end
        end
        
        function result = image_record_for_threshold(~, arguments, index)
                
            result = [];

            if isempty(arguments.image_records)
                return
            end
            
            if isempty(index)
                match_value = hdng.experiments.Value.empty_with_label('');
            else
                match_value = hdng.experiments.Value.from(index);
            end

            image_records = arguments.image_records.select(hdng.one_struct('threshold', match_value));

            if image_records.length ~= 1
                return
            end

            result = image_records.unsorted_records{1};
        end
    end
end
