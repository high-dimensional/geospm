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

function [experiments] = configure_experiments(options)
    
    if ~isfield(options, 'experiments')
        options.experiments = {'SPM', 'Kriging', 'AKDE'};
    end
    
    if ~isfield(options, 'kriging_kernel')
        options.kriging_kernel = {'Exp', 'Gau', 'Mat'};
    end
    
    experiment_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
    
    spm_regression = geospm.validation.configure_spm_experiment(options);
    kriging = geospm.validation.configure_kriging_experiment(options);
    akde = geospm.validation.configure_akde_experiment(options);
    
    experiment_map('spm') = spm_regression;
    experiment_map('kriging') = kriging;
    experiment_map('akde') = akde;
    
    experiments = {};
    
    for index=1:numel(options.experiments)
        experiment = options.experiments{index};
        
        if ~isKey(experiment_map, lower(experiment))
            warning('Unknown experiment specified (\"%s\"), ignoring...', experiment);
        end
        
        experiments{index} = experiment_map(lower(experiment)); %#ok<AGROW>
    end
end
