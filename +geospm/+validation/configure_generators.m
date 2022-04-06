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

function [generators] = configure_generators(options)
    
    if ~isfield(options, 'generators')
        options.generators = {{'geospm.validation.generator_models.A:Koch Snowflake', 'Koch Snowflake'}};
    end
    
    if ~isfield(options, 'generator_type')
        options.generator_type = 'factorisation';
    end
    
    if ~isfield(options, 'fractal_levels')
        options.fractal_levels = {5};
    end
    
    if ~isfield(options, 'generator_model_cooccurrence')
        options.generator_model_cooccurrence = true;
    end

    if ~isfield(options, 'generator_interaction_factor')
        options.generator_interaction_factor = 1.0 * options.generator_model_cooccurrence;
    end
    
    if ~isfield(options, 'generator_triangular_layout')
        options.generator_triangular_layout = true;
    end
    
    if ~isfield(options, 'generator_nested_layout')
        options.generator_nested_layout = true;
    end
    
    if ~isfield(options, 'generator_parameterisation')
        options.generator_parameterisation = 'effect_size';
    end
    
    generators = {};
    
    for index=1:numel(options.generators)
        generator_specifier = options.generators{index};
        
        generator_description = generator_specifier;
        
        if iscell(generator_specifier)
            generator_description = generator_specifier{2};
            generator_specifier = generator_specifier{1};
        end
        
        parts = split(generator_specifier, ':');
        
        generator = struct();
        
        generator.generator_type = options.generator_type;
        generator.initialiser = parts{1};
        
        generator.options.use_fractals = true;
        generator.options.fractal_levels = options.fractal_levels;
        generator.options.fractal_name = parts{2};
        
        names = fieldnames(options);
        
        for j=1:numel(names)
            name = names{j};
            
            if ~startsWith(name, 'generator_')
                continue;
            end
            
            
            generator.options.(name(11:end)) = options.(name);
        end
        
        generator.description = generator_description;
        
        generator.extra_variables = {};
        generator.extra_requirements = {};
        
        generators{index} = generator; %#ok<AGROW>
    end
end
