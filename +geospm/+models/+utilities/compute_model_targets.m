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

    joint_distribution = model.joint_distribution.flatten();
    
    probe_distributions = zeros([size(model.probes, 1), model.joint_distribution.dimensions]);
    
    for i=1:size(model.probes, 1)
        probe_distributions(i, :) = joint_distribution(model.probes(i, 1), model.probes(i, 2), :);
    end
    
    result = domain_expression.compute_term_probabilities(model.domain, joint_distribution);

    for i=1:domain_expression.N_terms
    	result{i} = apply_threshold(result{i});
    end
end
