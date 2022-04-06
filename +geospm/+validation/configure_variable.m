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

function [variable] = configure_variable(varargin)

    
    options = hdng.utilities.parse_struct_from_varargin(varargin{:});

    if ~isfield(options, 'identifier')
        error('geospm.validation.configure_variable() is missing an identifier argument.');
    end
    
    if ~isfield(options, 'requirements')
        options.requirements = {};
    end
    
    if ~isfield(options, 'value_generator')
        error('geospm.validation.configure_variable() is missing a value_generator argument.');
    end
    
    if ~isfield(options, 'description')
        options.description = options.identifier;
    end
    
    variable = struct();
    variable.identifier = options.identifier;
    variable.requirements = options.requirements;
    variable.value_generator = options.value_generator;
    variable.interactive = struct('default_display_mode', 'auto');
    variable.description = options.description;
end
