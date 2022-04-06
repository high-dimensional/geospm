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

classdef ImageScore < hdng.experiments.Score
    %ImageScore Computes the intersection over union.
    %   Takes the variable names of an experiment's data.
    
    properties
        score_descriptions
        score_identifiers
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = ImageScore()
            obj = obj@hdng.experiments.Score();
            
            obj.score_identifiers = {['score.' obj.compute_identifier()]};
            obj.score_descriptions = {''};
        end
        
        function compute(obj, evaluation, mode)
        	
            if ~obj.should_compute(mode, evaluation.results)
                return
            end
            
            results = evaluation.results;
            
            if ~results.holds_key('terms')
                warning('%s.compute(): Score is not applicable, missing ''terms'' key in results dictionary.', class(obj));
                return
            end
            
            scoring_records = results('terms').content;
            records = scoring_records.unsorted_records;
            
            new_scoring_records = hdng.experiments.RecordArray();
            new_scoring_records.attachments = scoring_records.attachments;
            
            for index=1:numel(scoring_records.attributes)
                attribute = scoring_records.attributes{index};
                
                new_attribute = new_scoring_records.define_attribute(attribute.identifier, true, attribute.is_persistent);
                new_attribute.description = attribute.description;
                new_attribute.attachments = attribute.attachments;
            end
            
            for index=1:numel(obj.score_identifiers)
                score_identifier = obj.score_identifiers{index};
                
                new_attribute = new_scoring_records.define_attribute(score_identifier, true, true);
                new_attribute.description = obj.score_descriptions{index};
                
                new_attribute = new_scoring_records.define_attribute([score_identifier '.min'], true, true);
                new_attribute.description = [obj.score_descriptions{index} ' Minimum'];
                
                new_attribute = new_scoring_records.define_attribute([score_identifier '.max'], true, true);
                new_attribute.description = [obj.score_descriptions{index} ' Maximum'];
            end
            
            record_scores = [];
            
            for i=1:numel(records)
                
                record = records{i};
                
                result = record('result');
                
                if strcmp(result.type_identifier, 'builtin.null')
                    
                    record(score_identifier) = hdng.experiments.Value.empty_with_label('score not applicable');
                    new_scoring_records.include_record(record);
                    continue
                end
                
                result = result.content;
                [result_volume, result_size] = obj.load(result, evaluation.canonical_base_path);
                
                result_slices = result_size(3);
                result_dimensions = result_size(1:2);
                
                target = record('target');
                
                if strcmp(target.type_identifier, 'builtin.null')
                    
                    scores = zeros(1, result_slices);
                    record_scores = [record_scores; scores]; %#ok<AGROW>
                    
                    record(score_identifier) = hdng.experiments.Value.empty_with_label('score not applicable');
                    new_scoring_records.include_record(record);
                    continue
                end
                
                target = target.content;
                [target_volume, target_size] = obj.load(target, evaluation.canonical_base_path);
                
                target_dimensions = target_size(1:2);
                
                if ~isequal(result_dimensions, target_dimensions)
                    error('ImageScore.compute() the image sizes for the target volume and the result volume don''t match.');
                end
                
                record = obj.compute_scores_for_volume(record, target_volume, target_dimensions, result_volume, result_dimensions);
                
                new_scoring_records.include_record(record);
                
                %figure;
                %plot(1:numel(scores), scores);
                %title(['Noise Level ' evaluation.configuration.values('noise_level').label]);
            end
            
            partitioning = new_scoring_records.get_partitioning_attachment();
            
            if ~isempty(partitioning)
                
                for index=1:numel(obj.score_identifiers)
                    partitioning.define_attribute(obj.score_identifiers{index}, hdng.experiments.RecordArrayPartitioning.CATEGORY_CONTENT);
                end
            end
            
            results('terms') = hdng.experiments.Value.from(new_scoring_records); %#ok<NASGU>
        end
        
        function record = compute_scores_for_volume(obj, record, target_volume, target_dimensions, result_volume, result_dimensions) %#ok<INUSL>
            
            result_slices = size(result_volume, 3);
            target_slices = size(target_volume, 3);
            
            S = numel(obj.score_identifiers);
            
            all_scores = zeros(result_slices, S);
            
            if result_slices ~= target_slices

                if target_slices ~= 1
                    error('ImageScore.compute() can''t match the target volume to the result volume.');
                end

                target_slice = reshape(target_volume, result_dimensions(1), result_dimensions(2));

                for index=1:result_slices

                    result_slice = reshape(result_volume(:, :, index), result_dimensions(1), result_dimensions(2));

                    all_scores(index, :) = obj.compute_scores_for_slice(1, target_slice, index, result_slice);
                end
            else

                for index=1:result_slices

                    target_slice = reshape(target_volume(:, :, index), result_dimensions(1), result_dimensions(2));
                    result_slice = reshape(result_volume(:, :, index), result_dimensions(1), result_dimensions(2));

                    all_scores(index, :) = obj.compute_scores_for_slice(index, target_slice, index, result_slice);
                end
            end
            
            for index=1:S
                score_identifier = obj.score_identifiers{index};
                scores = all_scores(:, index);
                record(score_identifier) = hdng.experiments.Value.from(scores);
                
                max_score_identifier = [score_identifier '.max'];
                record(max_score_identifier) = hdng.experiments.Value.from(max(scores(:)));
                
                min_score_identifier = [score_identifier '.min'];
                record(min_score_identifier) = hdng.experiments.Value.from(min(scores(:)));
            end
        end
        
        function result = compute_scores_for_slice(~, target_z, target_slice, result_z, result_slice) %#ok<STOUT,INUSD>
            error('ImageScore.compute_scores_for_slice() must be implemented by a sub-class.');
        end
        
        function [result, dimensions] = load(~, reference, base_path)
            
            switch class(reference)
                
                case 'hdng.experiments.VolumeReference'
                    result = reference.scalars.load(base_path);
            
                case 'hdng.experiments.ImageReference'
                    result = reference.load(base_path);
                
                case 'hdng.experiments.SliceReference'
                    result = reference.load(base_path);
                
                otherwise
                    error('JaccardIndex.load() couldn''t load reference of type ''%s''', class(reference));
            end
            
            dimensions = size(result);
            
            if numel(dimensions) == 1
                dimensions = [dimensions 1 1];
            elseif numel(dimensions) == 2
                %result = reshape(result, dimensions(1), dimensions(2), 1);
                dimensions = [dimensions 1];
            end
        end
    end
    
    
    methods (Access=protected)
        
        function result = compute_identifier(~)
            result = 'image_score';
        end
    end
end
