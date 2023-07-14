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

function [contrasts, contrasts_per_threshold] = ...
            define_domain_contrasts(thresholds, term_names)

    N_terms = numel(term_names);
    N_thresholds = numel(thresholds); 

    contrasts_per_threshold = cell(N_thresholds, 1);

    threshold_map = threshold_indices_by_distribution(thresholds);
    distributions = threshold_map.keys();

    contrast_map = containers.Map('KeyType', 'char', 'ValueType', 'any');

    for index=1:numel(distributions)

        distribution = distributions{index};
        threshold_indices = threshold_map(distribution);

        switch distribution

            case 'T[1]'
                
                I = reshape(-eye(N_terms), 1, N_terms, N_terms);
                threshold_contrasts = build_domain_contrasts(term_names, 'T', I, contrast_map, threshold_indices);
                threshold_composite_contrasts = threshold_contrasts;
                
            case 'T[2]'

                
                I = reshape(eye(N_terms), 1, N_terms, N_terms);
                threshold_contrasts = build_domain_contrasts(term_names, 'T', I, contrast_map, threshold_indices);
                threshold_composite_contrasts = threshold_contrasts;

            case 'T[1, 2]'
                
                I = reshape(eye(N_terms), 1, N_terms, N_terms);
                threshold_contrasts1 = build_domain_contrasts(term_names, 'T', I, contrast_map, threshold_indices);


                I = reshape(-eye(N_terms), 1, N_terms, N_terms);
                threshold_contrasts2 = build_domain_contrasts(term_names, 'T', I, contrast_map, threshold_indices, '', true);

                threshold_contrasts = [threshold_contrasts1; threshold_contrasts2];
                threshold_composite_contrasts = [threshold_contrasts1, threshold_contrasts2];

            case 'F'

                I = reshape(eye(N_terms), 1, N_terms, N_terms);
                threshold_contrasts = build_domain_contrasts(term_names, 'F', I, contrast_map, threshold_indices);
                threshold_composite_contrasts = threshold_contrasts;

            otherwise
                error('geospm.utilities.define_domain_contrasts(): Unknown test distribution: ''%s''.', distribution);
        end
        
        merged_composite_contrasts = {};

        for t_index=1:size(threshold_composite_contrasts, 1)
            merged_composite_contrasts = [merged_composite_contrasts; threshold_composite_contrasts(t_index, :)]; %#ok<AGROW> 
        end

        threshold_indices = threshold_map(distribution);

        for t_index=1:numel(threshold_indices)
            contrasts_per_threshold{threshold_indices(t_index), 1} = merged_composite_contrasts;
        end
    end
    
    contrasts = contrast_map.values();
    contrasts = contrasts(:);
end


function contrasts = build_domain_contrasts(term_names, statistic, weights, contrast_map, threshold_indices, prefix, is_auxiliary)

    N_terms = numel(term_names);
    contrasts = cell(N_terms, 1);

    if ~exist('prefix', 'var')
        prefix = '';
    end
    
    if ~exist('is_auxiliary', 'var')
        is_auxiliary = false;
    end

    for i=1:N_terms

        contrast = geospm.spm.Contrast();
        contrast.statistic = statistic;
        contrast.weights = weights(:, :, i);
        contrast.name = [prefix term_names{i}];

        if ~isKey(contrast_map, contrast.key)
            contrast_map(contrast.key) = contrast;
        else
            contrast = contrast_map(contrast.key);
        end


        contrast.attachments.term_index = i;
        
        if ~isfield(contrast.attachments, 'threshold_indices')
            contrast.attachments.threshold_indices = [];
        end
        
        contrast.attachments.threshold_indices = [contrast.attachments.threshold_indices; threshold_indices];
        contrast.attachments.is_auxiliary = is_auxiliary;


        contrasts{i} = contrast;
    end
end

function result = threshold_indices_by_distribution(threshold_array)

    distributions = containers.Map('KeyType', 'char', 'ValueType', 'any');

    for index=1:numel(threshold_array)
        
        threshold = threshold_array{index};
        
        if ~isKey(distributions, threshold.distribution_description)
            distributions(threshold.distribution_description) = [];
        end

        distributions(threshold.distribution_description) = [distributions(threshold.distribution_description); index];
    end

    result = distributions;
end
