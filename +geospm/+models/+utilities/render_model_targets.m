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

function result = render_model_targets(domain_expression, targets, targets_directory, use_volumetric_names, is_rehearsal, do_invert)

    if ~exist('use_volumetric_names', 'var')
        use_volumetric_names = false;
    end
    
    if ~exist('is_rehearsal', 'var')
        is_rehearsal = false;
    end
    
    if ~exist('do_invert', 'var')
        do_invert = false;
    end

    if domain_expression.N_terms ~= numel(targets)
        error('geospm.models.utilities.render_model_targets(): Number of targets does not match number of domain expression terms.');
    end

    result = containers.Map('KeyType', 'char', 'ValueType', 'any');
    
    blank = struct();

    blank.dt = [spm_type('uint8') 0];
    blank.mat = eye(4);
    blank.pinfo = [1 0 0]';

    for i=1:domain_expression.N_terms

        T = targets{i};
        T = permute(T, [2, 1]);
        
        target_name = domain_expression.term_names{i};
        
        if do_invert
            target_name = ['-' target_name]; %#ok<AGROW>
            T = ~T;
        end
        
        width = size(T, 2);
        height = size(T, 1);
            
        if use_volumetric_names
            file_name = [target_name, sprintf('(%d@%d,%d).png', 1, width, height)];
        else
            file_name = [target_name, '.png'];
        end
        
        file_path = fullfile(targets_directory, file_name);
        
        file_paths = {[], file_path};
        
        if ~is_rehearsal
            imwrite(flip(T), file_path, 'BitDepth', 1);
        end
        
        T = targets{i};
        
        file_name = [target_name, '.nii'];
        
        file_path = fullfile(targets_directory, file_name);
        V = blank;
        dim = ones(1, 3);
        unsafe_size = size(T);
        dim(1:numel(unsafe_size)) = unsafe_size;
        V.dim = dim;
        V.fname = file_path;
        
        if ~is_rehearsal
            spm_write_vol(V, T);
        end
        
        file_paths{1} = file_path;
        
        result(target_name) = file_paths;
    end

end
