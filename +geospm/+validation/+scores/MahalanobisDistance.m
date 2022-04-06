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

classdef MahalanobisDistance < geospm.validation.scores.TermScore
    %MahalanobisDistance 
    %   
    
    properties
        quantile_p_values
    end
    
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = MahalanobisDistance()
            obj = obj@geospm.validation.scores.TermScore();
            
            attribute = obj.result_attributes.define('mahalanobis', true, true);
            attribute.description = 'Mahalanobis Distance';
            
            obj.quantile_p_values = [0.5, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0];
        end
        
        
        function prepare_results(obj, evaluation, mode) %#ok<INUSD>
            
            quantile_records = hdng.experiments.RecordArray();
            
            attribute = quantile_records.define_attribute('threshold', true, true);
            attribute.description = 'Threshold';
            
            attribute = quantile_records.define_attribute('term', true, true);
            attribute.description = 'Term';
            
            attribute = quantile_records.define_attribute('p', true, true);
            attribute.description = 'Quantile Probability';
            
            attribute = quantile_records.define_attribute('quantile_distance', true, true);
            attribute.description = 'Quantile Distance Per Slice';
            
            attribute = quantile_records.define_attribute('mean_distance', true, true);
            attribute.description = 'Mean Distance Per Slice';
            
            attribute = quantile_records.define_attribute('score_for_quantile_distance', true, true);
            attribute.description = 'Score for Quantile Distance Per Slice';
            
            attribute = quantile_records.define_attribute('score_for_mean_distance', true, true);
            attribute.description = 'Score for Mean Distance Per Slice';
            
            
            quantile_records.define_partitioning_attachment({
                struct('identifier', 'threshold', 'category', 'partitioning', 'view_mode', 'select'), ...
                struct('identifier', 'p', 'category', 'partitioning', 'view_mode', 'select'), ...
                struct('identifier', 'term', 'category', 'partitioning'), ...
                struct('identifier', 'quantile_distance', 'category', 'content'), ...
                struct('identifier', 'mean_distance', 'category', 'content'), ...
                struct('identifier', 'score_for_quantile_distance', 'category', 'content'), ...
                struct('identifier', 'score_for_mean_distance', 'category', 'content')});
            
            
            obj.results.quantile_records = quantile_records;
        end
        
        function finalise_results(obj, evaluation, mode) %#ok<INUSD>
            results = evaluation.results;
            results('mahalanobis') = hdng.experiments.Value.from(obj.results.quantile_records); %#ok<NASGU>
        end
        
        function mark_scores_not_applicable(obj, evaluation, mode, term_record) %#ok<INUSD>
        end
        
        function prepare_term(obj, evaluation, mode, term_record)
            prepare_term@geospm.validation.scores.TermScore(obj, evaluation, mode, term_record);
            obj.term.per_slice_results = cell(obj.term.result_slices, 1);
            obj.term.max_distance = sqrt(sum(obj.term.target_dimensions .* obj.term.target_dimensions));
        end
        
        function finalise_term(obj, evaluation, mode, term_record) %#ok<INUSL>
            
            quantile_distances_with_zeros = zeros(obj.term.result_slices, numel(obj.quantile_p_values));
            mean_distances_with_zeros = zeros(obj.term.result_slices, 1);
            
            scores_for_quantile_distances_with_zeros = zeros(obj.term.result_slices, numel(obj.quantile_p_values));
            scores_for_mean_distances_with_zeros = zeros(obj.term.result_slices, 1);
            
            for index=1:obj.term.result_slices
                
                result = obj.term.per_slice_results{index};
                
                quantile_distances_with_zeros(index, :) = result.quantile_distances_with_zeros;
                mean_distances_with_zeros(index) = result.mean_distance_with_zeros;
                
                scores_for_quantile_distances_with_zeros(index, :) = result.scores_for_quantile_distances_with_zeros;
                scores_for_mean_distances_with_zeros(index) = result.scores_for_mean_distance_with_zeros;
            end
            
            for index=1:numel(obj.quantile_p_values)

                quantile_record = hdng.utilities.Dictionary();

                quantile_record('threshold') = term_record('threshold');
                quantile_record('term') = term_record('term');
                quantile_record('p') = hdng.experiments.Value.from(obj.quantile_p_values(index));
                quantile_record('quantile_distance') = hdng.experiments.Value.from(quantile_distances_with_zeros(:, index));
                quantile_record('mean_distance') = hdng.experiments.Value.from(mean_distances_with_zeros);
                quantile_record('score_for_quantile_distance') = hdng.experiments.Value.from(scores_for_quantile_distances_with_zeros(:, index));
                quantile_record('score_for_mean_distance') = hdng.experiments.Value.from(scores_for_mean_distances_with_zeros);
                
                obj.results.quantile_records.include_record(quantile_record);
            end
        end
        
        function compute_scores_for_slice(obj, term_record, target_z, target_slice, result_z, result_slice) %#ok<INUSL>
            
            result = struct();
            
            target_points = obj.points_from_mask(target_slice);
            result_points = obj.points_from_mask(result_slice);
            
            if size(target_points, 1) > 1 && size(result_points, 1) > 0
            
                result.quantile_distances_with_zeros = geospm.validation.scores.MahalanobisDistance.distance_quantiles(target_points, result_points, obj.quantile_p_values);
                result.mean_distance_with_zeros = geospm.validation.scores.MahalanobisDistance.mean_distance(target_points, result_points);

                result.scores_for_quantile_distances_with_zeros = (obj.term.max_distance - result.quantile_distances_with_zeros) ./ obj.term.max_distance;
                result.scores_for_mean_distance_with_zeros = (obj.term.max_distance - result.mean_distance_with_zeros) ./ obj.term.max_distance;
            
            else
                
                result.quantile_distances_with_zeros = nan(numel(obj.quantile_p_values), 1);
                result.mean_distance_with_zeros = NaN;
                
                result.scores_for_quantile_distances_with_zeros = nan(numel(obj.quantile_p_values), 1);
                result.scores_for_mean_distance_with_zeros = NaN;
            end
            
            obj.term.per_slice_results{result_z} = result;
        end
        
        function [result, dimensions] = load(obj, reference, base_path)
            
            [result, dimensions] = load@geospm.validation.scores.TermScore(obj, reference, base_path);
            
            result = result > 0.0;
        end
    end
    
    methods (Static)
        
        function d = distances(target_points, result_points)
            
            d = mahal(result_points, target_points);
        end
        
        function d = ranked_distances(target_points, result_points)
            
            D = mahal(result_points, target_points);
            d = sort(D);
        end
        
        function d = distance_quantiles(target_points, result_points, p)
            
            D = geospm.validation.scores.MahalanobisDistance.distances(target_points, result_points);
            
            d = quantile(D, p); % d might contain elements not in K/D because of linear interpolation
            
            d = d(:);
        end
        
        function d = mean_distance(target_points, result_points)
            
            D = geospm.validation.scores.MahalanobisDistance.distances(target_points, result_points);
            
            d = mean(D);
        end
        
        function result = points_from_mask(mask)
            
            indices = find(mask(:));
            [X, Y] = ind2sub(size(mask), indices);
            
            result = [X, Y];
        end
        
    end
end
