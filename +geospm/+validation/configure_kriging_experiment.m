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

function [kriging] = configure_kriging_experiment(options)

    kriging_kernel_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
    
    kriging_kernel_map('Exp') = hdng.experiments.Value.from('Exp', 'Exponential');
    kriging_kernel_map('Sph') = hdng.experiments.Value.from('Sph', 'Spherical');
    kriging_kernel_map('Gau') = hdng.experiments.Value.from('Gau', 'Gaussian');
    kriging_kernel_map('Exc') = hdng.experiments.Value.from('Exc', 'Exponential class/stable');
    kriging_kernel_map('Mat') = hdng.experiments.Value.from('Mat', 'Matérn');
    kriging_kernel_map('Ste') = hdng.experiments.Value.from('Ste', 'Matérn, M. Stein''s parameterization');
    kriging_kernel_map('Cir') = hdng.experiments.Value.from('Cir', 'Circular');
    kriging_kernel_map('Lin') = hdng.experiments.Value.from('Lin', 'Linear');
    kriging_kernel_map('Bes') = hdng.experiments.Value.from('Bes', 'Bessel');
    kriging_kernel_map('Pen') = hdng.experiments.Value.from('Pen', 'Pentaspherical');
    kriging_kernel_map('Per') = hdng.experiments.Value.from('Per', 'Periodic');
    kriging_kernel_map('Wav') = hdng.experiments.Value.from('Wav', 'Wave');
    kriging_kernel_map('Hol') = hdng.experiments.Value.from('Hol', 'Hole');
    kriging_kernel_map('Log') = hdng.experiments.Value.from('Log', 'Logarithmic');
    kriging_kernel_map('Pow') = hdng.experiments.Value.from('Pow', 'Power');
    kriging_kernel_map('Spl') = hdng.experiments.Value.from('Spl', 'Spline');
    
    kriging = struct();
    kriging.experiment_type = 'geospm.validation.experiments.Kriging';
    kriging.description = 'Kriging';
    kriging.extra_variables = {};
    
    conditional = hdng.experiments.ConditionalGenerator();
    conditional.requirement = 'experiment';
    conditional.requirement_test = @(value) strcmp(value.experiment_type, 'geospm.validation.experiments.Kriging');
    conditional.missing_label = '-';
    
    if ~isfield(options, 'kriging_thresholds')
        %options.kriging_thresholds = { 'none:0.05' };
        options.kriging_thresholds = { 'normal [2]: p < 0.05' };
    end
    
    conditional.value_generator = hdng.experiments.ValueList.from(...
        geospm.SignificanceTest.from_char(options.kriging_thresholds));
    
    kriging_thresholds = struct(...
        'identifier', 'kriging_thresholds', ...
        'description', 'Kriging Thresholds', ...
        'value_generator', conditional, ...
        'interactive', struct('default_display_mode', 'auto') ...
    );
    
    kriging_thresholds.requirements = { conditional.requirement };
    
    kriging.extra_variables = [kriging.extra_variables, {kriging_thresholds}];
    
    conditional = hdng.experiments.ConditionalGenerator();
    conditional.requirement = 'experiment';
    conditional.requirement_test = @(value) strcmp(value.experiment_type, 'geospm.validation.experiments.Kriging');
    conditional.missing_label = '-';
    conditional.value_generator = hdng.experiments.ValueList();
    
    for index=1:numel(options.kriging_kernel)
        kernel = options.kriging_kernel{index};
        
        if ~isKey(kriging_kernel_map, kernel)
            warning('Unknown kriging kernel specified (\"%s\"), ignoring...', kernel);
            continue
        end
        
        conditional.value_generator.values{index} = kriging_kernel_map(kernel);
    end
    
    variogram_function = struct(...
        'identifier', 'variogram_function', ...
        'description', 'Variogram Function', ...
        'value_generator', conditional ...
    );

    variogram_function.requirements = { conditional.requirement };
    
    kriging.extra_variables = [kriging.extra_variables, {variogram_function}];
    
    %---
    
    conditional = hdng.experiments.ConditionalGenerator();
    conditional.requirement = 'experiment';
    conditional.requirement_test = @(value) strcmp(value.experiment_type, 'geospm.validation.experiments.Kriging');
    conditional.missing_label = '-';
    
    if ~isfield(options, 'add_nugget')
        options.add_nugget = { true };
    end
    
    if ~iscell(options.add_nugget)
        options.add_nugget = { options.add_nugget };
    end
    
    conditional.value_generator = hdng.experiments.ValueList.from(options.add_nugget{:});
    
    add_nugget = struct(...
        'identifier', 'add_nugget', ...
        'description', 'Nugget Component', ...
        'value_generator', conditional, ...
        'interactive', struct('default_display_mode', 'auto') ...
    );
    
    add_nugget.requirements = { conditional.requirement };
    
    kriging.extra_variables = [kriging.extra_variables, {add_nugget}];
    %---
    
    kriging.extra_requirements = {
        geospm.validation.Constants.DOMAIN_EXPRESSION, ...
        'kriging_thresholds', ...
        'variogram_function', ...
        'add_nugget' };
    
    

end
