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

function [has_nans, message] = check_for_NaNs(value, value_name)
    
    %Checks whether the multi-dimensional array specified by value
    %contains any NaN values, and if so, returns a ready-made
    %diagnostic message to be displayed to the user.

    indicators = isnan(value(:));
    indices=1:numel(value);
    indices=indices(indicators);

    n_nans = numel(indices);
    has_nans=n_nans ~= 0;

    [rows, cols] = ind2sub(size(value), indices);
    
    N_examples = min([n_nans, 10]);

    examples = cell(N_examples, 1);

    for i=1:N_examples
        examples{i} = sprintf('(%d, %d)', rows(i), cols(i));
    end

    examples = join(examples, ' ');
    examples = examples{1};

    if n_nans == 1
        message = sprintf('''%s'' contains %d NaN value at position %s', value_name, n_nans, examples);
    else
        message = sprintf('''%s'' contains %d NaN values at positions %s', value_name, n_nans, examples);

        if n_nans > 10, message = [message ', ...']; end
    end
end
