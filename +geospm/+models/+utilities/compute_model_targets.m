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

function result = compute_model_targets(model, domain_expression, target_threshold)

    if isnumeric(target_threshold)
        apply_threshold = @(term) term > target_threshold;
    elseif ischar(target_threshold)
        switch( target_threshold )
            case 'max'
                apply_threshold = @(term) term >= max(term(:));
            
            case 'min'
                apply_threshold = @(term) term > min(term(:));
            
            otherwise
                error('compute_model_targets(): Unknown target threshold: %s', target_threshold);
        end
    end

    if numel(model.targets) == model.domain.N_variables
        
        map_size = model.spatial_resolution;
        
        targets = zeros(prod(map_size), model.domain.N_variables);
        
        for i=1:model.domain.N_variables
            target = model.targets{i}.flatten();
            targets(:, i) = target(:);
        end
        
        term_targets = domain_expression.compute_matrix(model.domain, targets);
        term_targets = reshape(term_targets, map_size(1), map_size(2), domain_expression.N_terms);
        
        result = cell(1, domain_expression.N_terms);
        
        for i=1:domain_expression.N_terms
            result{i} = term_targets(:, :, i);
        end
        
        return
    end
    
    joint_distribution = model.joint_distribution.flatten();
    
    result = domain_expression.compute_term_probabilities(model.domain, joint_distribution);

    for i=1:domain_expression.N_terms
    	result{i} = apply_threshold(result{i});
    end
end
