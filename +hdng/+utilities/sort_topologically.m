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

function [permutation, requirements] = ...
    sort_topologically(element_cells, requirements_for)
    %Sorts a cell array of elements in topological order.
    % element_cells - An array of arbitrary elements to be sorted.
    % requirements_for - A function of the form
    %   indices = requirements_for(element, index_in_array), which returns
    %   the indices of all elements required by the given element.
    
    N_elements = numel(element_cells);
    
    %sorted_elements = cell(N_elements, 1);
    requirements = cell(N_elements, 1);
    permutation = zeros(N_elements, 1);
    N_sorted_elements = 0;
    
    %forward and backward each hold an array of indices for every element.
    %A forward entry specifies the requirements of the respective
    %element, that is the elements that have to come before it in the result. 
    %A backward entry specifies which elements depend on the respective 
    %element, that is the elements that have to explicitly follow it.
    
    forward  = cell(N_elements, 1);
    backward = cell(N_elements, 1);

    for i=1:N_elements
        backward{i} = zeros(0,1, 'int32');
    end

    available = zeros(N_elements,1);
    n_available = 0;
    
    for i=1:N_elements
        
        element = element_cells{i};

        indices = requirements_for(element, i);
        
        k = numel(indices);
        
        if k ~= numel(unique(indices))
            error('hdng.utilities.sort_topologically() requirements_for() returned duplicate indices for the element in position %d', i);
        end
        
        for j=1:k
            
            % Record the ith element as directly dependent on its
            % required predecessor.
            
            predecessor = indices(j);
            backward{predecessor}(end + 1) = i;
        end

        if k == 0
            
            % Record the ith element as available since it does not
            % depend on any other element.
            
            n_available = n_available + 1;
            available(n_available) = i;
        end
        
        forward{i} = indices;
    end

    %Create a working copy of forward
    forward_remaining = forward;
    
    %Having set up the direct dependency structure, compute the
    %sort order over all elements.
    
    viable = zeros(N_elements,1);
    n_viable = 0; 
    
    %This is work-list style implementation:
    %The outer loop continues for as long as there are elements available
    %to be added to the sorted array.
    
    while n_available > 0

        %Loop over all elements whose requirements have been met.
        
        for i=1:n_available

            element_index = available(i);
            
            % This element has no more requirements, so add it to
            % the result

            N_sorted_elements = N_sorted_elements + 1;
            
            permutation(N_sorted_elements) = element_index;
            requirements{element_index} = forward{element_index};

            % Check all elements that depend on the current element
            % to see which ones now might become available.
            
            candidates = backward{element_index};

            for j=1:numel(candidates)

                candidate_index = candidates(j);

                % Update the candidate element's requirements
                
                if isempty(forward_remaining{candidate_index})
                    error('hdng.utilities.sort_topologically(): Detected inconsistency in depencency structure, an element discovered in ''backward'' doesn''t have corresponding ''forward'' entry.');
                end

                candidate_requirements = forward_remaining{candidate_index};
                candidate_requirements = candidate_requirements(candidate_requirements ~= element_index);
                forward_remaining{candidate_index} = candidate_requirements;

                % If there are no more requirements for the candidate, 
                % mark it as viable.
                
                if numel(candidate_requirements) == 0
                    n_viable = n_viable + 1;
                    viable(n_viable) = candidate_index;
                end
            end
        end

        % Designate the elements marked as viable as available

        tmp = available;
        available = viable;
        n_available = n_viable;
        viable = tmp;
        n_viable = 0;
    end
    
    %Sanity check: Make sure all elements could be sorted.
    
    if N_sorted_elements ~= N_elements
        error('hdng.utilities.sort_topologically(): Failed to sort all elements, presumable because of cycles.');
    end
end
