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

 classdef SPMApplyThresholds < geospm.stages.SpatialAnalysisStage
    %SPMApplyThresholds Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    properties (Constant)
        
        PEAK_STATISTIC = 9
        PEAK_EQUIV_Z = 10
        PEAK_LOCATION = 12
        PEAK_UNCORRECTED_P = 11
        PEAK_FWE_CORRECTED_P = 7
        PEAK_FDR_CORRECTED_P = 8
        
        CLUSTER_UNCORRECTED_P = 6
        CLUSTER_EQUIV_K = 5
        CLUSTER_FWE_CORRECTED_P = 3
        CLUSTER_FDR_CORRECTED_P = 4
        
        SET_P = 1
        SET_C = 2
    end
    
    methods (Static)
        
        function result = directory_name_for_threshold(threshold_index, ~)
            
            result = sprintf('th_%d', threshold_index);
        end
    end
    
    methods
        
        function obj = SPMApplyThresholds(analysis, options, varargin)
            
            obj = obj@geospm.stages.SpatialAnalysisStage(analysis);
            
            if ~exist('options', 'var')
                options = struct();
            end
            
            if isempty(options)
                options = struct();
            end
            
            additional_options = hdng.utilities.parse_struct_from_varargin(varargin{:});
            additional_names = fieldnames(additional_options);
            
            for i=1:numel(additional_names)
                name = additional_names{i};
                options.(name) = additional_options.(name);
            end
            
            obj.define_requirement('directory');
            obj.define_requirement('spm_output_directory');
            
            obj.define_requirement('thresholds');
            obj.define_requirement('threshold_contrasts');
            obj.define_requirement('volume_precision');
            
            obj.define_requirement('grid_data', ...
                struct(), 'is_optional', true, 'default_value', []);
            
            obj.define_product('threshold_directories');
            
        end
        
        function result = run(obj, arguments)
            
            grid = geospm.Grid();
            crs = hdng.SpatialCRS.empty;
            
            if ~isempty(arguments.grid_data)
                grid = arguments.grid_data.grid;
                crs = arguments.grid_data.crs;
            end
            
            spm_output_directory = arguments.spm_output_directory;
            
            spmmat = { fullfile(spm_output_directory, 'SPM.mat') };
            session = geospm.spm.SPMSession(spmmat{1});
            
            contrast_map_statistics = session.contrast_map_statistics;
            
            thresholds = arguments.thresholds;
            
            spm_output_files = hdng.utilities.list_files(spm_output_directory);
            spm_contrast_offset = 0;
            
            threshold_directories = cell(numel(thresholds), 1);
            
            for i=1:numel(thresholds)
                
                testing_threshold = thresholds{i};
                
                directory_name = obj.directory_name_for_threshold(i, testing_threshold);
                results_directory = fullfile(arguments.directory, directory_name);
                
                hdng.utilities.rmdir(results_directory, true, false);
                
                [dirstatus, dirmsg] = mkdir(results_directory);
                if dirstatus ~= 1; error(dirmsg); end
                
                threshold_directories{i} = results_directory;
                
                threshold_file = ...
                    fullfile(results_directory, 'threshold.txt');

                hdng.utilities.save_text(...
                    [testing_threshold.description newline], ...
                    threshold_file);
                
                contrasts = arguments.threshold_contrasts{i};

                if strcmp(testing_threshold.distribution, 'beta_coeff')
                    spm_contrast_offset = spm_contrast_offset + numel(contrasts);
                    obj.threshold_betas(session, testing_threshold, results_directory);
                    continue;
                end

                if strcmp(testing_threshold.distribution, 't_map')
                    obj.threshold_t_map(session, testing_threshold, cell2mat(contrasts) - spm_contrast_offset, results_directory);
                    continue;
                end
                
                threshold_value = testing_threshold.tail_level;
                
                spm_job_list = {};
                
                for c=1:numel(contrasts)
                    
                    if ~strcmp(testing_threshold.distribution, contrast_map_statistics{contrasts{c}})
                        error('SPMApplyThresholds.run(): Testing threshold distribution doesn''t match contrast statistic.');
                    end
                    
                    results_job = struct();
                    results_job.job_identifier = 'results';
                    results_job.spmmat = spmmat;
                    results_job.contrasts = contrasts{c};
                    results_job.threshold = threshold_value;
                    results_job.threshold_type = testing_threshold.correction;
                    results_job.binary_basename = 'mask';
                    
                    spm_job_list{end + 1} = results_job; %#ok<AGROW>
                end
                
                computation = geospm.spm.SPMJobList(...
                             spm_output_directory, ...
                             arguments.volume_precision, ...
                             spm_job_list);
                
                computation.run();
                
                threshold_output_files = hdng.utilities.list_files(spm_output_directory, 'exclude', spm_output_files);
                
                for j=1:numel(threshold_output_files)
                    file_path = threshold_output_files{j};
                    movefile(file_path, results_directory);
                end
                
                for c=1:numel(contrasts)
                    p_values_table = computation.batch_results{c}.TabDatvar;
                    obj.write_p_values_table(p_values_table, ...
                        contrasts{c}, grid, crs, results_directory);
                end
                
                match_result = session.match_statistic_threshold_files(...
                    testing_threshold.distribution, results_directory);
                
                if ~match_result.did_match_all_files
                    error('SPMApplyThresholds.run(): Couldn''t match all expected output maps.');
                end
                
                obj.save_contrasts(session, match_result, contrasts, results_directory);
                
            end
            
            result = struct();
            result.threshold_directories = threshold_directories;
        end
        
        function threshold_betas(~, session, testing_threshold, results_directory)
            
            beta_files = session.regression_beta_files;

            for i=1:numel(beta_files)

                beta_file = beta_files{i};
                
                beta_volume = geospm.utilities.read_nifti(beta_file);

                test_result = testing_threshold.test(beta_volume, 'statistics', beta_volume(:));

                [~, beta_name, ~] = fileparts(beta_file);
                beta_name = [beta_name '_mask.nii']; %#ok<AGROW>

                test_result = cast(test_result, 'uint8');
                test_path = fullfile(results_directory, beta_name);

                geospm.utilities.write_nifti(test_result, test_path, spm_type('uint8'));
            end
        end
        
        function threshold_t_map(~, session, testing_threshold, contrasts, results_directory)
            
            statistic_files = session.contrast_map_files(contrasts);
            
            for i=1:numel(statistic_files)

                statistic_file = statistic_files{i};
                
                statistic_volume = geospm.utilities.read_nifti(statistic_file);

                test_result = testing_threshold.test(statistic_volume, 'statistics', statistic_volume(:));

                [~, file_name, file_ext] = fileparts(statistic_file);
                file_name = [file_name, file_ext]; %#ok<AGROW>
                
                [start, tokens] = regexp(file_name, '^spmT_([0-9]+)\.nii$', 'start', 'tokens');

                if isempty(start)
                    continue
                end
                
                %file_index = str2double(tokens{1});
                
                statistic_name = ['t_map_' tokens{1}{1} '_mask.nii'];
                
                test_result = cast(test_result, 'uint8');
                test_path = fullfile(results_directory, statistic_name);

                geospm.utilities.write_nifti(test_result, test_path, spm_type('uint8'));
            end
        end
        
        function save_contrasts(obj, session, match_result, contrasts, results_directory)
            
            contrast_table = '';

            for c=1:numel(contrasts)
                contrast = contrasts{c};
                file_name = session.variables.xCon(contrast).Vspm.fname;
                contrast_table = [contrast_table, file_name, ' ', ...
                    session.variables.xCon(contrast).name, newline]; %#ok<AGROW>
            end

            contrasts = cell2mat(contrasts);
            contrast_pairs = obj.match_contrast_pairs(session, contrasts);
            contrast_map = zeros(session.N_contrasts, 1);
            contrast_map(contrasts) = 1:numel(contrasts);

            if size(contrast_pairs, 1) == 0
                contrast_table = ['Contrasts', newline, ...
                                   contrast_table];
            else
                contrast_table = ['Component Contrasts', newline, ...
                      contrast_table, 'Paired Contrasts', newline];
            end

            for p=1:size(contrast_pairs, 1)
                contrast1 = contrast_pairs(p, 1);
                contrast2 = contrast_pairs(p, 2);
                pair_name = sprintf('spmT_%04d_%04d_mask.nii', contrast1, contrast2);

                path1 = match_result.matched_files{contrast_map(contrast1)};
                path2 = match_result.matched_files{contrast_map(contrast2)};
                path3 = fullfile(results_directory, pair_name);

                obj.merge_mask_files(path1, path2, path3);

                pair_name = sprintf('spmT_%04d_%04d.nii', contrast1, contrast2);

                contrast_table = [contrast_table pair_name, ' ', ...
                    session.variables.xCon(contrast1).name, newline]; %#ok<AGROW>
            end

            hdng.utilities.save_text(...
                contrast_table, ...
                fullfile(results_directory, 'contrasts.txt'));
        end
        
        function merge_mask_files(~, path1, path2, path3)
            
            V2 = spm_vol(path1);
            data1 = spm_read_vols(V2);
                
            V2 = spm_vol(path2);
            data2 = spm_read_vols(V2);
            
            data = cast(data1 + data2, 'uint8');
            geospm.utilities.write_nifti(data, path3, spm_type('uint8'));
        end
        
        function pairs = match_contrast_pairs(~, session, selection)
            
            statistics = session.contrast_map_statistics;
            statistics = cellfun(@(x) strcmp(x, 'T'), statistics, 'UniformOutput', 1);
            
            selector = zeros(numel(statistics), 1, 'logical');
            selector(selection) = statistics(selection);
            
            definitions = session.contrast_definitions(selector);
            indices = 1:numel(session.contrast_definitions);
            indices = indices(selector);

            pairs = [];

            for index1=1:numel(definitions)
                definition1 = definitions{index1};

                for index2=index1 + 1:numel(definitions)
                    definition2 = definitions{index2};

                    if isequal(definition1, -definition2)
                        pairs = [pairs; [indices(index1), indices(index2)]]; %#ok<AGROW>
                        %fprintf('Matched contrasts %d and %d.\n', indices(index1), indices(index2));
                    end
                end
            end
            
        end
        
        function result = extra_values_from_contrast_p_values(obj, contrast_p_values)     %#ok<INUSD>
            result = struct();
        end
        
        function write_contrast_p_values(obj, directory, statistic, contrast_index, row_values, row_xyz, extra_values, crs)
            
            N_sets = sum(~isnan(row_values(:, obj.SET_C)));
            N_peaks = size(row_xyz, 1);
            N_clusters = sum(~isnan(row_values(:, obj.CLUSTER_EQUIV_K)));
            
            set_header = {'set', 'p', 'c'};
            sets = [set_header; cell(N_sets, 3)];
            
            cluster_header = {'set', 'cluster', 'equivK', 'p(unc)', 'p(FWE-corr)', 'p(FDR-corr)'};
            clusters = [cluster_header; cell(N_clusters, 6)];
            
            peaks_header = {'set', 'cluster', 'peak', statistic, 'equivZ', 'p(unc)', 'p(FWE-corr)', 'p(FDR-corr)', 'location', 'z-slice'};
            peaks = [peaks_header; cell(N_peaks, 10)];
            
            set_index = 1;
            cluster_index = 1;
            cluster_number = 0;
            peak_number = 0;
            
            set_p = NaN;
            set_c = NaN;
            
            cluster_p_fwe = NaN;
            cluster_p_fdr = NaN;
            cluster_equiv_k = NaN;
            cluster_p_uncorr = NaN;
            
            unique_peak_slices = containers.Map('KeyType', 'int64', 'ValueType', 'logical');
            
            for i=1:N_peaks
                
                peak_index = i + 1;
                
                if ~isnan(row_values(i, obj.SET_P))
                    set_p = row_values(i, obj.SET_P);
                end
                
                if ~isnan(row_values(i, obj.SET_C))
                    set_index = set_index + 1;
                    cluster_number = 0;
                    
                    set_c = row_values(i, obj.SET_C);
                    
                    sets{set_index, 1} = set_index - 1;
                    sets{set_index, 2} = sprintf('%-0.4f', set_p);
                    sets{set_index, 3} = sprintf('%g', set_c);
                end
                
                if ~isnan(row_values(i, obj.CLUSTER_UNCORRECTED_P))
                    cluster_p_uncorr = row_values(i, obj.CLUSTER_UNCORRECTED_P);
                end
                
                if ~isnan(row_values(i, obj.CLUSTER_FWE_CORRECTED_P))
                    cluster_p_fwe = row_values(i, obj.CLUSTER_FWE_CORRECTED_P);
                end
                
                if ~isnan(row_values(i, obj.CLUSTER_FDR_CORRECTED_P))
                    cluster_p_fdr = row_values(i, obj.CLUSTER_FDR_CORRECTED_P);
                end
                
                if ~isnan(row_values(i, obj.CLUSTER_EQUIV_K))
                    cluster_index = cluster_index + 1;
                    cluster_number = cluster_number + 1;
                    peak_number = 0;
                    
                    cluster_equiv_k = row_values(i, obj.CLUSTER_EQUIV_K);
                    
                    clusters{cluster_index, 1} = set_index - 1;
                    clusters{cluster_index, 2} = cluster_number;
                    clusters{cluster_index, 3} = sprintf('%0.0f', cluster_equiv_k);
                    clusters{cluster_index, 4} = sprintf('%0.4f', cluster_p_uncorr);
                    clusters{cluster_index, 5} = sprintf('%0.4f', cluster_p_fwe);
                    clusters{cluster_index, 6} = sprintf('%0.4f', cluster_p_fdr);
                end
                
                peak_number = peak_number + 1;
                
                peaks{peak_index, 1} = set_index - 1;
                peaks{peak_index, 2} = cluster_number;
                peaks{peak_index, 3} = peak_number;
                peaks{peak_index, 4} = sprintf('%6.2f', row_values(i, obj.PEAK_STATISTIC));
                peaks{peak_index, 5} = sprintf('%5.2f', row_values(i, obj.PEAK_EQUIV_Z));
                peaks{peak_index, 6} = sprintf('%0.4f', row_values(i, obj.PEAK_UNCORRECTED_P));
                peaks{peak_index, 7} = sprintf('%0.4f', row_values(i, obj.PEAK_FWE_CORRECTED_P));
                peaks{peak_index, 8} = sprintf('%0.4f', row_values(i, obj.PEAK_FDR_CORRECTED_P));
                peaks{peak_index, 9} = sprintf('POINT(%f %f)', row_xyz(i, 1), row_xyz(i, 2));
                peaks{peak_index, 10} = row_xyz(i, 3);
                
                unique_peak_slices(row_xyz(i, 3)) = true;
            end
            
            clusters_name = ['spm' statistic '_cluster_p_values_' num2str(contrast_index, '%04d') '.csv'];
            sets_name = ['spm' statistic '_set_p_values_' num2str(contrast_index, '%04d') '.csv'];
            peaks_name = ['spm' statistic '_peak_p_values_' num2str(contrast_index, '%04d') '.csv'];
                
            clusters_path = fullfile(directory, clusters_name);
            sets_path = fullfile(directory, sets_name);
            peaks_path = fullfile(directory, peaks_name);
            
            writecell(clusters, clusters_path);
            writecell(sets, sets_path);
            
            %{
            [~, peak_order] = sort(cell2mat(peaks(2:end,[10, 3, 2, 1])), 1);
            
            sorted_peaks = peaks([1; peak_order], :);
            %}
            
            sorted_peaks = peaks;
            writecell(sorted_peaks, peaks_path);
            
            peak_slices = unique_peak_slices.keys();
            
            for i=1:numel(peak_slices)
                z = peak_slices{i};
                
                peaks_name = ['spm' statistic '_peak_p_values_' num2str(contrast_index, '%04d') '_z' num2str(z, '%04d') '.csv'];
                peaks_path = fullfile(directory, peaks_name);
                
                selection = [1; find(row_xyz(:, 3) == z) + 1];
                
                writecell(peaks(selection, :), peaks_path);
            end
        end
        
        
        function write_p_values_table(obj, p_values_table, fixed_contrast_index, grid, crs, directory)
            
            tables_by_statistic = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            for contrast_index=1:numel(p_values_table)
                
                contrast_p_values = p_values_table(contrast_index);
                
                if ~obj.check_p_values_header(contrast_p_values)
                    continue;
                end
                
                statistic = contrast_p_values.hdr{2, obj.PEAK_STATISTIC};
                
                if ~isKey(tables_by_statistic, statistic)
                    tables_by_statistic(statistic) = {};
                end
                
                indices = tables_by_statistic(statistic);
                tables_by_statistic(statistic) = [indices, {contrast_index}];
                
                if isempty(contrast_p_values.dat)
                    % Do not skip insignificant contrasts
                    % continue;
                end
                
                if size(contrast_p_values.dat, 2) < obj.PEAK_LOCATION - 1
                    warning('SPMApplyThresholds.write_contrast_p_values(): Table is too small.');
                    continue;
                end
                
                row_cells = contrast_p_values.dat(:, 1:obj.PEAK_LOCATION - 1);
                row_values = zeros(size(row_cells));
                
                %Can't use cell2mat because empty cells crash cell2mat
                
                for p=1:size(row_cells, 1)
                    for q=1:size(row_cells, 2)
                        tmp = row_cells{p, q};
                        
                        if isempty(tmp)
                            tmp = NaN;
                        end
                        
                        row_values(p, q) = tmp;
                    end
                end
                
                row_xyz = zeros(size(contrast_p_values.dat, 1), 3);
                
                for j=1:size(contrast_p_values.dat, 1)
                    xyz = contrast_p_values.dat{j, obj.PEAK_LOCATION};
                    row_xyz(j, :) = xyz;
                end
                
                if ~isempty(grid)
                    [row_xyz(:, 1), row_xyz(:, 2), ~] = grid.grid_to_space(row_xyz(:,1), row_xyz(:,2), row_xyz(:,3));
                end
                
                extra_values = obj.extra_values_from_contrast_p_values(contrast_p_values);
                
                index = contrast_index;
                
                if fixed_contrast_index
                    index = fixed_contrast_index;
                end
                
                obj.write_contrast_p_values(directory, statistic, index, row_values, row_xyz, extra_values, crs);
                
                if fixed_contrast_index
                    break;
                end
            end
            
            statistics = keys(tables_by_statistic);
            
            if numel(p_values_table)
                p_values_table(1).contrast_index = [];
            end
            
            for i=1:numel(statistics)
                statistic = statistics{i};
                indices = cell2mat(tables_by_statistic(statistic));
                p_values = p_values_table(indices);
                
                for j=1:numel(indices)
                    p_values(j).contrast_index = indices(j);
                end
                
                file_path = fullfile(directory, ['spm' statistic '_p_values.mat']);
                save(file_path, 'p_values');
            end
        end
        
        function report_p_values_check_failure(~, expected)
            error(['SPMApplyThresholds.check_p_values_header(): Internal consistency check failed. Expected text ''' expected ''' in header cell.']);
        end
        
        function result = check_p_values_header(obj, p_values_record)
            
            expected = 'set';
            
            if ~strcmpi(p_values_record.hdr{1, obj.SET_P}, expected)
                obj.report_p_values_check_failure(expected);
            end

            if ~strcmpi(p_values_record.hdr{1, obj.SET_C}, expected)
                obj.report_p_values_check_failure(expected);
            end
            
            expected = 'p';
            
            if ~strcmpi(p_values_record.hdr{2, obj.SET_P}, expected)
                obj.report_p_values_check_failure(expected);
            end
            
            expected = 'c';
            
            if ~strcmpi(p_values_record.hdr{2, obj.SET_C}, expected)
                obj.report_p_values_check_failure(expected);
            end

            
            expected = 'cluster';
            
            if ~strcmpi(p_values_record.hdr{1, obj.CLUSTER_EQUIV_K}, expected)
                obj.report_p_values_check_failure(expected);
            end

            if ~strcmpi(p_values_record.hdr{1, obj.CLUSTER_UNCORRECTED_P}, expected)
                obj.report_p_values_check_failure(expected);
            end
            
            if ~strcmpi(p_values_record.hdr{1, obj.CLUSTER_FWE_CORRECTED_P}, expected)
                obj.report_p_values_check_failure(expected);
            end

            if ~strcmpi(p_values_record.hdr{1, obj.CLUSTER_FDR_CORRECTED_P}, expected)
                obj.report_p_values_check_failure(expected);
            end
            
            expected = 'equivk';
            
            if ~strcmpi(p_values_record.hdr{2, obj.CLUSTER_EQUIV_K}, expected)
                obj.report_p_values_check_failure(expected);
            end

            expected = 'p(unc)';
            
            if ~strcmpi(p_values_record.hdr{2, obj.CLUSTER_UNCORRECTED_P}, expected)
                obj.report_p_values_check_failure(expected);
            end
            
            expected = 'p(FWE-corr)';
            
            if ~strcmpi(p_values_record.hdr{2, obj.CLUSTER_FWE_CORRECTED_P}, expected)
                obj.report_p_values_check_failure(expected);
            end
            
            expected = 'p(FDR-corr)';

            if ~strcmpi(p_values_record.hdr{2, obj.CLUSTER_FDR_CORRECTED_P}, expected)
                obj.report_p_values_check_failure(expected);
            end
            
            expected = 'peak';
            
            if ~strcmpi(p_values_record.hdr{1, obj.PEAK_STATISTIC}, expected)
                obj.report_p_values_check_failure(expected);
            end

            if ~strcmpi(p_values_record.hdr{1, obj.PEAK_UNCORRECTED_P}, expected)
                obj.report_p_values_check_failure(expected);
            end
            
            if ~strcmpi(p_values_record.hdr{1, obj.PEAK_FWE_CORRECTED_P}, expected)
                obj.report_p_values_check_failure(expected);
            end

            if ~strcmpi(p_values_record.hdr{1, obj.PEAK_FDR_CORRECTED_P}, expected)
                obj.report_p_values_check_failure(expected);
            end

            expected = '';
            
            if ~strcmpi(p_values_record.hdr{1, obj.PEAK_LOCATION}, expected)
                obj.report_p_values_check_failure(expected);
            end

            expected = 'x,y,z {mm}';
            
            if ~strcmpi(p_values_record.hdr{2, obj.PEAK_LOCATION}, expected)
                obj.report_p_values_check_failure(expected);
            end
            
            expected = 'p(unc)';
            
            if ~strcmpi(p_values_record.hdr{2, obj.PEAK_UNCORRECTED_P}, expected)
                obj.report_p_values_check_failure(expected);
            end

            expected = 'p(FWE-corr)';
            
            if ~strcmpi(p_values_record.hdr{2, obj.PEAK_FWE_CORRECTED_P}, expected)
                obj.report_p_values_check_failure(expected);
            end

            expected = 'p(FDR-corr)';
            
            if ~strcmpi(p_values_record.hdr{2, obj.PEAK_FDR_CORRECTED_P}, expected)
                obj.report_p_values_check_failure(expected);
            end
            
            result = true;
        end
    end
end
