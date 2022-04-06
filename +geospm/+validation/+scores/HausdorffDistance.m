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

classdef HausdorffDistance < geospm.validation.scores.TermScore
    %HausdorffDistance 
    %   
    
    properties
        quantile_p_values
    end
    
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = HausdorffDistance()
            obj = obj@geospm.validation.scores.TermScore();
            
            attribute = obj.result_attributes.define('hausdorff', true, true);
            attribute.description = 'Hausdorff Distance';
            
            obj.quantile_p_values = [0.5, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0];
        end
        
        
        function prepare_results(obj, evaluation, mode) %#ok<INUSD>
            
            quantile_records = hdng.experiments.RecordArray();
            
            attribute = quantile_records.define_attribute('threshold', true, true);
            attribute.description = 'Threshold';
            
            attribute = quantile_records.define_attribute('term', true, true);
            attribute.description = 'Term';
            
            attribute = quantile_records.define_attribute('includes_zeros', true, true);
            attribute.description = 'Include Zeros';
            
            attribute = quantile_records.define_attribute('p', true, true);
            attribute.description = 'Quantile Probability';
            
            attribute = quantile_records.define_attribute('quantile_distance', true, true);
            attribute.description = 'Quantile Distance Per Slice';
            
            attribute = quantile_records.define_attribute('mean_distance', true, true);
            attribute.description = 'Mean Distance Per Slice';
            
            attribute = quantile_records.define_attribute('modified_distance', true, true);
            attribute.description = 'Modified Distance Per Slice';
            
            attribute = quantile_records.define_attribute('score_for_quantile_distance', true, true);
            attribute.description = 'Score for Quantile Distance Per Slice';
            
            attribute = quantile_records.define_attribute('score_for_mean_distance', true, true);
            attribute.description = 'Score for Mean Distance Per Slice';
            
            attribute = quantile_records.define_attribute('score_for_modified_distance', true, true);
            attribute.description = 'Score for Modified Distance Per Slice';
            
            
            quantile_records.define_partitioning_attachment({
                struct('identifier', 'threshold', 'category', 'partitioning', 'view_mode', 'select'), ...
                struct('identifier', 'p', 'category', 'partitioning', 'view_mode', 'select'), ...
                struct('identifier', 'includes_zeros', 'category', 'partitioning', 'view_mode', 'select'), ...
                struct('identifier', 'term', 'category', 'partitioning'), ...
                ...
                struct('identifier', 'quantile_distance', 'category', 'content'), ...
                struct('identifier', 'mean_distance', 'category', 'content'), ...
                struct('identifier', 'modified_distance', 'category', 'content'), ...
                ...
                struct('identifier', 'score_for_quantile_distance', 'category', 'content'), ...
                struct('identifier', 'score_for_mean_distance', 'category', 'content'), ...
                struct('identifier', 'score_for_modified_distance', 'category', 'content') ...
            
            });
            
            
            obj.results.quantile_records = quantile_records;
        end
        
        function finalise_results(obj, evaluation, mode) %#ok<INUSD>
            results = evaluation.results;
            results('hausdorff') = hdng.experiments.Value.from(obj.results.quantile_records); %#ok<NASGU>
            
            % fprintf('Hausdorff Records:\n%s', obj.results.quantile_records.format());
        end
        
        function mark_scores_not_applicable(obj, evaluation, mode, term_record) %#ok<INUSD>
        end
        
        function prepare_term(obj, evaluation, mode, term_record)
            
            prepare_term@geospm.validation.scores.TermScore(obj, evaluation, mode, term_record);
            
            obj.term.per_slice_results = cell(obj.term.result_slices, 1);
            
            dims = obj.term.target_dimensions - 1;
            obj.term.max_distance = sqrt(sum(dims .* dims));
        end
        
        function finalise_term(obj, evaluation, mode, term_record) %#ok<INUSL>
            
            quantile_distances = zeros(obj.term.result_slices, numel(obj.quantile_p_values));
            mean_distances = zeros(obj.term.result_slices, 1);
            modified_distances = zeros(obj.term.result_slices, 1);
            
            score_for_quantile_distances = zeros(obj.term.result_slices, numel(obj.quantile_p_values));
            score_for_mean_distances = zeros(obj.term.result_slices, 1);
            score_for_modified_distances = zeros(obj.term.result_slices, 1);
            
            for index=1:obj.term.result_slices
                
                result = obj.term.per_slice_results{index};
                
                quantile_distances(index, :) = result.quantile_distances;
                mean_distances(index) = result.mean_distance;
                modified_distances(index) = result.modified_distance;
                
                score_for_quantile_distances(index, :) = result.score_for_quantile_distances;
                score_for_mean_distances(index) = result.score_for_mean_distance;
                score_for_modified_distances(index) = result.score_for_modified_distance;
            end
            
            for index=1:numel(obj.quantile_p_values)

                quantile_record = hdng.utilities.Dictionary();

                quantile_record('threshold') = term_record('threshold');
                quantile_record('term') = term_record('term');
                quantile_record('p') = hdng.experiments.Value.from(obj.quantile_p_values(index));
                quantile_record('includes_zeros') = hdng.experiments.Value.from(true, 'Including zero distance.');
                quantile_record('quantile_distance') = hdng.experiments.Value.from(quantile_distances(:, index));
                quantile_record('mean_distance') = hdng.experiments.Value.from(mean_distances);
                quantile_record('modified_distance') = hdng.experiments.Value.from(modified_distances);
                quantile_record('score_for_quantile_distance') = hdng.experiments.Value.from(score_for_quantile_distances(:, index));
                quantile_record('score_for_mean_distance') = hdng.experiments.Value.from(score_for_mean_distances);
                quantile_record('score_for_modified_distance') = hdng.experiments.Value.from(score_for_modified_distances);
                
                obj.results.quantile_records.include_record(quantile_record);
            end
        end
        
        function compute_scores_for_slice(obj, term_record, target_z, target_slice, result_z, result_slice) %#ok<INUSL>
            
            result = struct();
            
            result.quantile_distances = geospm.validation.scores.HausdorffDistance.distance_quantiles(target_slice, result_slice, obj.quantile_p_values);
            result.mean_distance = geospm.validation.scores.HausdorffDistance.mean_distance(target_slice, result_slice);
            result.modified_distance = geospm.validation.scores.HausdorffDistance.modified_distance(target_slice, result_slice);
            
            max_distances = repelem(obj.term.max_distance, numel(result.quantile_distances));
            clipped_quantile_distances = min(result.quantile_distances, max_distances);
            result.score_for_quantile_distances = (max_distances - clipped_quantile_distances) ./ max_distances;
            
            clipped_mean_distance = min(result.mean_distance, obj.term.max_distance);
            result.score_for_mean_distance = (obj.term.max_distance - clipped_mean_distance) ./ obj.term.max_distance;
            
            clipped_modified_distance = min(result.modified_distance, obj.term.max_distance);
            result.score_for_modified_distance = (obj.term.max_distance - clipped_modified_distance) ./ obj.term.max_distance;
            
            obj.term.per_slice_results{result_z} = result;
        end
        function [result, dimensions] = load(obj, reference, base_path)
            
            [result, dimensions] = load@geospm.validation.scores.TermScore(obj, reference, base_path);
            
            result = result > 0.0;
        end
    end
    
    methods (Static)
        
        function [d, A_index, B_index] = directed_distance(A, B, method)
            
            % Returns 
            %    d - the distance from A to B, is Inf if A or B contain no
            %             non-zero pixels.
            %
            %    A_index, B_index specify the indices in A and B
            %    of the pair with distance d. 0 if d is Inf.
            
            
            % 'euclidean' (default) | 'chessboard' | 'cityblock' | 'quasi-euclidean'
            
            if ~isequal(size(A), size(B))
                error('HausdorffDistance.directed_distance(): A and B must have equal dimensions.');
            end
            
            if ~exist('method', 'var')
                args = {};
            else
                args = {method};
            end
            
            [D, B_indices] = bwdist(B, args{:});
            
            % If B did not hold any non-zero pixels all distances are Inf
            
            A_indices = find(A);
            
            % If A did not hold any non-zero pixels A_indices is empty
            
            D = D(A_indices);
            B_indices = B_indices(A_indices);
            
            % The elements of D are the distances of each non-zero pixel
            % in A to the nearest non-zero pixel in B 
            % in acending order of their linear index in A.
            % The elements of B_indices are the corresponding linear indices
            % in B
            
            % Find the first maximum distance in D and its index.
            
            [d, d_index] = max(D);
            
            if isinf(d)
                A_index = 0;
                B_index = 0;
                
            elseif isempty(d)
                
                A_index = 0;
                B_index = 0;
                d = Inf;
                
            else
                A_index = A_indices(d_index);
                B_index = B_indices(d_index);
            end
            
            d = cast(d, 'double');
            A_index = cast(A_index, 'double');
            B_index = cast(B_index, 'double');
        end
        
        function [d, A_indices, B_indices] = directed_distances(A, B, method)
            
            % Returns 
            %    d - the distances from non-zero pixels in A to B. distances
            %        are Inf if B is zero, or d is empty if A is zero.
            %
            %    A_indices and B_indices specify the indices in A and B
            %    of each pair with a distance in d. 0 if d is Inf, or empty
            %    if A is zero.
            
            
            if ~isequal(size(A), size(B))
                error('HausdorffDistance.directed_distances(): A and B must have equal dimensions.');
            end
            
            if ~exist('method', 'var')
                args = {};
            else
                args = {method};
            end
            
            [D, B_indices] = bwdist(B, args{:});
            
            A_indices = find(A);
            
            d = D(A_indices);
            B_indices = B_indices(A_indices);
            
            
            d = cast(d, 'double');
            A_indices = cast(A_indices, 'double');
            B_indices = cast(B_indices, 'double');
        end
        
        
        function [d, A_index, B_index] = hausdorff_distance(A, B, method)
            
            if ~exist('method', 'var')
                args = {};
            else
                args = {method};
            end
            
            
            [d_a_to_b, index_a_a_to_b, index_b_a_to_b] = ...
                geospm.validation.scores.HausdorffDistance.directed_distance(A, B, args{:});
            [d_b_to_a, index_b_b_to_a, index_a_b_to_a] = ...
                geospm.validation.scores.HausdorffDistance.directed_distance(B, A, args{:});
            
            
            [d, index] = max([d_a_to_b, d_b_to_a]);
            
            A_indices = [index_a_a_to_b, index_a_b_to_a];
            B_indices = [index_b_a_to_b, index_b_b_to_a];
            
            A_index = A_indices(index);
            B_index = B_indices(index);
        end
        
        function d = modified_distance(A, B, method)
            
            if ~exist('method', 'var')
                args = {};
            else
                args = {method};
            end
            
            [D_a_b, ~, ~] = geospm.validation.scores.HausdorffDistance.directed_distances(A, B, args{:});
            [D_b_a, ~, ~] = geospm.validation.scores.HausdorffDistance.directed_distances(B, A, args{:});
            
            d = max(sum(D_a_b) / numel(D_a_b), sum(D_b_a) / numel(D_b_a));
            
            if isempty(d)
                d = Inf;
            end
        end
        
        function [d, A_indices, B_indices] = ranked_distances(A, B, method)
            
            if ~exist('method', 'var')
                args = {};
            else
                args = {method};
            end
            
            [D, A_indices, B_indices] = geospm.validation.scores.HausdorffDistance.directed_distances(A, B, args{:});
            
            [d, D_order] = sort(D);
            
            A_indices = A_indices(D_order);
            B_indices = B_indices(D_order);
        end
        
        function d = directed_distance_quantiles(A, B, p, method)
            
            if ~exist('method', 'var')
                args = {};
            else
                args = {method};
            end
            
            [D, ~, ~] = geospm.validation.scores.HausdorffDistance.directed_distances(A, B, args{:});
            
            if isempty(D)
                d = Inf(numel(p), 1);
            else
                d = quantile(D, p); % d might contain elements not in D because of linear interpolation
            end
        end
        
        function d = mean_directed_distance(A, B, method)
            
            if ~exist('method', 'var')
                args = {};
            else
                args = {method};
            end
            
            [D, ~, ~] = geospm.validation.scores.HausdorffDistance.directed_distances(A, B, args{:});
            
            d = mean(D);
            
            if isnan(d)
                d = Inf;
            end
        end
        
        function d = distance_quantiles(A, B, p, method)
            
            if ~exist('method', 'var')
                args = {};
            else
                args = {method};
            end
            
            [D_a_b, ~, ~] = geospm.validation.scores.HausdorffDistance.directed_distances(A, B, args{:});
            [D_b_a, ~, ~] = geospm.validation.scores.HausdorffDistance.directed_distances(B, A, args{:});
            
            D = [D_a_b; D_b_a];
            
            if isempty(D)
                d = Inf(1, numel(p));
            else
                d = quantile(D, p); % d might contain elements not in D because of linear interpolation
            end
        end
        
        function d = mean_distance(A, B, method)
            
            if ~exist('method', 'var')
                args = {};
            else
                args = {method};
            end
            
            d1 = geospm.validation.scores.HausdorffDistance.mean_directed_distance(A, B, args{:});
            d2 = geospm.validation.scores.HausdorffDistance.mean_directed_distance(B, A, args{:});
            
            d = max([d1, d2]);
        end
        
    end
end
