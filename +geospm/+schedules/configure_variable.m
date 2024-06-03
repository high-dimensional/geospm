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

function variable = configure_variable(identifier, description, ...
    requirements, value_generator, varargin)

    options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    
    if ~isfield(options, 'interactive')
        options.interactive = struct('default_display_mode', 'auto');
    end

    if iscell(value_generator)
        value_generator = hdng.experiments.ValueList.from(value_generator{:});
    end
    
    variable = struct();
    variable.identifier = identifier;
    variable.requirements = requirements;
    variable.value_generator = value_generator;
    variable.interactive = options.interactive;
    variable.description = description;
end
