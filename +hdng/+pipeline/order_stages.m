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

function permutation = order_stages(stages, required_variables)

    N_stages = numel(stages);
    
    %Convert the interface requirements to stage requirements
    indexed_requirements = cell(N_stages, 1);

    for i=1:N_stages

        variable_map = required_variables{i};
        names = fieldnames(variable_map);

        N_local_indices = 0;
        local_indices = zeros(numel(names), 1);

        for j=1:numel(names)
            name = names{j};
            variable = variable_map.(name);

            producers = variable.objects_for_role(hdng.pipeline.Variable.PRODUCER_ROLE);
            
            if numel(producers) == 0
                input = variable.objects_for_role(hdng.pipeline.Variable.INPUT_ROLE);
                
                if numel(input) ~= 0
                    continue
                end
                
                
                consumers = variable.objects_for_role(hdng.pipeline.Variable.CONSUMER_ROLE);
                
                is_optional = true;
                
                for k=1:numel(consumers)
                    consumer = consumers{k};
                    is_optional = is_optional && consumer.binding.is_optional;
                end
                
                if is_optional
                    continue
                end
                
                error(['hdng.pipeline.order_stages(): Variable ''' name ''' has no producer and is not designated an input.']);
            end
            
            N_local_indices = N_local_indices + 1;
            producer = producers{1};
            
            local_indices(N_local_indices) = producer.nth_stage;
        end

        %Make sure local_indices are unique
        local_indices = unique(local_indices(1:N_local_indices));
        indexed_requirements{i} = local_indices;
    end

    %Run the topological sort with the converted requirements
    permutation = ...
        hdng.utilities.sort_topologically(stages, ...
        @(~, index) indexed_requirements{index});
end
