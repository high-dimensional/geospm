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

classdef TermScore < hdng.experiments.Score
    %TermScore Computes one or more scalar-valued scores for each slice.
    
    properties
        score_descriptions
        score_identifiers
        
        results
        term
    end
    
    properties (Dependent, Transient)
    end
    
    methods
        
        function obj = TermScore()
            obj = obj@hdng.experiments.Score();
            
            obj.score_identifiers = {};
            obj.score_descriptions = {};
            
            obj.results = struct();
            obj.term = struct();
        end
        
        function result = copy_term_record_array(~, term_records)
            
            result = hdng.experiments.RecordArray();
            
            result.attachments = term_records.attachments;
            
            for index=1:numel(term_records.attributes)
                attribute = term_records.attributes{index};
                
                new_attribute = result.define_attribute(attribute.identifier, true, attribute.is_persistent);
                
                new_attribute.description = attribute.description;
                new_attribute.attachments = attribute.attachments;
            end
            
            partitioning = result.get_partitioning_attachment();
            
            if ~isempty(partitioning)
                
                for index=1:numel(obj.score_identifiers)
                    partitioning.define_attribute(obj.score_identifiers{index}, hdng.experiments.RecordArrayPartitioning.CATEGORY_CONTENT);
                end
            end
            
            obj.define_score_attributes(result);
        end
        
        function define_score_attributes(obj, record_array)
            
            for index=1:numel(obj.score_identifiers)
                
                score_identifier = obj.score_identifiers{index};
                
                new_attribute = record_array.define_attribute(score_identifier, true, true);
                new_attribute.description = obj.score_descriptions{index};
                
                new_attribute = record_array.define_attribute([score_identifier '.min'], true, true);
                new_attribute.description = [obj.score_descriptions{index} ' Minimum'];
                
                new_attribute = record_array.define_attribute([score_identifier '.max'], true, true);
                new_attribute.description = [obj.score_descriptions{index} ' Maximum'];
            end
        end
        
        function mark_scores_not_applicable(obj, evaluation, mode, term_record) %#ok<INUSL>
            
            for index=1:numel(obj.score_identifiers)
                score_identifier = obj.score_identifiers{index};
                term_record(score_identifier) = hdng.experiments.Value.empty_with_label('Not applicable.');
            end
            
            obj.results.term_records.include_record(term_record);
        end
        
        function prepare_results(obj, evaluation, mode) %#ok<INUSD>
            
            term_records = evaluation.results('terms').content;
            
            obj.results = struct();
            obj.results.term_records = obj.copy_term_record_array(term_records);
        end
        
        function finalise_results(obj, evaluation, mode) %#ok<INUSD>
            
            evaluation.results('terms') = hdng.experiments.Value.from(obj.results.term_records);
        end
        
        function compute(obj, evaluation, mode)
        	
            if ~obj.should_compute(mode, evaluation.results)
                return
            end
            
            if ~evaluation.results.holds_key('terms')
                warning('%s.compute(): Score is not applicable, missing ''terms'' key in results dictionary.', class(obj));
                return
            end
            
            obj.prepare_results(evaluation, mode);
            
            term_records = evaluation.results('terms').content;
            records = term_records.records;
            
            for i=1:numel(records)
                
                term_record = records{i};
                
                result = term_record('result');
                target = term_record('target');
                
                if strcmp(result.type_identifier, 'builtin.null') || ...
                   strcmp(target.type_identifier, 'builtin.null')
                    
                    obj.mark_scores_not_applicable(evaluation, mode, term_record);
                    continue
                end
                
                obj.compute_scores_for_term(evaluation, mode, term_record);
            end
            
            obj.finalise_results(evaluation, mode);
        end
        
        function prepare_term(obj, evaluation, mode, term_record) %#ok<INUSL>
            
            result = term_record('result');
            target = term_record('target');

            obj.term = struct();
            
            [obj.term.result_volume, ...
             obj.term.result_size] = ...
             obj.load(result.content, evaluation.canonical_base_path);
         
            obj.term.result_dimensions = ...
                obj.term.result_size(1:2);

            [obj.term.target_volume, ...
             obj.term.target_size] = ...
             obj.load(target.content, evaluation.canonical_base_path);
         
            obj.term.target_dimensions = ...
                obj.term.target_size(1:2);
            
            if ~isequal(obj.term.result_dimensions, ...
                        obj.term.target_dimensions)
                
                error('TermScore.prepare_term() the image sizes for the target volume and the result volume don''t match.');
            end
            
            obj.term.result_slices = ...
                size(obj.term.result_volume, 3);
            
            obj.term.target_slices = ...
                size(obj.term.target_volume, 3);
            
            N_scores = numel(obj.score_identifiers);
            
            obj.term.score_matrix = zeros(obj.term.result_slices, N_scores);
        end
        
        function finalise_term(obj, evaluation, mode, term_record) %#ok<INUSL>
            
            N_scores = numel(obj.score_identifiers);
            
            for index=1:N_scores
                
                score_identifier = obj.score_identifiers{index};
                scores = obj.term.score_matrix(:, index);
                term_record(score_identifier) = hdng.experiments.Value.from(scores);
                
                max_score_identifier = [score_identifier '.max'];
                term_record(max_score_identifier) = hdng.experiments.Value.from(max(scores(:)));
                
                min_score_identifier = [score_identifier '.min'];
                term_record(min_score_identifier) = hdng.experiments.Value.from(min(scores(:)));
            end
            
            obj.results.term_records.include_record(term_record);
        end
        
        function compute_scores_for_term(obj, evaluation, mode, term_record)
            
            obj.prepare_term(evaluation, mode, term_record);
            
            if obj.term.result_slices ~= obj.term.target_slices

                if obj.term.target_slices ~= 1
                    error('TermRecords.compute() can''t match the target volume to the result volume.');
                end
                
                target_slice = reshape(obj.term.target_volume, ...
                                       obj.term.result_dimensions(1:2));
                
                for slice_index=1:obj.term.result_slices
                    
                    result_slice = reshape(obj.term.result_volume(:, :, slice_index),  ...
                                           obj.term.result_dimensions(1:2));
                    
                    obj.compute_scores_for_slice(term_record, 1, target_slice, slice_index, result_slice);
                end
            else

                for slice_index=1:obj.term.result_slices
                    
                    target_slice = reshape(obj.term.target_volume(:, :, slice_index), ...
                                           obj.term.result_dimensions(1:2));
                                       
                    result_slice = reshape(obj.term.result_volume(:, :, slice_index), ...
                                           obj.term.result_dimensions(1:2));
                    
                    obj.compute_scores_for_slice(term_record, slice_index, target_slice, slice_index, result_slice);
                end
            end
            
            obj.finalise_term(evaluation, mode, term_record);
        end
        
        function compute_scores_for_slice(~, term_record, target_z, target_slice, result_z, result_slice) %#ok<INUSD>
            error('TermRecords.compute_scores_for_slice() must be implemented by a subclass.');
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
                    error('TermRecords.load() couldn''t load reference of type ''%s''', class(reference));
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
end
