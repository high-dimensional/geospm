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


function variable = create_conditional_value_list_variable(identifier, description, requirement, condition_value, varargin)
    
    conditional = create_string_conditional(requirement, condition_value);
    conditional.value_generator = hdng.experiments.ValueList.from(varargin{:});
    
    variable = struct(...
        'identifier', identifier, ...
        'description', description, ...
        'value_generator', conditional ...
    );
    
    variable.requirements = { conditional.requirement };
end

function conditional = create_string_conditional(requirement, condition)

    conditional = hdng.experiments.ConditionalGenerator();
    conditional.requirement = requirement;
    conditional.requirement_test = @(value) strcmp(value, condition);
    conditional.missing_label = '-';
    conditional.value_generator = [];
end
