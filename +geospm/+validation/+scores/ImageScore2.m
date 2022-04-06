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

classdef ImageScore2 < geospm.validation.scores.TermScore
    %ImageScore2 
    %   
    
    properties
    end
    
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = ImageScore2()
            obj = obj@geospm.validation.scores.TermScore();
            
            %attribute = obj.result_attributes.define('terms', true, true);
            %attribute.description = 'Hausdorff';
            
        end
        
        
        function prepare_results(obj, evaluation, mode) %#ok<INUSD>
            
            quantile_records = hdng.experiments.RecordArray();
            
            attribute = quantile_records.define_attribute('threshold', true, true);
            attribute.description = 'Threshold';
            
            attribute = quantile_records.define_attribute('term', true, true);
            attribute.description = 'Term';
            
            attribute = quantile_records.define_attribute('p', true, true);
            attribute.description = 'Probability';
            
            attribute = quantile_records.define_attribute('q', true, true);
            attribute.description = 'Quantile';
            
            obj.results.quantile_records = quantile_records;
        end
        
        function finalise_results(obj, evaluation, mode) %#ok<INUSD>
            
            results = evaluation.results;
            results('hausdorff') = hdng.experiments.Value.from(obj.results.quantile_records); %#ok<NASGU>
        end
        
        
        
        function result = compute_scores_for_slice(~, term_record, target_z, target_slice, result_z, result_slice) %#ok<STOUT,INUSD>
        
            [d, A_indices, B_indices] = geospm.validation.scores.HausdorffDistance.distance_quantiles(target_slice, result_slice, obj.quantile);
            mean_d = geospm.validation.scores.HausdorffDistance.mean_distance(target_slice, result_slice);
        end
        
        %{
        
            'score.quantile_distance
        
        %}
    end
    
    methods (Static)
        
        function [d, A_index, B_index] = directed_distance(A, B, method)
            
            if ~exist('method', 'var')
                args = {};
            else
                args = {method};
            end
            
            [D, B_indices] = bwdist(B, args{:});
            
            A_indices = find(A);
            
            D = D(A_indices);
            B_indices = B_indices(A_indices);
            [d, d_index] = max(D);
            
            if isinf(d)
                A_index = 0;
                B_index = 0;
            else
                B_index = B_indices(d_index);
                A_index = A_indices(d_index);
            end
        end
        
        function [d, A_index, B_index] = hausdorff_distance(A, B, method)
            
            if ~exist('method', 'var')
                args = {};
            else
                args = {method};
            end
            
            [d1, A_index1, B_index1] = geospm.validation.scores.HausdorffDistance.directed_distance(A, B, args{:});
            [d2, A_index2, B_index2] = geospm.validation.scores.HausdorffDistance.directed_distance(B, A, args{:});
            
            A_indices = [A_index1, A_index2];
            B_indices = [B_index1, B_index2];
            
            [d, index] = max([d1, d2]);
            A_index = A_indices(index);
            B_index = B_indices(index);
        end
        
        function [d, A_indices, B_indices] = directed_distances(A, B, method)
            
            if ~exist('method', 'var')
                args = {};
            else
                args = {method};
            end
            
            [D, B_indices] = bwdist(B, args{:});
            
            A_indices = find(A);
            
            d = D(A_indices);
            B_indices = B_indices(A_indices);
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
            
            selector = isinf(d);
            
            A_indices(selector) = 0;
            B_indices(selector) = 0;
        end
        
        function [d, A_indices, B_indices] = directed_distance_quantiles(A, B, p, method)
            
            if ~exist('method', 'var')
                args = {};
            else
                args = {method};
            end
            
            [D, A_indices, B_indices] = geospm.validation.scores.HausdorffDistance.directed_distances(A, B, args{:});
            
            K = D(D ~= 0.0);
            
            d = quantile(K, p);
            selector = D == d;
            
            indices = zeros(numel(p), 1);
            
            for index=1:numel(p)
                indices(index) = find(selector(:, index), 1);
            end
            
            d = d(:);
            A_indices = A_indices(indices);
            B_indices = B_indices(indices);
        end
        
        function d = mean_directed_distance(A, B, method)
            
            if ~exist('method', 'var')
                args = {};
            else
                args = {method};
            end
            
            [D, ~, ~] = geospm.validation.scores.HausdorffDistance.directed_distances(A, B, args{:});
            
            K = D(D ~= 0.0);
            
            d = mean(K);
        end
        
        function [d, A_indices, B_indices] = distance_quantiles(A, B, p, method)
            
            if ~exist('method', 'var')
                args = {};
            else
                args = {method};
            end
            
            [D1, A_indices1, B_indices1] = geospm.validation.scores.HausdorffDistance.directed_distance_quantiles(A, B, p, args{:});
            [D2, A_indices2, B_indices2] = geospm.validation.scores.HausdorffDistance.directed_distance_quantiles(B, A, p, args{:});
            
            A_indices = [A_indices1, A_indices2];
            B_indices = [B_indices1, B_indices2];
            
            [d, indices] = max([D1, D2], [], 2);
         
            selector = zeros(1, 2, 'logical');
            selector(indices) = 1;
            
            A_indices = A_indices(:, selector);
            B_indices = B_indices(:, selector);
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
