% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%                                                                         %
%  This source file is part of GeoSPM:                                    %
%  https://github.com/high-dimensional/geospm                             %
%                                                                         %
%  Copyright (C) 2018,                                                    %
%  High-Dimensional Neurology Group, University College London            %
%                                                                         %
%  See geospm/LICENSE.txt for license details.                            %
%  See geospm/AUTHORS.txt for the list of GeoSPM authors.                 %
%                                                                         %
%  SPDX-License-Identifier: GPL-3.0-only                                  %
%                                                                         %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function [context, errors] = parse_parameters(parameters, handlers, default_handler, context)
%PARSE_PARAMETERS Summary of this function goes here
%   Detailed description
%

    errors=cell(0,1);

    if ~iscell(parameters)
        errors{end + 1} = 'Error: parse_parameters() expects ''parameters'' argument to be a cell array.';
        return
    end

    if ~isstruct(handlers)
        errors{end + 1} = 'Error: parse_parameters() expects ''handlers'' argument to be a struct.';
        return
    end

    n_parameters=size(parameters, 2);
    index=1;

    while index <= n_parameters

        parameter_name = parameters{index};

        if ~ischar(parameter_name)
            errors{end + 1} = sprintf('Error: Expecting parameter name for argument %d.', index);
            return
        end

        expect_parameter_value = false;

        if parameter_name(end) == '='
            expect_parameter_value=true;
            parameter_name=parameter_name(1:end-1);
        end

        if expect_parameter_value
            if index + 1 > n_parameters
                errors{end + 1} = sprintf('Error: Missing value for parameter ''%s''.', parameter_name);
                return;
            end

            parameter_value = parameters{index + 1};
        else
            parameter_value = true;
        end

        if isfield(handlers, parameter_name)
            parameter_handler=handlers.(parameter_name);
        else
            parameter_handler=default_handler;
        end

        [context, is_parameter_valid, reason_if_not]=parameter_handler(context, parameter_name, expect_parameter_value, parameter_value);

        if ~is_parameter_valid
            errors{end + 1} = reason_if_not;
        end

        index = index + 1;

        if expect_parameter_value
            index = index + 1;
        end
    end

end
