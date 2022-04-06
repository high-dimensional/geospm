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

function options = parse_options_argument(options, varargin)
%parse_options_argument Parses a sequence of Name, Value pairs into a struct.
%   Detailed explanation goes here
    
    if ~exist('options', 'var') || isempty(options)
        options = struct();
    end

    additional_options = hdng.utilities.parse_struct_from_varargin(varargin{:});
    additional_names = fieldnames(additional_options);

    for i=1:numel(additional_names)
        name = additional_names{i};
        options.(name) = additional_names.(name);
    end
end
